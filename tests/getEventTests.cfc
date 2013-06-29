component extends="mxunit.framework.TestCase" {
	
	public void function beforeTests() {

		setupcfc = new setup.setup( request.datasourceName, request.db.DATABASE_PRODUCTNAME );

		data = setupcfc.getData();

	}

	public void function test_afterget_result_modification() {

		var beanfactory = new beanfactory.beanfactory( [ 'users' ] );
		var persistence = new persistence.persistence( request.datasourceName, { }, beanfactory );

		var user = persistence.get( 'users', 1 );

		//debug( user );

		assertTrue( structKeyExists( user, 'fullname' ), 'result was not modified by afterGet method' );
			
	}

	public void function test_beforeget_property_setting() {

		var beanfactory = new beanfactory.beanfactory( [ 'comments' ] );
		var persistence = new persistence.persistence( request.datasourceName, { }, beanfactory );

		var commentOne = persistence.get( 'comments', 1 );
		var commentTwo = persistence.get( 'comments', 1, { 'dontreturnanything' = true } );

		//debug( commentOne );
		//debug( commentTwo );

		assertTrue( !isNull( commentOne ), 'commentOne should not be null' );
		assertTrue( isNull( commentTwo ), 'commentTwo should be null' );
			
	}

	public void function test_beforeget_option_setting() {

		var beanfactory = new beanfactory.beanfactory( [ 'posts' ] );
		var persistence = new persistence.persistence( request.datasourceName, { }, beanfactory );

		var post = persistence.get( 'posts', 2 );

		//debug( post );

		assertTrue( structKeyExists( post, 'users' ), 'include was not added to options struct by beforeGet method' );
			
	}

	public void function test_get_include_with_singular_name() {

		var beanfactory = new beanfactory.beanfactory( [ 'users' ] );
		var persistence = new persistence.persistence( request.datasourceName, { }, beanfactory );


		var post = persistence.get( 'posts', 2, { include = 'users' } );

		//debug( post );

		assertTrue( structKeyExists( post, 'user' ), 'include was not added with the correct singular name' );
			
	}

}