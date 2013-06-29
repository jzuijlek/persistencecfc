/*
	Copyright (c) 2013, John Berquist

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/
component {

	public any function init( required string persistenceDatasource, struct persistenceOptions = { }, any beanFactory ) {
		variables.datasource = persistenceDatasource;
		variables.serverType = server.coldfusion.productname;
		variables.dbinfo = new dbInfoProxy();
		variables.queryService = new query();
		variables.cache = { columns = { }, cfcFunctions = { }, datasourceTypes = { } }; 

		variables.options = persistenceOptions;
 		var defaultOptions = { 
 			persistenceBeanName = 'persistence',
 			cfcFolder = 'persistence',
 			globalHandlerBean = 'global',
 			bitToBoolean = true,
 			getReturnsArray = false,
 			delimiter = ' ',
 			flagNew = '',
 			useIsValid = true,
 			logSql = false
 		};		
		structAppend( variables.options, defaultOptions, false );

		if ( structKeyExists( arguments, 'beanFactory' ) ) {
			variables.beanFactory = beanFactory;
			variables.beanFactory.addBean( variables.options.persistenceBeanName, this );
		}

		return this;
	}

	// public methods: new, get, getOrNew, getByProperties, validate, save, updateByProperties, delete, deleteByProperties

	public struct function new( required string tableName, struct options = { } ) {
		var columns = getColumns( tableName );
		var result = { };

		// set struct key for each column with default value
		for ( var column in columns.columns ) {
			if ( column.name != columns.primaryKey.name ) {
				result[ column.name ] = column.defaultvalue;
			}
		}

		// add new flag, if set
		if ( len( variables.options.flagNew ) ) result[ variables.options.flagNew ] = true;

		// handle passed in defaultvalues -- options.defaultvalues should be a struct
		if ( structKeyExists( options, 'defaultvalues' ) ) structAppend( result, options.defaultvalues, true );

		// handle includes -- options.include should either be a single tableName string/struct, or an array
		if ( structKeyExists( options, 'include' ) ) getIncludes( tableName, [ result ], options.include );

		// afterNew event handling
		if ( cfcFunctionExists( tableName, 'afterNew' ) ) {
			variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).afterNew( result, options );
		}

		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'afterNew' ) ) {
			variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).afterNew( tableName, result, options );
		}

		return result;
	}

	// get function wraps getByProperties, allows easy retrieval of rows by primary key
	// primarykey is expected to be either a primary key or an array of primary keys
	public any function get( required string tableName, required any primaryKeyId, struct options = { } ) {
		var primaryKey = getColumns( tableName ).primaryKey.name;
		var properties[ primaryKey ] = primaryKeyId;
		var result = getByProperties( tableName, properties, options );

		if ( structKeyExists( options, 'getOrNew' ) && options.getOrNew ) {
			var getOrNewResult = [ ];
			var idArray = isArray( primaryKeyId ) ? primaryKeyId : [ primaryKeyId ];
			for ( var id in idArray ) {
				var findIndex = arrayStructsFind( result, primaryKey, id );
				arrayAppend( getOrNewResult, findIndex ? result[ findIndex ] : new( tableName, options ) );
			}
			result = getOrNewResult;
		}

		if ( variables.options.getReturnsArray ) {
			return result;
		}

		if ( arrayLen( result ) ) {
			return arrayLen( result ) > 1 ? result : result[ 1 ];
		}
	}

	// wrapper function around get, to set getOrNew option without passing it in options struct
	public any function getOrNew( required string tableName, required any primaryKeyId, struct options = { } ) {
		options.getOrNew = true;
		return get( tableName, primaryKeyId, options ); 
	}

	public array function getByProperties( required string tableName, required struct properties, struct options = { } ) {
		// before get event handling
		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'beforeGet' ) ) {
			variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).beforeGet( tableName, properties, options );
		}

		if ( cfcFunctionExists( tableName, 'beforeGet' ) ) {
			variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).beforeGet( properties, options );
		}

		// make, run, and parse the result of the select query
		var params = buildQueryParams( tableName, properties );
		var sql = buildSelectQuery( tableName, params, structKeyExists( options, 'orderby' ) ? options.orderby : [ ], structKeyExists( options, 'maxrows' ) ? options.maxrows : 0 );
		var queryResult = executeQuery( tableName, sql.statement, params, structKeyExists( options, 'logsql' ) && options.logsql );
		var columns = getColumns( tableName );
		var result = [ ];

		if ( !structKeyExists( queryResult, 'result' ) ) throw( 'Bad query result, nothing was retrieved!' );

		for ( var row = 1; row <= queryResult.result.recordcount; row++ ) {
			var thisRow = { };
			for ( var thisColumn in columns.columns ) {
				// checking for nulls in query
				queryResult.result.absolute( row );
				thisRow[ thisColumn.name ] = ( !thisColumn.nullable || !isNull( queryResult.result.getString( thisColumn.name ) ) ) ? queryResult.result[ thisColumn.name ][ row ] : javacast( 'NULL', '' );
				// convert bit columns to boolean
				if ( variables.options.bitToBoolean && thisColumn.type == 'bit' && structKeyExists( thisRow, thisColumn.name ) && !isNull( thisRow[ thisColumn.name ] ) ) {
					thisRow[ thisColumn.name ] = !!thisRow[ thisColumn.name ];
				}
			}
			arrayAppend( result, thisRow ); 
		}

		// handle includes -- options.include should either be a single tableName string/struct, or an array
		if ( structKeyExists( options, 'include' ) ) {
			getIncludes( tableName, result, options.include );
		}

		// after get event handling
		if ( cfcFunctionExists( tableName, 'afterGet' ) ) {
			variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).afterGet( result, options );
		}

		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'afterGet' ) ) {
			variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).afterGet( tableName, result, options );
		}

		return result;
	}

	public any function validate( required string tableName, required any propertyStructs ) {
		var columns = getColumns( tableName );
		var propertyStructArray = isArray( propertyStructs ) ? propertyStructs : [ propertyStructs ];
		var result = [ ];

		for ( var properties in propertyStructArray ) {
			var thisPropertyStruct = duplicate( properties ); // prevent modifications to original passed in struct
			var keyArray = structKeyArray( thisPropertyStruct );
			var thisResult = { 'success' = true, 'message' = 'Validation Passed.' }; // each validation result is a struct containing at least a success/fail boolean and a string message field

			for ( var column in columns.columns ) {
				var validation = [ ];
				var thisValidationType = getColumnInfoFromType( tableName, column.type ).validation;

				// check first for nulls
				if ( arrayFindNoCase( keyArray, column.name ) && ( !structKeyExists( thisPropertyStruct, column.name ) || isNull( thisPropertyStruct[ column.name ] ) ) && !column.nullable ) {
					arrayAppend( validation, '''#column.name#'' is null, but this column does not allow nulls.' );
				}

				// run isvalid check and string length checks
				if ( structKeyExists( thisPropertyStruct, column.name ) && !isNull( thisPropertyStruct[ column.name ] ) ) {

					if ( variables.options.useIsValid && !isValid( thisValidationType, thisPropertyStruct[ column.name ] ) ) {
						arrayAppend( validation, '''#column.name#'' is not of type #thisValidationType#.' );
					}

					if ( thisValidationType == 'string' && len( thisPropertyStruct[ column.name ] ) > column.size ) {
						arrayAppend( validation, '''#column.name#'' is too long, the string would be truncated.' );
					}

				} 

				// add array to validation result if it contains error messages
				if ( arrayLen( validation ) ) {
					thisResult[ 'validation' ][ column.name ] = validation;
					thisResult.success = false;
					thisResult.message = 'Validation failure.';
				}
			}

			// check for validate methods
			if ( cfcFunctionExists( tableName, 'validate' ) ) {
				variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).validate( thisPropertyStruct, thisResult );
			}

			if ( cfcFunctionExists( variables.options.globalHandlerBean, 'validate' ) ) {
				variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).validate( tableName, thisPropertyStruct, thisResult );
			}

			arrayAppend( result, thisResult );
		}

		return arrayLen( result ) > 1 ? result : result[ 1 ];
	}

	public any function save( required string tableName, required any propertyStructs, struct options = { } ) {
		var result = [ ];
		var propertyStructArray = isArray( propertyStructs ) ? propertyStructs : [ propertyStructs ];

		for ( var properties in propertyStructArray ) {
			var thisPropertyStruct = duplicate( properties ); // prevent modifications to original passed in struct
			var thisOptions = duplicate( options ); // modifications to options struct not shared between iterations
			var thisResult = { 'success' = true, 'message' = '' }; // each save result is a struct containing at least a success/fail boolean and a string message field

			// before save event handling
			if ( cfcFunctionExists( variables.options.globalHandlerBean, 'beforeSave' ) ) {
				variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).beforeSave( tableName, thisPropertyStruct, thisResult, thisOptions );
			}

			if ( cfcFunctionExists( tableName, 'beforeSave' ) ) {
				variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).beforeSave( thisPropertyStruct, thisResult, thisOptions );
			}

			// basic validation
			if ( structKeyExists( thisOptions, 'validate' ) && thisOptions.validate ) {
				structAppend( thisResult, validate( tableName, thisPropertyStruct ), true );
			}

			// after all pre save events called, if success flag is false, abort save attempt
			if ( !thisResult.success ) {
				arrayAppend( result, thisResult );
				continue;
			}

			// check for save event override; global save is called if there is a global override and not a particular one
			if ( cfcFunctionExists( tableName, 'save' ) ) {
				variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).save( thisPropertyStruct, thisResult, thisOptions );
			} else if ( cfcFunctionExists( variables.options.globalHandlerBean, 'save' ) ) {
				variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).save( tableName, thisPropertyStruct, thisResult, thisOptions );
			} else {
				structAppend( thisResult, _save( tableName, thisPropertyStruct, structKeyExists( thisOptions, 'forceInsert' ) && thisOptions.forceInsert, structKeyExists( options, 'logsql' ) && options.logsql ), true );
			}
			
			// after save event handling - the after events are passed the current result struct so that it can be determined if a save was successful
			if ( cfcFunctionExists( tableName, 'afterSave' ) ) {
				variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).afterSave( thisPropertyStruct, thisResult, thisOptions );
			}

			if ( cfcFunctionExists( variables.options.globalHandlerBean, 'afterSave' ) ) {
				variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).afterSave( tableName, thisPropertyStruct, thisResult, thisOptions );
			}

			arrayAppend( result, thisResult );
		}

		return arrayLen( result ) > 1 ? result : result[ 1 ];
	}

	public struct function updateByProperties( required string tableName, required struct propertiesToUpdate, required struct properties, struct options = { } ) {
		var result = { 'success' = true, 'message' = '' };

		// before update event handling
		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'beforeUpdate' ) ) {
			variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).beforeUpdate( tableName, propertiesToUpdate, properties, result, options );
		}

		if ( cfcFunctionExists( tableName, 'beforeUpdate' ) ) {
			variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).beforeUpdate( propertiesToUpdate, properties, result, options );
		}

		// after all pre update events called, if success flag is false, abort update attempt
		if ( !result.success ) return result;

		// check for update event override; global update is called if there is a global override and not a particular one
		if ( cfcFunctionExists( tableName, 'updateByProperties' ) ) {
			variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).updateByProperties( propertiesToUpdate, properties, result, options );
		} else if ( cfcFunctionExists( variables.options.globalHandlerBean, 'updateByProperties' ) ) {
			variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).updateByProperties( tableName, propertiesToUpdate, properties, result, options );
		} else {
			structAppend( result, _updateByProperties( tableName, propertiesToUpdate, properties, structKeyExists( options, 'logsql' ) && options.logsql ), true );
		}
			
		// after update event handling - the after event is passed the result struct so that it can be determined if a update was successful
		if ( cfcFunctionExists( tableName, 'afterUpdate' ) ) {
			variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).afterUpdate( propertiesToUpdate, properties, result, options );
		}

		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'afterUpdate' ) ) {
			variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).afterUpdate( tableName, propertiesToUpdate, properties, result, options );
		}

		return result;
	}


	// delete function wraps deleteByProperties, allows easy deletion of rows by primary key
	// primaryKeyId is expected to be either a primary key or an array of primary keys
	public any function delete( required string tableName, required any primaryKeyId, struct options = { } ) {
		var properties[ getColumns( tableName ).primaryKey.name ] = primaryKeyId;
		return deleteByProperties( tableName, properties, options );
	}

	public struct function deleteByProperties( required string tableName, required struct properties, struct options = { } ) {
		var result = { 'success' = true, 'message' = '' };

		// before delete event handling
		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'beforeDelete' ) ) {
			variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).beforeDelete( tableName, properties, result, options );
		}

		if ( cfcFunctionExists( tableName, 'beforeDelete' ) ) {
			variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).beforeDelete( properties, result, options );
		}

		// after all pre delete events called, if success flag is false, abort delete attempt
		if ( !result.success ) {
			return result;
		}

		// check for delete event override; global delete is called if there is a global override and not a particular one
		if ( cfcFunctionExists( tableName, 'deleteByProperties' ) ) {
			variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).deleteByProperties( properties, result, options );
		} else if ( cfcFunctionExists( variables.options.globalHandlerBean, 'deleteByProperties' ) ) {
			variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).deleteByProperties( tableName, properties, result, options );
		} else {
			structAppend( result, _deleteByProperties( tableName, properties, structKeyExists( options, 'logsql' ) && options.logsql ), true );
		}
			
		// after delete event handling - the after event is passed the result struct so that it can be determined if a delete was successful
		if ( cfcFunctionExists( tableName, 'afterDelete' ) ) {
			variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).afterDelete( properties, result, options );
		}

		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'afterDelete' ) ) {
			variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).afterDelete( tableName, properties, result, options );
		}

		return result;
	}

	// private methods
	// they are not set as private so that they can be called by cfc method overrides
	// TODO: clean up this function
	public void function getIncludes( required string tableName, required array result, required any includes ) {
		var columns = getColumns( tableName );
		if ( !isArray( includes ) ) includes = [ includes ];

		for ( var thisInclude in includes ) {
			if ( isSimpleValue( thisInclude ) ) thisInclude = { 'name' = thisInclude };
			var includeTableName =	getTableName( thisInclude.name );
			var thisIncludeResult =	[ ];
			var propStruct = { };
			if ( structKeyExists( columns.foreignKeys, includeTableName ) ) {
				// many to one
				var thisIncludePrimaryKey = getColumns( thisInclude.name ).primaryKey.name;
				var foreignKeyIds = [ ];
				// find foreign keys in result that are not null
				for ( var row in result ) {
					row[ getSingularName ( thisInclude.name ) ] = javaCast( 'NULL', '' ); // initialize result with null values, overwrite after getting include
					if ( structKeyExists( row, columns.foreignKeys[ includeTableName ] ) && !isNull( row[ columns.foreignKeys[ includeTableName ] ] ) ) {
						arrayAppend( foreignKeyIds, row[ columns.foreignKeys[ includeTableName ] ] );
					}
				}
				// if not-null foreign keys found, retrieve those rows from database
				if ( arrayLen( foreignKeyIds ) ) {
					var propStruct[ thisIncludePrimaryKey ] = foreignKeyIds;				
					var thisIncludeResult = getByProperties( thisInclude.name, propStruct, thisInclude );
				}
				// add results to original result
				for ( var row in thisIncludeResult ) {
					var index = arrayStructsFind( result, columns.foreignKeys[ includeTableName ], row[ thisIncludePrimaryKey ] );
					result[ index ][ getSingularName ( thisInclude.name ) ] = row;
				}
			} else {
				/*
					Assumption: if the include is not found in the current table, it must be the name of another related table.
					The way this is structured right now an exception will be thrown if the include is not the name of another table
					in the database (when getColumns is called), and it will be ignored if there isn't a foreign key there referencing 
					the original table.
				*/
				// one to many
				var includeForeignKeys = getColumns( thisInclude.name ).foreignKeys;
				includeTableName =	getTableName( tableName );
				if ( structKeyExists( includeForeignKeys, includeTableName ) ) {
					var primaryKeyIds = [ ];
					for ( var row in result ) {
						// null check is necessary because in the case of new() getincludes() calls there most likely won't be a primary key in the result
						if ( structKeyExists( row, columns.primaryKey.name ) && !isNull( row[ columns.primaryKey.name ] ) ) {
							var propStruct[ includeForeignKeys[ includeTableName ] ] = row[ columns.primaryKey.name ];	
							row[ thisInclude.name ] = getByProperties( thisInclude.name, propStruct, thisInclude );
						}
					}
				}
			}
		}
	}

	public any function _save( required string tableName, required struct properties, boolean forceInsert = false, boolean logSql = false ) {
		var primarykey = getColumns( tableName ).primaryKey.name;
		var result = { };
		var whereProperties = { };

		if ( structKeyExists( properties, primarykey ) && !isNull( properties[ primarykey ] ) && !forceInsert ) {
			whereProperties[ primarykey ] = properties[ primarykey ];
			structDelete( properties, primarykey );
		}

		var params = buildQueryParams( tableName, properties );

		if ( !structIsEmpty( whereProperties ) ) {

			var primaryKeyParam = buildQueryParams( tableName, whereProperties );
			var sql = buildUpdateQuery( tableName, params, primaryKeyParam );

			transaction {
				result[ 'originalrow' ] = get( tableName, whereProperties[ primarykey ] );
				structAppend( result, executeQuery( tableName, sql.statement, sql.params, logSql ) );
			}
			if ( result.success && result.prefix.recordcount == 1  ) {
				result[ 'primarykey' ] = whereProperties[ primarykey ];
				result.message = 'Update Successful.';
			} else {
				result.success = false;
			}
		} else {
			result = executeQuery( tableName, buildInsertQuery( tableName, params ).statement, params, logSql );
			if ( result.success && result.prefix.recordcount == 1  ) {
				result[ 'primarykey' ] = result.prefix.generatedKey;
				result.message = 'Insert successful.';
			} else {
				result.success = false;
			}
		}

		structDelete( result, 'prefix' );
		structDelete( result, 'result' );

		return result;
	}

	public any function _updateByProperties( required string tableName, required struct propertiesToUpdate, required struct properties, boolean logSql = false ) {
		var params = buildQueryParams( tableName, propertiesToUpdate );
		var whereParams = buildQueryParams( tableName, properties );
		var sql = buildUpdateQuery( tableName, params, whereParams );
		var result = { };

		transaction {
			result[ 'originalrows' ] = getByProperties( tableName, properties );
			structAppend( result, executeQuery( tableName, sql.statement, sql.params, logSql ) );
		}

		if ( structKeyExists( result, 'prefix' ) ) {
			if ( result.prefix.recordcount == 0 ) {
				result.success = false;
				result.message = 'Nothing was updated.';
				result[ 'rowsupdated' ] = 0;
			} else {
				result.message = result.prefix.recordcount & ' row' & ( result.prefix.recordcount > 1 ? 's' : '' ) & ' updated.';
				result[ 'rowsupdated' ] = result.prefix.recordcount;
			}
			structDelete( result, 'prefix' );
			structDelete( result, 'result' );
		}

		return result;
	}

	public any function _deleteByProperties( required string tableName, required struct properties, boolean logSql = false ) {
		var params = buildQueryParams( tableName, properties );
		var sql = buildDeleteQuery( tableName, params );
		var result = { };

		transaction {
			result[ 'originalrows' ] = getByProperties( tableName, properties );
			structAppend( result, executeQuery( tableName, sql.statement, params, logSql ) );
		}

		if ( structKeyExists( result, 'prefix' ) ) {
			if ( result.prefix.recordcount == 0 ) {
				result.success = false;
				result.message = 'Nothing was deleted.';
				result[ 'rowsdeleted' ] = 0;
			} else {
				result.message = result.prefix.recordcount & ' row' & ( result.prefix.recordcount > 1 ? 's' : '' ) & ' deleted.';
				result[ 'rowsdeleted' ] = result.prefix.recordcount;
			}
			structDelete( result, 'prefix' );
			structDelete( result, 'result' );
		}

		return result;
	}

	// query methods

	public struct function executeQuery( required string tableName, required string sql, required array params, boolean logSql = false ) {
		variables.queryService.clearParams();
		variables.queryService.setDatasource( getDatasource( tableName ) );
		variables.queryService.setSql( sql );
		var result = { 'success' = true, 'message' = '' };
		var index = 1;

		for ( var param in params ) {
			for( var thisValue in param.value ) {
				// strict null support workaround to preserve cf and railo compatibility -- see https://issues.jboss.org/browse/RAILO-2371
        var argColl = { 'name' = 'param_' & index, 'value' = thisValue, 'cfsqltype' = getColumnInfoFromType( tableName, param.type ).queryparam, 'null' = param.isNull };
				variables.queryService.addParam( argumentCollection = argColl );
				index++;
			}
		}

		try {
			var queryResult = variables.queryService.execute();
			result[ 'prefix' ] = queryResult.getPrefix();
			result[ 'result' ] = queryResult.getResult();
		} 
		catch( any e ) {
			// TODO: handle the different ways Adobe CF and Railo return query error messages
			// writeDump( e ); abort;
			result.message = e.message;
			result.success = false;
		}

		if ( variables.options.logSql || logSql ) logQuery( sql, params, result );
		
		return result;
	}

	public array function buildQueryParams( required string tableName, required struct properties ) {
		var params = [ ];
		var thisProperty = '';
		var columns = getColumns( tableName );
		var keyArray = structKeyArray( properties ); // using this in order to detect null properties
		var operators = [ '=','>','<','>=','<=','<>','!=','!>','!<' ];

		for ( var key in keyArray ) {
			var setFieldNull = false;
			var columnIndex = arrayStructsFind( columns.columns, 'name', listFirst( key, variables.options.delimiter ) );
			if ( columnIndex ) {
				if ( !structKeyExists( properties, key ) || isNull( properties[ key ] ) ) {
					thisProperty = [ '' ];
					setFieldNull = true;
				} else {
					thisProperty = isArray( properties[ key ] ) ? properties[ key ] : [ properties[ key ] ];
				}
				arrayAppend( params, { 'name' = columns.columns[ columnIndex ].name, 'value' = thisProperty, 'type' = columns.columns[ columnIndex ].type, 'isNull' = setFieldNull, 'operator' = ( listLen( key, variables.options.delimiter ) == 2 && arrayFind( operators, listLast( key, variables.options.delimiter ) ) ) ? listLast( key, variables.options.delimiter ) : '=' } );	
			}
		}		

		return params;
	}

	public struct function buildSelectQuery( required string tableName, required array params, any orderBy = [ ], numeric maxrows = 0 ) {
		var fullTableName = getTableName( tableName );
		var columns = getColumns( tableName );
		var databaseQuotes = getDatabaseQuotes( tableName );
		var databaseVersion = getDatabaseVersion( getDatasource( tableName ) );
		var sql = { 'columnlist' = '', 'from' = databaseQuotes.start & fullTableName & databaseQuotes.end, 'where' = '', 'orderby' = '', 'prefix' = '', 'suffix' = '', 'statement' = '' };
		var separator = '';
		var index = 1;
		var columnNameArray = [ ];

		for ( var column in columns.columns ) {
			sql.columnlist = listAppend( sql.columnlist, getQualifiedColumnName( column.name, fullTableName, databaseQuotes ) );
			arrayAppend( columnNameArray, column.name );
		}

		for ( var param in params ) {
			if ( arrayLen( param.value ) > 1 ) {
				var thisSep = '';
				sql.where &= separator & getQualifiedColumnName( param.name, fullTableName, databaseQuotes ) & ' IN(';
				for ( var thisValue in param.value ) {
					sql.where &= thisSep & ':param_' & index; 
					index++; 
					thisSep = ',';
				}
				sql.where &= ')';
			} else {
				sql.where &= separator & getQualifiedColumnName( param.name, fullTableName, databaseQuotes ) & param.operator & ':param_' & index;
				index++;
			}
			separator = ' AND ';
		}

		// parse orderby
		if ( !isArray( orderby ) ) orderby = [ orderby ];

		for ( var orderbyColumn in orderby ) {
			var columnName = listFirst( orderbyColumn, variables.options.delimiter );
			var direction = listRest( orderbyColumn, variables.options.delimiter );
			if ( arrayFindNoCase( columnNameArray, columnName ) ) {
				var thisColumnOrderby = getQualifiedColumnName( columnName, fullTableName, databaseQuotes );
				if ( len( direction ) && arrayFindNoCase( ['ASC','DESC'], direction ) ) {
					thisColumnOrderby &= ' ' & uCase( direction );
				}
				sql.orderby = listAppend( sql.orderby, thisColumnOrderby );
			}
		}

		// add max rows handling
		if ( maxrows ) {
			if ( databaseVersion == 'Microsoft SQL Server' ) {
				sql.prefix = ' TOP #maxrows# ';
			} else if ( databaseVersion == 'MySQL' ) {
				sql.suffix = ' LIMIT #maxrows#';
			}
		}

		sql.statement = 'SELECT ' & sql.prefix & sql.columnlist & ' FROM ' & sql.from & ' WHERE ' & sql.where & ( len( sql.orderby ) ? ( ' ORDER BY ' & sql.orderBy ) : '' ) & sql.suffix;

		return sql;
	}

	public struct function buildUpdateQuery( required string tableName, required array params, required array whereParams ) {
		var fullTableName = getTableName( tableName );
		var databaseQuotes = getDatabaseQuotes( tableName );
		var sql = { 'update' = '', 'where' = '', 'statement' = '', 'params' = [ ] };
		var separator = '';
		var whereSeparator = '';
		var index = 1;

		for ( var param in params ) {
			arrayAppend( sql.params, param );
			sql.update &= separator & getQualifiedColumnName( param.name, fullTableName, databaseQuotes ) & '=:param_' & index;
			separator = ','; 
			index++;
		}

		separator = '';

		for ( var param in whereParams ) {
			arrayAppend( sql.params, param );
			if ( arrayLen( param.value ) > 1 ) {
				var thisSep = '';
				sql.where &= separator & getQualifiedColumnName( param.name, fullTableName, databaseQuotes ) & ' IN(';
				for ( var thisValue in param.value ) {
					sql.where &= thisSep & ':param_' & index; 
					index++; 
					thisSep = ',';
				}
				sql.where &= ')';
			} else {
				sql.where &= separator & getQualifiedColumnName( param.name, fullTableName, databaseQuotes ) & param.operator & ':param_' & index;
				index++;
			}
			separator = ' AND ';
		}		

		sql.statement = 'UPDATE ' & databaseQuotes.start & fullTableName & databaseQuotes.end & ' SET ' & sql.update & ' WHERE ' & sql.where;

		return sql;
	}

	public struct function buildInsertQuery( required string tableName, required array params ) {
		var fullTableName = getTableName( tableName );
		var databaseQuotes = getDatabaseQuotes( tableName );
		var sql = { 'insert' = '', 'values' = '', 'statement' = '' };
		var index = 1;

		for ( var param in params ) {
			sql.insert = listAppend( sql.insert, getQualifiedColumnName( param.name, fullTableName, databaseQuotes ) );
			sql.values = listAppend( sql.values, ':param_' & index );
			index++;
		}

		sql.statement = 'INSERT INTO ' & fullTableName & ' (' & sql.insert & ') ' & 'VALUES (' & sql.values & ')';

		return sql;
	}

	public struct function buildDeleteQuery( required string tableName, required array params ) {
		var fullTableName = getTableName( tableName );
		var databaseQuotes = getDatabaseQuotes( tableName );
		var sql = { 'from' = 'DELETE FROM ' & databaseQuotes.start & fullTableName & databaseQuotes.end, 'where' = 'WHERE ', 'statement' = '' };
		var separator = '';
		var index = 1;

		for ( var param in params ) {
			if ( arrayLen( param.value ) > 1 ) {
				var thisSep = '';
				sql.where &= separator & getQualifiedColumnName( param.name, fullTableName, databaseQuotes ) & ' IN(';
				for ( var thisValue in param.value ) {
					sql.where &= thisSep & ':param_' & index; 
					index++; 
					thisSep = ',';
				}
				sql.where &= ')';
			} else {
				sql.where &= separator & getQualifiedColumnName( param.name, fullTableName, databaseQuotes ) & param.operator & ':param_' & index;
				index++;
			}
			separator = ' AND ';
		}

		sql.statement = sql.from & ' ' & sql.where;

		return sql;
	}

	public string function getQualifiedColumnName( required string columnName, required string tableName, required struct databaseQuotes ) {
		return databaseQuotes.start & tableName & databaseQuotes.end & '.' & databaseQuotes.start & columnName & databaseQuotes.end;
	}

	// database information methods

	public struct function getColumns( required string tableName ) {
		if ( !structKeyExists( variables.cache.columns, tableName ) ) {
			var columns = variables.dbinfo.execute( datasource = getDatasource( tableName ), type = 'columns', table = getTableName( tableName ) );
			variables.cache.columns[ tableName ] = { 'columns' = [ ], 'primaryKey' = { }, 'foreignKeys' = { } };
			for ( var row = 1; row <= columns.recordcount; row++ ) {
				var columnData = {};
				columnData[ 'name' ] = columns.COLUMN_NAME[ row ];
				columnData[ 'type' ] = columns.TYPE_NAME[ row ];
				columnData[ 'size' ] = ( !isNull( columns.COLUMN_SIZE[ row ] ) && len( columns.COLUMN_SIZE[ row ] ) ) ? columns.COLUMN_SIZE[ row ] : 0;
				columnData[ 'decimal_digits' ] = columns.DECIMAL_DIGITS[ row ];
				columnData[ 'nullable' ] = !!columns.IS_NULLABLE[ row ];
				columnData[ 'defaultvalue' ] = getDatabaseDefaultValue( tableName, columns, row );
				arrayAppend( variables.cache.columns[ tableName ][ 'columns' ], columnData );
				if ( columns.IS_PRIMARYKEY[ row ] == 'YES' ) {
					variables.cache.columns[ tableName ][ 'primaryKey' ] = { 'name' = columns.COLUMN_NAME[ row ], 'type' = columns.TYPE_NAME[ row ] };
				}
				if ( columns.IS_FOREIGNKEY[ row ] == 'YES' ) {
					variables.cache.columns[ tableName ][ 'foreignKeys' ][ columns.REFERENCED_PRIMARYKEY_TABLE[ row ] ] = columns.COLUMN_NAME[ row ];
				}
			}
		}
		return variables.cache.columns[ tableName ];
	}

	public string function getTableName( required string tableName ) {
		if ( cfcFunctionExists( tableName, 'getTableName' ) ) {
			return variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).getTableName();
		}
		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'getTableName' ) ) {
			return variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).getTableName( tableName );
		}
		return tableName;
	}

	public string function getSingularName( required string tableName ) {
		if ( cfcFunctionExists( tableName, 'getSingularName' ) ) {
			return variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).getSingularName();
		}
		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'getSingularName' ) ) {
			return variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).getSingularName( tableName );
		}
		return tableName;
	}

	public string function getDatasource( required string tableName ) {
		if ( cfcFunctionExists( tableName, 'getDatasource' ) ) {
			return variables.beanFactory.getBean( tableName & variables.options.cfcFolder ).getDatasource();
		}
		if ( cfcFunctionExists( variables.options.globalHandlerBean, 'getDatasource' ) ) {
			return variables.beanFactory.getBean( variables.options.globalHandlerBean & variables.options.cfcFolder ).getDatasource( tableName, variables.datasource );
		}
		return variables.datasource;
	}

	public string function getDatabaseVersion( required string datasource ) {
		if ( !structKeyExists( variables.cache.datasourceTypes, datasource ) ) {
			variables.cache.datasourceTypes[ datasource ] = variables.dbinfo.execute( datasource = datasource, type = 'version' ).DATABASE_PRODUCTNAME;
		}
		return variables.cache.datasourceTypes[ datasource ];
	}

	private struct function getDatabaseQuotes( required string tableName ) {
		var databaseversion = getDatabaseVersion( getDatasource( tableName ) );
		if ( databaseversion == 'Microsoft SQL Server' ) {
			return { 'start' = '[', 'end' = ']' };
		} else if ( databaseversion == 'MySQL' ) {
			return { 'start' = '`', 'end' = '`' };
		}
		throw( 'Database type unsupported.' );
	}

	private any function getDatabaseDefaultValue( required string tableName, required query columns, required numeric row ) {
		if ( !isNull( columns.COLUMN_DEFAULT_VALUE[ row ] ) && len( columns.COLUMN_DEFAULT_VALUE[ row ] ) && columns.TYPE_NAME[ row ] == 'BIT' ) {
			return !!find( '1', columns.COLUMN_DEFAULT_VALUE[ row ] );
		}
		var columntype = getColumnInfoFromType( tableName, columns.TYPE_NAME[ row ] );
		if ( arrayFind( [ 'integer','numeric' ], columntype.validation ) ) {
			return 0;
		}
		return '';
	}

	private boolean function cfcFunctionExists( required string tableName, required string functionName ) {
		if ( !structKeyExists( variables.cache.cfcFunctions, tableName ) ) {
			variables.cache.cfcFunctions[ tableName ] = [ ];
			if ( structKeyExists( variables, 'beanFactory' ) && variables.beanFactory.containsBean( tableName & variables.options.cfcFolder ) ) {
				var metadata = getMetadata( variables.beanFactory.getBean( tableName & variables.options.cfcFolder ) );
				var al = arrayLen( metadata.functions );
				for ( var i = 1; i <= al; i++ ) {
					arrayAppend( variables.cache.cfcFunctions[ tableName ], metadata.functions[ i ].name );
				}
			}
		}
		return arrayFindNoCase( variables.cache.cfcFunctions[ tableName ], functionName );
	}

	private struct function getColumnInfoFromType( required string tableName, required string type ) {
		var databaseversion = getDatabaseVersion( getDatasource( tableName ) );
		if ( databaseversion == 'Microsoft SQL Server' ) {
			return getMSSQLColumnInfoFromType( type );
		} else if ( databaseversion == 'MySQL' ) {
			return getMySQLColumnInfoFromType( type );
		}
		throw( 'Database type unsupported.' );
	}

	// cfwheels (https://github.com/cfwheels/cfwheels) - wheels.model.adapters - used a starting point here
	private struct function getMSSQLColumnInfoFromType( required string type ) {
		var columntype = { 'queryparam' = '', 'validation' = '' };

		switch( type ) {
				case "bigint": columntype.queryparam = "cf_sql_bigint"; columntype.validation = 'integer'; break;
				case "binary": case "timestamp": columntype.queryparam = "cf_sql_binary"; columntype.validation = 'binary'; break;
				case "bit": columntype.queryparam = "cf_sql_bit"; columntype.validation = 'boolean'; break;
				case "char": case "nchar": case "uniqueidentifier": columntype.queryparam = "cf_sql_char"; columntype.validation = 'string'; break;
				case "date": columntype.queryparam = "cf_sql_date"; columntype.validation = 'date'; break;
				case "datetime": case "datetime2": case "smalldatetime": columntype.queryparam = "cf_sql_timestamp"; columntype.validation = 'date'; break;
				case "decimal": case "money": case "smallmoney": columntype.queryparam = "cf_sql_decimal"; columntype.validation = 'numeric'; break;
				case "float": columntype.queryparam = "cf_sql_float"; columntype.validation = 'numeric'; break;
				case "int": case "int identity": columntype.queryparam = "cf_sql_integer"; columntype.validation = 'integer'; break;
				case "image": columntype.queryparam = "cf_sql_longvarbinary"; columntype.validation = 'binary'; break;
				case "text": case "ntext": case "xml": columntype.queryparam = "cf_sql_longvarchar"; columntype.validation = 'string'; break;
				case "numeric": columntype.queryparam = "cf_sql_numeric"; columntype.validation = 'numeric'; break;
				case "real": columntype.queryparam = "cf_sql_real"; columntype.validation = 'numeric'; break;
				case "smallint": columntype.queryparam = "cf_sql_smallint"; columntype.validation = 'integer'; break;
				case "time": columntype.queryparam = "cf_sql_time"; columntype.validation = 'time'; break;
				case "tinyint": columntype.queryparam = "cf_sql_tinyint"; columntype.validation = 'integer'; break;
				case "varbinary": columntype.queryparam = "cf_sql_varbinary"; columntype.validation = 'binary'; break;
				case "varchar": case "nvarchar": columntype.queryparam = "cf_sql_varchar"; columntype.validation = 'string'; break;
			}

		return columntype;
	}

	private struct function getMySQLColumnInfoFromType( required string type ) {
		var columntype = { 'queryparam' = '', 'validation' = '' };

		switch( type ) {
				case "bigint": columntype.queryparam = "cf_sql_bigint"; columntype.validation = 'integer'; break;
				case "binary": columntype.queryparam = "cf_sql_binary"; columntype.validation = 'binary'; break;
				case "bit": case "bool": columntype.queryparam = "cf_sql_bit"; columntype.validation = 'boolean'; break;
				case "blob": case "tinyblob": case "mediumblob": case "longblob": columntype.queryparam = "cf_sql_blob";	columntype.validation = 'binary'; break;
				case "char": columntype.queryparam = "cf_sql_char"; columntype.validation = 'string'; break;
				case "date": columntype.queryparam = "cf_sql_date"; columntype.validation = 'date'; break;
				case "decimal": columntype.queryparam = "cf_sql_decimal"; columntype.validation = 'numeric'; break;
				case "double": columntype.queryparam = "cf_sql_double"; columntype.validation = 'numeric'; break;
				case "float": columntype.queryparam = "cf_sql_float"; columntype.validation = 'numeric'; break;
				case "int": case "mediumint": columntype.queryparam = "cf_sql_integer"; columntype.validation = 'integer'; break;
				case "smallint": case "year": columntype.queryparam = "cf_sql_smallint"; columntype.validation = 'integer'; break;
				case "time": columntype.queryparam = "cf_sql_time"; columntype.validation = 'time'; break;
				case "datetime": case "timestamp": columntype.queryparam = "cf_sql_timestamp"; columntype.validation = 'date'; break;
				case "tinyint": columntype.queryparam = "cf_sql_tinyint"; columntype.validation = 'integer'; break;
				case "varbinary": columntype.queryparam = "cf_sql_varbinary"; columntype.validation = 'binary'; break;
				case "varchar": case "text": case "mediumtext": case "longtext": case "tinytext": case "enum": case "set": columntype.queryparam = "cf_sql_varchar"; columntype.validation = 'string'; break;
			}

		return columntype;
	}

	private void function logQuery( required string sql, required array params, required struct result ) {
		writeLog( file = 'persistence', text = serializeJSON( arguments ) );
	}

	private numeric function arrayStructsFind( required array arrayToSearch, required string keyToSearch, required any valueToSearch ) {
		var n = arrayLen( arrayToSearch );
		for ( var i = 1; i <= n; i++ ) {
			if ( structKeyExists( arrayToSearch[ i ], keyToSearch ) && !isNull( arrayToSearch[ i ][ keyToSearch ] ) && arrayToSearch[ i ][ keyToSearch ] == valueToSearch ) return i;
		}
		return 0;
	}

}