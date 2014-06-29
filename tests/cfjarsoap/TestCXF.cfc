<cfcomponent extends="mxunit.framework.TestCase">
	<cfsetting requesttimeout="333"/>
	<!--- set to false when not testing generation to prevent memory leak --->
	<cfset regenerate = true />
	<cfset thisdir = getDirectoryFromPath(getMetadata(this).path) />
	<cfset jardir = thisdir & "/wsjars" />
	<cfset srcdir = thisdir & "/wssrc" />

	<cffunction name="setUp" returntype="void" access="public">
	</cffunction>

	<cffunction name="testSpringBus">
		<cfscript>

//System.setProperty("java.security.auth.login.config", "crm-integration/src/main/resources/login.conf");
//System.setProperty("java.security.krb5.conf", "crm-integration/src/main/resources/krb5.conf");

			// the same call using generated stuff
			var cxf = new cfjarsoap.cxf.CXF(jardir,srcdir);
			var host = "disco.crm.dynamics.com";
			var orgHost = "yourcrmonlineinstance.crm.dynamics.com";
			var discoveryWSDL = "https://#host#/XRMServices/2011/Discovery.svc?wsdl";
			var organizationWSDL = "https://#orgHost#/XRMServices/2011/Organization.svc?wsdl";
			var bindings = thisdir & "/spring/bindings.xml";
			cxf.addWSDL(wsdl=discoveryWSDL, addJavaSrcDir=thisdir & "/spring/javasrc", bindings=bindings);
			cxf.addWSDL(wsdl=organizationWSDL, bindings=bindings);

			cxf.setSpringApplicationContext(thisdir & "spring/applicationContext.xml");
			var c = cxf.getClassLoader();

//			debug(cxf.getServices());

//			var service = c.create("com.microsoft.schemas.xrm._2011.contracts.OrganizationService").init(createObject("java","java.net.URL").init(organizationWSDL));
			var service = c.create("com.microsoft.schemas.xrm._2011.contracts.OrganizationService").init();
			var orgReq = c.create("com.microsoft.schemas.xrm._2011.contracts.OrganizationRequest").init();
			var IOrganizationService = c.getLoader().getURLClassloader().loadClass("com.microsoft.schemas.xrm._2011.contracts.services.IOrganizationService");

port = service.getCustomBindingIOrganizationService();
request.debug(orgReq);
//orgReq.setRequestName("WhoAmI");
port.execute(orgReq);
return "yay";

			var port = service.getPort(IOrganizationService);
			var entity = c.create("com.microsoft.schemas.xrm._2011.contracts.Entity").init();
			debug(entity);
			port.create(entity);

			debug(cxf.getServices());
 			var asso = cxf.create("com.microsoft.schemas.xrm._2011.contracts.entities.Entity");
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
			var cxf = new cfjarsoap.cxf.CXF();
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