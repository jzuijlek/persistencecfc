component extends="mxunit.framework.TestCase" {
	
	public void function beforeTests() {

		setupcfc = new setup.setup( request.datasourceName, request.db.DATABASE_PRODUCTNAME );
		persistence = new persistence.persistence( request.datasourceName );

		data = setupcfc.getData();

	}

	private array function arrayFlatten( required array rows, string key = 'id' ) {
		var result = [ ];
		for ( var row in rows ) {
			arrayAppend( result, row[ key ] );
		}
		return result;
	}

}