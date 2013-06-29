component {
	
	public any function init() {
		return this;
	}

	public void function beforeGet( required struct properties, required struct options ) {
		if ( !structKeyExists( options, 'include' ) ) options.include = [ ];
		if ( !isArray( options.include ) ) options.include = [ options.include ];
		arrayAppend( options.include, 'users' );
	}

}