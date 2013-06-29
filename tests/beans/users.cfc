component {
	
	public any function init() {
		return this;
	}

	public string function getSingularName() { return 'user'; }

	public void function afterGet( required array users, required struct options ) {
		for ( var user in users ) {
			user.fullname = user.firstname & ' ' & user.lastname;
		}
	}

}