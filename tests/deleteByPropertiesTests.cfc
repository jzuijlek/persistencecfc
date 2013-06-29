component extends="testBase" {
	
	public void function setup() {

		setupcfc.resetDb();

	}

	public void function deletebyproperties_test() {

		var result = persistence.deleteByProperties( 'comments', { 'post_id' = 5 } );
		var deleted_comments = persistence.getByProperties( 'comments', { 'post_id' = 5 } );

		//debug( result );

		assertTrue( result.success, 'failed success check' );
		assertTrue( result.rowsdeleted == 3, 'did not return correct rowsdeleted' );
		assertTrue( isArray( result.originalrows ) && arrayLen( result.originalrows ) == 3, 'did not return correct originalrows array length' );
		assertEquals( arrayFlatten( result.originalrows ), [ 1,2,3 ], 'did not return correct originalrows array' );
			
	}

}