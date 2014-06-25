<cfcomponent extends="mxunit.framework.TestCase">

	<!--- set to false when not testing generation to prevent memory leak --->
	<cfset regenerate = true />
	<cfset jardir = getDirectoryFromPath(getMetadata(this).path) & "/wsjars" />

	<cffunction name="beforeTests" returntype="void" access="public">
		<cfset variables.jarSoap = new cfjarsoap.jarSoap(jardir) />
	</cffunction>

	<cffunction name="setUp" returntype="void" access="public">
		<cfset variables.jarSoap = new cfjarsoap.jarSoap(jardir) />
	</cffunction>

	<cffunction name="testCreateJar">
		<cfscript>
			// first, a normal call
			var ws = createObject("webservice","http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl");
			request.debug(ws);
			// returns a struct of the javabean
			var weatherStruct = ws.getCityWeatherByZIP("87104");
			request.debug(weatherStruct);

			// the same call using generated stuff
 			jarSoap.addWSDL("http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl");
 			jarSoap.addWSDL("http://www.webservicex.net/uszip.asmx?WSDL");

 			var classloader = jarSoap.getClassLoader();
 			debug(jarSoap.getServices());
			var weatherStruct = jarSoap.getCityWeatherByZIP("87104");
			request.debug(weatherStruct);
			assertEquals("Albuquerque",weatherStruct.City);
			assertEquals("Albuquerque",weatherStruct._pojo.getCity());

			var zipStruct = jarSoap.getInfoByZIP("87104");
		</cfscript>
	</cffunction>

   </cfcomponent>