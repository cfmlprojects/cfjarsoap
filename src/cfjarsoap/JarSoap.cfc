component {

	/**
	 * constructor
	 * @wsengine.hint webservice engine, one of axis,axis2 or cxf, defaults to axis2
	 * @wsjars.hint where to store the generated jars
	 * @srcdir.hint where to store the generated source, defaults to getTempDirectory()
	 **/
	function init(wsengine="axis2", wsjars= getTempdirectory() & "/wsjars/", srcdir=getTempDirectory() & "/wsdlsrc",reload=true)  {
		WSDLs = {};
		jardir = wsjars;
		wsdlsrc = srcdir;
		dm = new dependency.Manager();
		wsengines = {cfx:{}, axis:{}, axis2:{}};
		var depdir = getDirectoryFromPath(getMetadata(this).path) & "/dependency/#wsengine#/";
		var isolate = true;
		switch(wsengine) {
			case "axis1" :
				isolate = false;
			break;
			case "axis2" :
			case "axis" :
				dm.materialize("org.apache.axis2:axis2-codegen:1.6.2",depdir);
				dm.materialize("org.apache.axis2:axis2-jaxws:1.6.2",depdir);
				dm.materialize("org.apache.axis2:axis2-adb-codegen:1.6.2",depdir);
				dm.materialize("org.apache.axis2:axis2-xmlbeans:1.6.2",depdir);
				dm.materialize("org.apache.ws.commons.axiom:axiom-impl:1.2.13",depdir);
				dm.materialize("org.apache.axis2:axis2-java2wsdl:1.6.2",depdir);
				wsengineObj = createObject("cfjarsoap.axis2.Axis2")
			break;
			case "cxf" :
				dm.materialize("org.springframework:spring-context:3.2.6.RELEASE",depdir);
				dm.materialize("org.apache.cxf:cxf-bundle:3.0.0-milestone2",depdir);
				wsengineObj = createObject("cfjarsoap.cxf.CXF")
			break;
		}
		javaloader = new cfjarsoap.dependency.javatools.LibraryLoader(id="cfjarsoap-classloader-#wsengine#", pathlist="#depdir#,#jardir#", force=reload);
		wsengineObj.init(javaloader,jardir,srcdir);
		return this;
	}

	/**
	 * add a WSDL to be generated/loaded
	 * @wsdl.hint WSDL URI
	 * @endpoint.hint override endpoint URI
	 * @package.hint override generated java package
	 * @jar.hint where to store the generated jar, defaults to jardir
	 * @srcdir.hint where to store the generated java, defaults to srcdir
	 * @addJavaSrcDir.hint directory of java sources to add to jar
	 * @bindings.hint bindings.xml for CXF
	 * @refresh.hint force regeneration of WSDL jar
	 **/
	function addWSDL(required wsdl, endpoint="", package="", jar="", srcdir=wsdlsrc, addJavaSrcDir="", bindings="", boolean refresh=false)  {
		wsengineObj.addWSDL(argumentCollection = arguments);
	}

	/**
	 * returns a list of available services
	 **/
	function getServices()  {
		if(isNull(services)) {
			services = wsengineObj.getServices();
		}
		return services;
	}

	/**
	 * returns the webservices classloader
	 * @reload.hint regenerates classes and returns new classloader
	 **/
	function getClassLoader(reload=false)  {
		return wsengineObj.getClassloader(reload);
	}

	/**
	 * returns the webservices classloader
	 **/
	function getWSEngine()  {
		return wsengineObj;
	}

	/**
	 * converts a POJO to a CFML Struct (with the POJO in _pojo)
	 * @pojo.hint the POJO to convert
	 **/
	function pojo2struct(required pojo)  {
		return wsengineObj.pojo2struct(pojo);
	}

	/**
	 * OnMissingMethod used to call service
	 * @pojo.serviceName the service
	 * @pojo.serviceArguments the service arguments
	 **/
   function onMissingMethod( serviceName, serviceArguments ) {
   	var services = getServices();

   	if(listFindNoCase(structKeyList(services),serviceName)) {
		return wsengineObj.runOperation(serviceName,serviceArguments);
   	}
   	throw(type="jarsoap.service.notfound",message="the service #serviceName# was not found. Available services:#structKeyList(services)#");
   }

}