component {
	
	public any function init( array beansToRegister = [ ], string suffix = 'persistence' ) {
		variables.beans = { };
		registerBeans( beansToRegister, suffix );
		return this;
	}

	public void function addBean( required string beanName, required any bean ) {
		variables.beans[ beanName ] = bean;
	}

	public boolean function containsBean( required string beanName ) {
		return structKeyExists( variables.beans, beanName );
	}

	public any function getBean( required string beanName ) {
		if ( containsBean( beanName ) ) return variables.beans[ beanName ];
		throw( 'missing bean' );
	}

	private void function registerBeans( array beansToRegister = [ ], string suffix = 'persistence' ) {
		var allBeans = [  'global', 'users', 'posts', 'comments' ];
		for ( var beanName in allBeans ) {
			if ( arrayIsEmpty( beansToRegister ) || arrayFind( beansToRegister, beanName ) ) {
				addBean( beanName & suffix, new "beans.#beanname#"() );
			}
		}
	}
	
}