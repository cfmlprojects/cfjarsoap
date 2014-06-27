<cfcomponent extends="mxunit.framework.TestCase">

	<!--- set to false when not testing generation to prevent memory leak --->
	<cfset regenerate = true />
	<cfset thisdir = getDirectoryFromPath(getMetadata(this).path) />
	<cfset jardir = thisdir & "/wsjars" />

	<cffunction name="setUp" returntype="void" access="public">
	</cffunction>

	<cffunction name="testSpringBus">
		<cfscript>
			// the same call using generated stuff
			var cxf = new cfjarsoap.cxf.CXF("https://pixl8.smartmembership.net/XRMServices/2011/Organization.svc?wsdl",thisdir & "MSCRM2011/applicationContext.xml");
			debug(cxf.getServices());
 			var asso = cxf.create("com.microsoft.schemas.xrm._2011.contracts.services.Create");
 			request.debug(asso);
 			cxf.create(asso);
return;

 			cxf.setWSDLURL("http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl");
 			cxf.callMethod("getServices",["http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl"]);
 			debug(cxf.getCityForecastByZip("87104"));
 			cxf.callMethod("getServices",["https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl"]);
 			//cxf.getServices("https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl");
		</cfscript>
	</cffunction>

	<cffunction name="testCreateJar">
		<cfscript>
			// the same call using generated stuff
			var cxf = new cfjarsoap.cxf.CXF("https://pixl8.smartmembership.net/XRMServices/2011/Organization.svc?wsdl");
 			var asso = cxf.create("com.microsoft.schemas.xrm._2011.contracts.services.Associate");
 			request.debug(asso);
 			cxf.Associate(asso);
return;

 			cxf.setWSDLURL("http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl");
 			cxf.callMethod("getServices",["http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl"]);
 			debug(cxf.getCityForecastByZip("87104"));
 			cxf.callMethod("getServices",["https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl"]);
 			//cxf.getServices("https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl");
		</cfscript>
	</cffunction>

	<cffunction name="testWSDLToJava">
		<cfscript>
			// the same call using generated stuff
// 			cxf.wsdl2java("https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl");
 			var cxf = new cfjarsoap.cxf.CXF("https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl");
 			cxf.wsdl2java();
		</cfscript>
	</cffunction>

   </cfcomponent>