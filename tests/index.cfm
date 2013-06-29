<cfscript>
cfcBase = replace( replace( getDirectoryFromPath( getCurrentTemplatePath() ), expandPath( '/' ), '' ), '/', '.', 'all' );

testSuite = createObject( "component", "mxunit.framework.TestSuite" ).TestSuite();

cfcNames = directoryList( getDirectoryFromPath( getCurrentTemplatePath() ), false, 'name', '*.cfc' );

for ( cfcName in cfcNames ) {
	if ( arrayFindNoCase( [ 'Application.cfc', 'testBase.cfc' ], cfcName ) ) continue;
	testSuite.addAll( cfcBase & replace( cfcName, '.cfc', '' ) );
}

results = testSuite.run();

// reset the db after the tests -- the init function of the setupcfc resets the db, so we only need to create it
setupcfc = new setup.setup( request.datasourceName, request.db.DATABASE_PRODUCTNAME );

</cfscript>
<cfoutput>
<h1 style="padding:10px;">persistence.cfc tests</h1>
<h3 style="padding:10px;">
#server.coldfusion.productname#: #server.coldfusion.productname eq 'Railo' ? server.railo.version : listChangeDelims( server.coldfusion.productversion, '.' )#<br>
#request.db.DATABASE_PRODUCTNAME#: #request.db.DATABASE_VERSION#<br>
#request.db.DRIVER_NAME#: #request.db.DRIVER_VERSION#
</h3>
<h3 style="padding:10px;">Datasource: #request.datasourceName#</h3>

<p style="padding:10px;">The testing datasource name can be set in tests/Application.cfc</p>

#results.getResultsOutput( 'html' )#
</cfoutput>