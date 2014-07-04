component {

	function init(wsengine="axis2", wsjars= getTempdirectory() & "/wsjars/", srcdir=getTempDirectory() & "/wsdlsrc")  {
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
		javaloader = new cfjarsoap.dependency.javatools.LibraryLoader(id="cfjarsoap-classloader", pathlist="#depdir#,#jardir#");
		wsengineObj.init(javaloader,jardir,srcdir);
		return this;
	}

	function addWSDL(required wsdl, package="", jar="", srcdir=wsdlsrc, addJavaSrcDir="", bindings="", boolean refresh=false)  {
		wsengineObj.addWSDL(argumentCollection = arguments);
	}

	function getServices()  {
		if(isNull(services)) {
			services = wsengineObj.getServices();
		}
		return services;
	}

	function getClassLoader(reload=false)  {
		return wsengineObj.getClassloader(reload);
	}

	function getWSEngine()  {
		return wsengineObj;
	}

	function pojo2struct(required pojo)  {
		return wsengineObj.pojo2struct(pojo);
	}

   function onMissingMethod( missingMethodName, missingMethodArguments ) {
   	var services = getServices();
   	if(listFindNoCase(structKeyList(services),missingMethodName)) {
   		var service = services[missingMethodName];
   		var soap = getClassLoader().create(service.locator);
   		var pojo = "";
   		switch(listLen(structKeyList(service.arguments))) {
   			case 1:
	   			return wsengineObj.runOperation(missingMethodName,missingMethodArguments[1]);
   			case 2:
	   			return wsengineObj.runOperation(missingMethodName,missingMethodArguments[1],missingMethodArguments[2]);
   			case 3:
	   			return wsengineObj.runOperation(missingMethodName,missingMethodArguments[1],missingMethodArguments[2],missingMethodArguments[3]);
   		}
   	}
   	throw(type="jarsoap.service.notfound",message="the service #missingMethodName# was not found. Available services:#structKeyList(services)#");
   }

}