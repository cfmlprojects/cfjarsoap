<cfcomponent extends="mxunit.framework.TestCase">
	<cfsetting requesttimeout="333"/>
	<!--- set to false when not testing generation to prevent memory leak --->
	<cfset regenerate = true />
	<cfset thisdir = getDirectoryFromPath(getMetadata(this).path) />
	<cfset jardir = thisdir & "/wsjars" />
	<cfset srcdir = thisdir & "/wssrc" />

	<cffunction name="setUp" returntype="void" access="public">
	</cffunction>

	<cffunction name="testCreateJar">
		<cfscript>
			if(directoryExists(srcdir))
				directoryDelete(srcdir,true);
			wsdl = "http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl";
			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
			cfsoap.addWSDL(wsdl=wsdl);
			var c = cfsoap.getClassLoader(false);
			cb = c.create("com.cdyne.ws.weatherws.WeatherStub");
			debug(cb);
			debug(cb.getCityWeatherByZIP("87104"));
			debug(cfsoap.pojo2struct(cb.getCityWeatherByZIP("87104")));
			debug(cfsoap.getServices());
			debug(cfsoap.getCityWeatherByZIP(87104));

		</cfscript>
	</cffunction>

   </cfcomponent>