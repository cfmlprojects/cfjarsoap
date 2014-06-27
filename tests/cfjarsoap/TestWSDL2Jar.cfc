<cfcomponent extends="mxunit.framework.TestCase">

	<!--- set to false when not testing generation to prevent memory leak --->
	<cfset regenerate = true />

	<cffunction name="beforeTests" returntype="void" access="public">
		<cfset variables.wsdl2jar = new cfjarsoap.WSDL2Jar() />
		<cfset variables.jardir = getDirectoryFromPath(getMetadata(this).path) & "/wsjars" />
		<cfif regenerate>
			<cfset directoryExists(jardir) ? directoryDelete(jardir,true):"" />
			<cfset directoryCreate(jardir) />
		</cfif>
	</cffunction>

	<cffunction name="setUp" returntype="void" access="public">
		<cfset variables.wsdl2jar = new cfjarsoap.WSDL2Jar() />
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
 			wsdl2jar.jar("http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl",jardir & "/weather.jar");
 			var classloader = wsdl2jar.getClassLoader(jardir);
			var weatherSoap = classloader.create("com.cdyne.ws.WeatherWS.WeatherLocator").getWeatherSoap();
			// returns the actual bean
			var weatherByZip = weatherSoap.getCityWeatherByZIP("87104");
			assertEquals("Albuquerque",weatherByZip.getCity());
			debug("city:" & weatherByZip.getCity());
			debug("wind:" & weatherByZip.getWind());
			debug("temp:" & weatherByZip.getTemperature());

			//.NET using generated stuff
 			wsdl2jar.jar("http://www.webservicex.net/uszip.asmx?WSDL",jardir & "/uszip.jar");
 			var classloader = wsdl2jar.getClassLoader(jardir);
			var zipSoap = classloader.create("NET.webserviceX.www.USZipLocator").getUSZipSoap();
			// this service returns plain XML messages apparently
			var areacodes = zipSoap.getInfoByZIP("87104").get_any();
			assertEquals(xmlSearch(areacodes[1],"//CITY")[1].xmlText,"Albuquerque");

			ws = createObject("webservice","http://www.webservicex.net/uszip.asmx?WSDL");
			debug(ws);
			try {
				res = ws.getInfoByAreaCode("87104");
				debug(res);
			} catch (any e) {
				debug("The normal WS call always fails for some reason!" & e.message);
			}


		</cfscript>
	</cffunction>

	<cffunction name="testCreateJar2">
		<cfscript>
			// first, a normal call
			var ws = createObject("webservice","https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl");
			request.debug(ws);

			// the same call using generated stuff
			wsdl2jar.jar("https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl",jardir & "/disco.jar");
 			var classloader = wsdl2jar.getClassLoader(jardir);
		</cfscript>
	</cffunction>

   </cfcomponent>