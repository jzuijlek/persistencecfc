component {
	
	public any function init() {
		return this;
	}

	public void function beforeGet( required struct properties, required struct options ) {
		if ( structKeyExists( options, 'dontreturnanything' ) ) structAppend( properties, { 'user_id <' = 0 } );
	}



}