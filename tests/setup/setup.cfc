component {


	public any function init( required string datasource, required string databaseType ) {
		variables.datasource = datasource;
		variables.databaseType = databaseType;
		variables.data = loadData();
		variables.sqlString = loadSqlString();
		resetDb();
		return this;
	}

	public void function resetDb() {
		var queryService = new query();
		queryService.setDatasource( variables.datasource );
		queryService.setSql( getSqlString() );
		queryService.execute();
	}

	public any function getData() {
		return variables.data;
	}

	public string function getSqlString() {
		return variables.sqlString;
	}

	public string function loadSqlString() {
		var fileName = '';

		switch( variables.databaseType ) {
			case 'Microsoft SQL Server': { fileName = 'mssql.sql'; break; }
			case 'MySQL': { fileName = 'mysql.sql'; break; }
			default: { throw( 'Database Type Unsupported!' ) }
		}

		return fileRead( getDirectoryFromPath( getCurrentTemplatePath() ) & fileName );
	}

	public any function loadData() {
		return deserializeJSON( fileRead( getDirectoryFromPath( getCurrentTemplatePath() ) & 'data.json' ) );
	}

}