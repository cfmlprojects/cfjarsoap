<cfcomponent extends="mxunit.framework.TestCase">

	<cffunction name="dumpvar" access="private">
		<cfargument name="var">
		<cfdump var="#var#">
		<cfabort/>
	</cffunction>

  <cffunction name="setUp" returntype="void" access="public">
 		<cfset variables.wsdl2jar = new cfjarsoap.WSDL2Jar() />
 		<cfset variables.jardir = getDirectoryFromPath(getMetadata(this).path) & "/wsjars" />
		<cfset directoryExists(jardir) ? directoryDelete(jardir,true):"" />
		<cfset directoryCreate(jardir) />
  </cffunction>

	<cffunction name="testCreateJar">
		<cfscript>
 			wsdl2jar.jar("http://www.webservicex.net/uszip.asmx?WSDL",jardir & "/uszip.jar");
 			var classloader = wsdl2jar.getClassLoader(jardir);
			var loc = classloader.create("NET.webserviceX.www.USZipLocator");
			var areacodes = loc.getUSZipSoap().getInfoByZIP("87104").get_any();
			debug(areacodes.toString());
			debug(loc);
		</cfscript>
	</cffunction>

   </cfcomponent>