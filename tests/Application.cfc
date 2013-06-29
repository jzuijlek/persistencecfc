component {

	this.mappings[ '/persistence' ] = getDirectoryFromPath( getCurrentTemplatePath() ) & '../';
	this.mappings[ '/beans' ] = getDirectoryFromPath( getCurrentTemplatePath() ) & 'beans/';

	public void function onRequestStart() {
		// the datasource name below needs to be set to a valid datasource
		request.datasourceName = 'testdb-mssql';
		
		request.db = new persistence.dbInfoProxy().execute( datasource = request.datasourceName, type = 'version' );
	}

}