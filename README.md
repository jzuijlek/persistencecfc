persistence.cfc
===============

persistence.cfc is a lightweight CFML wrapper around CRUD operations on
relational databases (currently MSSQL and MYSQL). It has been tested on Railo 
and ColdFusion. It should run on Railo 3.3+ and ColdFusion 9.0.1+. It is 
initialized with a datasource, and makes the following methods available: get(), 
getByProperties(), new(), getOrNew(), validate(), save(), updateByProperties(),
delete(), and deleteByProperties(). It makes extensive use of the cfdbinfo tag 
to look up primary and foreign key information. On the CFML side it expects 
and returns structures and arrays of structures.

persistence.cfc was designed to be used with DI/1 (https://github.com/framework-one/di1)
to enable more sophisticated behaviors. However, any bean factory that
makes the following methods available should work with it: addBean(),
containsBean(), and getBean(). If a bean factory is passed into persistence.cfc
at initialization, it will add itself to the bean factory using the addBean
method, giving itself by default the alias of 'persistence' (this alias can be
configured). Then, when persistence.cfc CRUD methods are called, it will look
for bean names in the factory that start with the specified tablename, and have
a suffix of 'persistence' (this suffix can also be configured), and then will
look for specific methods (such as beforeSave() and afterSave()) in those beans
to call at the appropriate points in each CRUD operation.

Getting Started
===============

Initialize persistence.cfc with a datasource:

    persistence = new persistence( 'datasource' );

**Note**: Currently persistence.cfc makes use of dbInfoProxy.cfc which wraps the 
cfdbinfo tag, because Railo and Adobe ColdFusion do not implement cfdbinfo in 
cfscript in the same way. dbInfoProxy.cfc need to be in the same directory as 
persistence.cfc.

**Note**: persistence.cfc caches all of the database metadata it retrieves, so if
it is going to be used in an application, it should be stored in the
application scope, or managed by a bean factory such as DI/1.

To retrieve a row from the database by a primary key value do the following:

    rowStruct = persistence.get( 'tableName', primaryKeyValue );
    // rowStruct will be a structure with a key-value pair for each column in the table

To save a row structure, pass it to the save method:

    persistence.save( 'tableName', rowStruct );

By default, if a primary key value is found in the structure, the row will be updated, 
otherwise, it will be inserted.

To delete a row, use the delete method:

    persistence.delete( 'tableName', primaryKeyValue );