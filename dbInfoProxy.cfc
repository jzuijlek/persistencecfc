<cfcomponent output="false">

	<cffunction name="execute" access="public" returntype="any" output="false">
		<cfargument name="name" type="any" default="result">
		<cfset var result = "">
		<cfdbinfo attributeCollection="#arguments#" />
		<cfreturn result>
	</cffunction>
	
</cfcomponent>