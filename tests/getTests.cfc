component extends="testBase" {
	
	public void function get_with_no_valid_pk() {

		var user = persistence.get( 'users', 0 );
		assertTrue( isNull( user ), 'result was supposed to be null' );

	}

	public void function get_with_invalid_pk() {

		try {
		
			var user = persistence.get( 'users', 'bad_key' );
			fail( 'persistence cfc was supposed to throw an error' );

		} catch( any e ) {
			assertTrue( e.message == 'Bad query result, nothing was retrieved!', 'wrong error was thrown' );
		}

	}

	public void function get_with_single_valid_pk() {

		var user = persistence.get( 'users', 1 );

		//debug( user );

		assertIsStruct( user, 'result was supposed to be a struct' );
		assertEquals( user.id, 1, 'data retrieved does not match expected result' );

	}

	public void function get_with_multiple_valid_pks() {

		var users = persistence.get( 'users', [ 1, 3 ] );

		//debug( users );

		assertIsArray( users, 'result was supposed to be an array' );
		assertEquals( arrayFlatten( users ), [ 1, 3 ], 'data retrieved does not match expected result' );

	}

	public void function get_with_orderby() {

		var posts = persistence.get( 'posts', [ 3, 4 ], { orderby = 'createdat' } );

		//debug( posts );

		assertIsArray( posts, 'result was supposed to be an array' );
		assertEquals( arrayFlatten( posts ), [ 4, 3 ], 'data retrieved does not match expected result' );

	}

	public void function get_with_maxrows() {

		var posts = persistence.get( 'posts', [ 3, 4 ], { maxrows = 1 } );

		//debug( posts );

		assertIsStruct( posts, 'result was supposed to be a struct' );
		assertEquals( posts.id, 3, 'data retrieved does not match expected result' );

	}

	public void function get_with_maxrows_and_orderby() {

		var posts = persistence.get( 'posts', [ 1, 2 ], { maxrows = 1, orderby = 'createdat desc' } );

		//debug( posts );

		assertIsStruct( posts, 'result was supposed to be an array' );
		assertEquals( posts.id, 2, 'data retrieved does not match expected result' );

	}

	public void function get_with_include_many_to_one() {

		var post = persistence.get( 'posts', 2, { include = 'users' } );
		var expected_result = data.users[ 3 ];

		//debug( post );
		//debug( expected_result );

		assertTrue( structKeyExists( post, 'users' ), 'included table was not retrieved' );
		assertIsStruct( post.users, 'include was supposed to be an struct' );
		assertEquals( post.users, expected_result, 'data retrieved does not match expected result' );

	}

	public void function get_with_include_one_to_many() {

		var user = persistence.get( 'users', 1, { include = 'posts' } );

		//debug( user );

		assertTrue( structKeyExists( user, 'posts' ), 'included table was not retrieved' );
		assertIsArray( user.posts, 'include was supposed to be an array' );
		assertEquals( arrayFlatten( user.posts ), [ 5 ], 'data retrieved does not match expected result' );

	}

	public void function get_with_multiple_includes() {

		var post = persistence.get( 'posts', 3, { include = [ 'comments', 'users' ] } );

		//debug( post );

		assertTrue( structKeyExists( post, 'users' ), 'included table was not retrieved' );
		assertTrue( structKeyExists( post, 'comments' ), 'included table was not retrieved' );
		
		assertIsArray( post.comments, 'include was supposed to be an array' );
		assertIsStruct( post.users, 'include was supposed to be a struct' );
		
		assertEquals( arrayFlatten( post.comments ), [ 4, 5, 6 ], 'data retrieved does not match expected result' );
		assertEquals( post.users.id, 2, 'data retrieved does not match expected result' );

	}

}