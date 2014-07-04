	<cfsetting requesttimeout="333"/>
	<!--- set to false when not testing generation to prevent memory leak --->
	<cfset thisdir = getDirectoryFromPath(getTemplatePath()) />
	<cfset jardir = thisdir & "/wsjars" />
	<cfset srcdir = thisdir & "/wssrc" />

	<cffunction name="test">
		<cfscript>
			if(directoryExists(srcdir))
				directoryDelete(srcdir,true);
			wsdl = "http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl";
			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
			cfsoap.addWSDL(wsdl=wsdl);
			var c = cfsoap.getClassLoader(true);
			dump(cfsoap.getServices());
			cb = c.create("com.cdyne.ws.weatherws.WeatherStub");
			dump(cb);
			dump(cb.getCityWeatherByZIP("87104"));
			dump(cfsoap.pojo2struct(cb.getCityWeatherByZIP("87104")));
			dump(cfsoap.getCityWeatherByZIP(87104));

		</cfscript>
	</cffunction>

<cfoutput>
	<cfset test() />
</cfoutput>
