component extends="testBase" {
	
	public void function setup() {

		setupcfc.resetDb();

	}

	public void function test_update_validate_null() {

		var result = persistence.save( 'comments', { 'post_id' = javaCast( 'null', '' ) }, { validate = true } );

		//debug( result );

		assertFalse( result.success, 'was supposed to fail success check' );
		assertTrue( find( 'Validation', result.message ), 'failed to return correct message' );
		assertTrue( structKeyExists( result, 'validation' ) && structKeyExists( result.validation, 'post_id' ), 'missing validation struct' );
		assertIsArray( result.validation.post_id, 'missing expected validation array' );
			
	}

	public void function test_update_validate_invalid_datatype() {

		var result = persistence.save( 'comments', { 'post_id' = 'test' }, { validate = true } );

		//debug( result );

		assertFalse( result.success, 'was supposed to fail success check' );
		assertTrue( find( 'Validation', result.message ), 'failed to return correct message' );
		assertTrue( structKeyExists( result, 'validation' ) && structKeyExists( result.validation, 'post_id' ), 'missing validation struct' );
		assertIsArray( result.validation.post_id, 'missing expected validation array' );
			
	}

}