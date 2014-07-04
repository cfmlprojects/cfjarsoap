<cfcomponent extends="mxunit.framework.TestCase">
	<cfsetting requesttimeout="333"/>
	<!--- set to false when not testing generation to prevent memory leak --->
	<cfset regenerate = true />
	<cfset thisdir = getDirectoryFromPath(getMetadata(this).path) />
	<cfset jardir = thisdir & "/wsjars" />
	<cfset srcdir = thisdir & "/wssrc" />

	<cffunction name="beforeTests" returntype="void" access="public">
		<cfif directoryExists(jardir)>
			<cftry>
			<cfset directoryCreate(jardir) />
			<cfset directoryDelete(jardir,true) />
			<cfcatch></cfcatch>
			</cftry>
		</cfif>
	</cffunction>

	<cffunction name="setUp" returntype="void" access="public">
	</cffunction>

	<cffunction name="testWeather">
		<cfscript>
			if(directoryExists(srcdir))
				directoryDelete(srcdir,true);
			wsdl = "http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl";
			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
			cfsoap.addWSDL(wsdl=wsdl);
			var c = cfsoap.getClassLoader(true);
			request.debug("loaded jars:" & c.getClassloaderJars());
			try{
				cb = c.create("com.cdyne.ws.weatherws.WeatherStub");
				debug(cb);
			} catch (any e) {
				debug(e.message);
			}
			debug(cfsoap.getServices());
			debug(cb);
			debug(cb.getCityWeatherByZIP("87104"));
			debug(cfsoap.pojo2struct(cb.getCityWeatherByZIP("87104")));
			debug(cfsoap.getServices());
			debug(cfsoap.getCityWeatherByZIP(87104));
		</cfscript>
	</cffunction>

	<cffunction name="testDisco">
		<cfscript>
			if(directoryExists(srcdir))
				directoryDelete(srcdir,true);
			wsdl = "https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl";
			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
			cfsoap.addWSDL(wsdl=wsdl);
			var c = cfsoap.getClassLoader(true);
			request.debug("loaded jars:" & c.getClassloaderJars());
			try{
				cb = c.create("com.microsoft.schemas.xrm._2011.contracts.DiscoveryServiceStub");
				debug(cb);
			} catch (any e) {
				debug(e.message);
			}
			debug(cfsoap.getServices());
		</cfscript>
	</cffunction>

   </cfcomponent>