component extends="testBase" {
	
	public void function test_null_datatype() {

		var user = persistence.get( 'users', 2 );
		var users = persistence.getByProperties( 'users', { 'id >' = 0 } );

		assertTrue( arrayFindNoCase( structKeyArray( user ), 'TestNull' ), 'result was supposed to contain key for null value' );
		assertTrue( arrayFindNoCase( structKeyArray( users[ 2 ] ), 'TestNull' ), 'result array was supposed to contain key for null value' );
		assertTrue( !structKeyExists( user, 'TestNull' ) || isNull( user.TestNull ), 'result was supposed to be null' );
		assertTrue( !structKeyExists( users[ 2 ], 'TestNull' ) || isNull( users[ 2 ].TestNull ), 'result array was supposed to be null' );

	}

}