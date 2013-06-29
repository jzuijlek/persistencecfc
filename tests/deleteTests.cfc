component extends="testBase" {
	
	public void function setup() {

		setupcfc.resetDb();

	}

	public void function delete_with_no_valid_pk() {

		var result = persistence.delete( 'comments', 0 );
		assertFalse( result.success, 'supposed to fail success check' );

	}

	public void function delete_with_invalid_pk() {

		try {
		
			var result = persistence.delete( 'comments', 'bad_key' );
			fail( 'persistence cfc was supposed to throw an error' );

		} catch( any e ) {
			//debug( e );
		}

	}

	public void function delete_with_single_valid_pk() {

		var result = persistence.delete( 'comments', 1 );
		var deleted_comment = persistence.get( 'comments', 1 );
		
		//debug( result );

		assertTrue( result.success, 'failed success check' );
		assertTrue( isNull( deleted_comment ), 'failed to delete from database' );
		assertTrue( result.rowsDeleted == 1, 'did not return correct rowsDeleted' );
		assertTrue( isArray( result.originalrows ) && arrayLen( result.originalrows ) == 1, 'did not return correct array of deleted rows' );
		assertTrue( result.originalrows[ 1 ].id == 1, 'did not return correct original row' );

	}

	public void function delete_with_multiple_valid_pks() {

		var result = persistence.delete( 'comments', [ 1,2,4 ] );
		var deleted_comments = persistence.get( 'comments', [ 1,2,4 ] );
		
		//debug( result );

		assertTrue( result.success, 'failed success check' );
		assertTrue( isNull( deleted_comments ), 'failed to delete from database' );
		assertTrue( result.rowsDeleted == 3, 'did not return correct rowsDeleted' );
		assertTrue( isArray( result.originalrows ) && arrayLen( result.originalrows ) == 3, 'did not return correct array of deleted rows' );
		assertEquals( arrayFlatten( result.originalrows ), [ 1,2,4 ], 'did not return correct original rows' );

	}

}