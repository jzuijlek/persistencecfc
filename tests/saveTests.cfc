component extends="testBase" {
	
	public void function setup() {

		setupcfc.resetDb();

	}

	public void function test_update() {

		var userData = { 'id' = 2, 'firstname' = 'John', LASTNAME = 'Doe'  };
		var result = persistence.save( 'users', userData );
		var new_user = persistence.get( 'users', 2 );

		//debug( result );
		//debug( new_user );

		assertTrue( result.success, 'failed success check' );
		assertTrue( result.primarykey == 2, 'failed to return correct primarykey' );
		assertTrue( find( 'Update', result.message ), 'failed to return correct message' );
		assertTrue( structKeyExists( result, 'originalrow' ), 'failed to return original object' );
		assertTrue( result.originalrow.lastname == 'Allen' && result.originalrow.firstname == 'Jami', 'failed to return correct original object' );
		assertTrue( new_user.lastname == userData.lastname && new_user.firstname == userData.firstname, 'failed to update database' );

	}

	public void function test_null_update() {

		var userData = { 'id' = 1, 'testNull' = javaCast( 'null', '' ) };
		var result = persistence.save( 'users', userData );
		var new_user = persistence.get( 'users', 1 );

		//debug( result );
		//debug( new_user );

		assertTrue( result.success, 'failed success check' );
		assertTrue( result.primarykey == 1, 'failed to return correct primarykey' );
		assertTrue( find( 'Update', result.message ), 'failed to return correct message' );
		assertTrue( structKeyExists( result, 'originalrow' ), 'failed to return original object' );
		assertTrue( arrayFindNoCase( structKeyArray( new_user ), 'testNull' ), 'key for null value does not exists' );
		assertTrue( !structKeyExists( new_user, 'testNull' ) || isNull( new_user.testNull ), 'value was supposed to be null' );

	}

	public void function test_failed_update() {

		var userData = { 'id' = 1, 'lastname' = javaCast( 'null', '' ) };
		var result = persistence.save( 'users', userData );

		//debug( result );

		assertFalse( result.success, 'supposed to fail success check' );

	}

	public void function test_failed_validate_update() {

		var userData = { 'id' = 1, 'lastname' = javaCast( 'null', '' ) };
		var result = persistence.save( 'users', userData, { validate = true } );

		//debug( result );

		assertFalse( result.success, 'supposed to fail success check' );
		assertTrue( find( 'Validation', result.message ), 'failed to return correct message' );
		assertTrue( structKeyExists( result, 'validation' ) && structKeyExists( result.validation, 'lastname' ), 'missing validation message' );

	}

	public void function test_insert() {

		var userData = { 'email' = 'johndoe@example.com', 'firstname' = 'John', 'lastname' = 'Doe', 'passwordhash' = 'HASH', 'testNull' = 'NOTNULL', 'testBoolean' = false  };
		var result = persistence.save( 'users', userData );

		//debug( result );

		assertTrue( result.success, 'failed success check' );
		assertTrue( find( 'Insert', result.message ), 'failed to return correct message' );

		var new_user = persistence.get( 'users', result.primarykey );

		//debug( new_user );

		assertTrue( new_user.lastname == userData.lastname && new_user.firstname == userData.firstname, 'failed retrieve correct data from database' );

	}

	public void function test_null_insert() {

		var userData = { 'email' = 'johndoe@example.com', 'firstname' = 'John', 'lastname' = 'Doe', 'passwordhash' = 'HASH', 'testNull' = javaCast( 'null', '' ), 'testBoolean' = false  };
		var result = persistence.save( 'users', userData );

		//debug( result );

		assertTrue( result.success, 'failed success check' );
		assertTrue( find( 'Insert', result.message ), 'failed to return correct message' );

		var new_user = persistence.get( 'users', result.primarykey );

		//debug( new_user );

		assertTrue( arrayFindNoCase( structKeyArray( new_user ), 'testNull' ), 'key for null value does not exists' );
		assertTrue( !structKeyExists( new_user, 'testNull' ) || isNull( new_user.testNull ), 'value was supposed to be null' );

	}

	public void function test_failed_insert() {

		var userData = { 'email' = 'johndoe@example.com' };
		var result = persistence.save( 'users', userData );

		//debug( result );

		assertFalse( result.success, 'supposed to fail success check' );

	}

	public void function test_save_array() {

		var posts = [ { 'id' = 1, 'post_text' = 'updated post', 'user_id' = 2, createdat = now(), updatedat = now() }, { 'user_id' = 1, createdat = now(), updatedat = now() }, { 'post_text' = 'inserted post', 'user_id' = 1, createdat = now(), updatedat = now() } ];
		var result = persistence.save( 'posts', posts );

		//debug( result );

		assertIsArray( result, 'result was supposed to be an array' );

		assertTrue( result[ 1 ].success, 'failed update success check' );
		assertFalse( result[ 2 ].success, 'supposed to fail success check' );
		assertTrue( result[ 3 ].success, 'failed insert success check' );

		assertTrue( result[ 1 ].primarykey == 1, 'failed to return correct update primarykey' );
		assertTrue( find( 'Update', result[ 1 ].message ), 'failed to return correct update message' );
		assertTrue( structKeyExists( result[ 1 ], 'originalrow' ), 'failed to return original object' );

		assertTrue( result[ 3 ].primarykey > 5, 'failed to return correct insert primarykey' );
		assertTrue( find( 'Insert', result[ 3 ].message ), 'failed to return correct insert message' );

	}

}