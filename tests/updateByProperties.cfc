component extends="testBase" {
	
	public void function setup() {

		setupcfc.resetDb();

	}

	public void function updatebyproperties_test() {

		var propertiesToUpdate = { 'user_id' = 1, 'updatedat' = now() };
		var properties = { 'user_id' = 3 };

		var result = persistence.updateByProperties( 'comments', propertiesToUpdate, properties );
		var updated_rows = persistence.getByProperties( 'comments', { 'user_id' = 1 } ); 
		
		//debug( result );
		//debug( propertiesToUpdate );
		//debug( updated_rows );

		assertTrue( result.success, 'failed success check' );
		assertTrue( structKeyExists( result, 'originalrows' ), 'failed to return original rows' );
		assertEquals( arrayFlatten( result.originalrows ), [ 1, 2, 3, 7, 9 ], 'failed to return correct original rows' );
		assertEquals( arrayFlatten( updated_rows ), [ 1, 2, 3, 5, 7, 9, 10 ], 'failed to update correctly' );
		assertTrue( updated_rows[ 1 ].user_id == 1 && updated_rows[ 1 ].updatedat == propertiesToUpdate.updatedat, 'failed to update correctly' );
			
	}

	public void function updatebyproperties_array_param_test() {

		var propertiesToUpdate = { 'comment_text' = 'updated' };
		var properties = { 'user_id' = [ 1, 3 ] };

		var result = persistence.updateByProperties( 'comments', propertiesToUpdate, properties );
		var updated_rows = persistence.getByProperties( 'comments', properties ); 
		
		debug( result );
		debug( propertiesToUpdate );
		debug( updated_rows );

		assertTrue( result.success, 'failed success check' );
		assertTrue( structKeyExists( result, 'originalrows' ), 'failed to return original rows' );
		assertEquals( arrayFlatten( result.originalrows ), [ 1, 2, 3, 5, 7, 9, 10 ], 'failed to return correct original rows' );
		assertEquals( arrayFlatten( updated_rows ), [ 1, 2, 3, 5, 7, 9, 10 ], 'failed to update correct rows' );
		assertEquals( arrayFlatten( updated_rows, 'comment_text' ), [ 'updated','updated','updated','updated','updated','updated','updated' ], 'failed to update correctly' );
			
	}

}