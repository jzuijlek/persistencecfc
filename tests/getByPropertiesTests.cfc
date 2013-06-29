component extends="testBase" {
	
	public void function getbyproperties_with_no_results() {

		var posts = persistence.getByProperties( 'posts', { 'user_id' = 0 } );

		//debug( posts );

		assertIsArray( posts, 'result was supposed to be an array' );
		assertTrue( arrayLen( posts ) == 0, 'result was supposed to be an empty array' );

	}

	public void function getbyproperties_with_fk() {

		var comments = persistence.getByProperties( 'comments', { 'user_id' = 3 } );

		//debug( comments );

		assertIsArray( comments, 'result was supposed to be an array' );
		assertTrue( arrayLen( comments ) == 5, 'result was supposed to be an array with 5 elements' );

	}

	public void function getbyproperties_with_multiple_params() {

		var comments = persistence.getByProperties( 'comments', { 'user_id' = 3, 'post_id' = 5 } );

		//debug( comments );

		assertIsArray( comments, 'result was supposed to be an array' );
		assertTrue( arrayLen( comments ) == 3, 'result was supposed to be an array with 3 elements' );

	}

	public void function getbyproperties_with_alternate_operator() {

		var posts = persistence.getByProperties( 'posts', { 'createdat <' = '6/11/2013' } );

		//debug( posts );

		assertIsArray( posts, 'result was supposed to be an array' );
		assertTrue( arrayLen( posts ) == 2, 'result was supposed to be an array with 2 elements' );

	}

	public void function getbyproperties_with_orderby() {

		var comments = persistence.getByProperties( 'comments', { 'user_id' = 3, 'post_id' = 5 }, { 'orderby' = 'createdat desc' } );

		//debug( comments );

		assertIsArray( comments, 'result was supposed to be an array' );
		assertTrue( arrayLen( comments ) == 3, 'result was supposed to be an array with 3 elements' );
		assertEquals( arrayFlatten( comments ), [ 3, 2, 1 ], 'data retrieved does not match expected result' );

	}

	public void function getbyproperties_with_maxrows() {

		var comments = persistence.getByProperties( 'comments', { 'user_id' = 3, 'post_id' = 5 }, { 'maxrows' = 2 } );

		//debug( comments );

		assertIsArray( comments, 'result was supposed to be an array' );
		assertTrue( arrayLen( comments ) == 2, 'result was supposed to be an array with 2 elements' );

	}

	public void function getbyproperties_with_orderby_and_maxrows() {

		var comments = persistence.getByProperties( 'comments', { 'user_id' = 3, 'post_id' = 5 }, { 'orderby' = 'createdat desc', 'maxrows' = 2 } );

		//debug( comments );

		assertIsArray( comments, 'result was supposed to be an array' );
		assertTrue( arrayLen( comments ) == 2, 'result was supposed to be an array with 2 elements' );
		assertEquals( arrayFlatten( comments ), [ 3, 2 ], 'data retrieved does not match expected result' );

	}

	public void function getbyproperties_with_include_many_to_one() {

		var posts = persistence.getByProperties( 'posts', { 'createdat <' = '6/11/2013' }, { 'include' = 'users', orderby = 'user_id' } );

		//debug( posts );

		assertTrue( structKeyExists( posts[ 1 ], 'users' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( posts[ 2 ], 'users' ), 'included table was not retrieved' );
		assertIsStruct( posts[ 1 ].users, 'include was supposed to be an struct' );
		assertIsStruct( posts[ 2 ].users, 'include was supposed to be an struct' );
		assertEquals( posts[ 1 ].users.id, 1, 'data retrieved does not match expected result' );
		assertEquals( posts[ 2 ].users.id, 2, 'data retrieved does not match expected result' );

	}

	public void function getbyproperties_with_include_many_to_one_null() {

		var posts = persistence.getByProperties( 'posts', { 'updatedat <' = '6/16/2013' }, { 'include' = 'users', 'orderby' = 'id' } );

		//debug( posts );

		assertTrue( arrayFind( structKeyArray( posts[ 1 ] ), 'users' ), 'included table was not retrieved' );
		assertTrue( arrayFind( structKeyArray( posts[ 2 ] ), 'users' ), 'included table was not retrieved' );
		assertTrue( !structKeyExists( posts[ 1 ], 'users' ) || isNull( posts[ 1 ].users ), 'include was supposed to be null' );
		assertIsStruct( posts[ 2 ].users, 'include was supposed to be an struct' );

	}

	public void function getbyproperties_with_include_one_to_many() {

		var posts = persistence.getByProperties( 'posts', { 'createdat <' = '6/11/2013' }, { 'include' = 'comments' } );

		//debug( posts );

		assertTrue( structKeyExists( posts[ 1 ], 'comments' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( posts[ 2 ], 'comments' ), 'included table was not retrieved' );
		assertIsArray( posts[ 1 ].comments, 'include was supposed to be an array' );
		assertIsArray( posts[ 2 ].comments, 'include was supposed to be an array' );
		assertTrue( arrayLen( posts[ 1 ].comments ) == 0, 'result was supposed to be an array with 0 elements' );
		assertTrue( arrayLen( posts[ 2 ].comments ) == 3, 'result was supposed to be an array with 3 elements' );

	}

	public void function getbyproperties_with_include_struct() {

		var posts = persistence.getByProperties( 'posts', { 'createdat <' = '6/11/2013' }, { 'include' = { 'name' = 'comments', 'orderby' = 'updatedat' } } );

		//debug( posts );

		assertTrue( structKeyExists( posts[ 1 ], 'comments' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( posts[ 2 ], 'comments' ), 'included table was not retrieved' );
		assertIsArray( posts[ 1 ].comments, 'include was supposed to be an array' );
		assertIsArray( posts[ 2 ].comments, 'include was supposed to be an array' );
		assertTrue( arrayLen( posts[ 1 ].comments ) == 0, 'result was supposed to be an array with 0 elements' );
		assertTrue( arrayLen( posts[ 2 ].comments ) == 3, 'result was supposed to be an array with 3 elements' );
		assertEquals( arrayFlatten( posts[ 2 ].comments ), [ 1, 3, 2 ], 'data retrieved does not match expected result' );

	}

	public void function getbyproperties_with_multiple_includes() {

		var posts = persistence.getByProperties( 'posts', { 'createdat <' = '6/11/2013' }, { 'include' = [ { 'name' = 'comments', 'orderby' = 'updatedat' }, 'users' ] } );

		//debug( post );

		assertTrue( structKeyExists( posts[ 1 ], 'users' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( posts[ 1 ], 'comments' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( posts[ 2 ], 'users' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( posts[ 2 ], 'comments' ), 'included table was not retrieved' );
		
		assertIsArray( posts[ 1 ].comments, 'include was supposed to be an array' );
		assertIsArray( posts[ 2 ].comments, 'include was supposed to be an array' );
		assertIsStruct( posts[ 1 ].users, 'include was supposed to be an struct' );
		assertIsStruct( posts[ 2 ].users, 'include was supposed to be an struct' );
		
		assertEquals( posts[ 1 ].users.id, 2, 'data retrieved does not match expected result' );
		assertEquals( posts[ 2 ].users.id, 1, 'data retrieved does not match expected result' );

	}

	public void function getbyproperties_with_multiple_includes_order_reversed() {

		var posts = persistence.getByProperties( 'posts', { 'createdat <' = '6/11/2013' }, { 'include' = [ 'users', 'comments' ] } );

		//debug( posts );

		assertTrue( structKeyExists( posts[ 1 ], 'users' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( posts[ 1 ], 'comments' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( posts[ 2 ], 'users' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( posts[ 2 ], 'comments' ), 'included table was not retrieved' );
		
		assertIsArray( posts[ 1 ].comments, 'include was supposed to be an array' );
		assertIsArray( posts[ 2 ].comments, 'include was supposed to be an array' );
		assertIsStruct( posts[ 1 ].users, 'include was supposed to be an struct' );
		assertIsStruct( posts[ 2 ].users, 'include was supposed to be an struct' );
		
	}

}