component {

	cl = new lib.LibraryLoader(getDirectoryFromPath(getMetaData(this).path) & "lib/jars/").init();
//    createObject("java","java.lang.Thread").currentThread().setContextClassLoader(cl.getLoader().getURLClassLoader())
	java = {
		Thread : cl.create("java.lang.Thread")
		, QName : cl.create("javax.xml.namespace.QName")
		, JaxWsDynamicClientFactory : cl.create("org.apache.cxf.jaxws.endpoint.dynamic.JaxWsDynamicClientFactory")
		, WSDLToJava : cl.create("org.apache.cxf.tools.wsdlto.WSDLToJava")
		, ToolContext : cl.create("org.apache.cxf.tools.common.ToolContext")
		, Client : cl.create("org.apache.cxf.endpoint.Client")
		, URL : cl.create("java.net.URL")
		, File : cl.create("java.io.File")
		, SpringBusFactory : cl.create("org.apache.cxf.bus.spring.SpringBusFactory")
		, BusFactory : cl.create("org.apache.cxf.BusFactory")
	}
	//org.apache.axis.wsdl.toJava.Emitter
	cTL = java.Thread.currentThread().getContextClassLoader();

	function init(wsdl,springContext="") {
		if(!isNull(wsdl))
		 	setWSDLURL(wsdl);
		springContextLocation = springContext;
		return this;
	}

	function setWSDLURL(required wsdl) {
		wsdlURL = wsdl;
	}

	function getClient() {
		if(springContextLocation !="") {
			var springFactory =java.SpringBusFactory.init();
			var bus = springFactory.createBus(java.File.init(springContextLocation));
			java.BusFactory.setDefaultBus(bus);
			var factory = java.JaxWsDynamicClientFactory.newInstance(bus);
		} else {
	       	var factory = java.JaxWsDynamicClientFactory.newInstance();
		}

	       	wsClient = factory.createClient(wsdlURL);
		if(isNull(wsClient)) {
		}
		return wsClient;
/*
  OrganizationService service = new OrganizationService(wsdlLocation);
  IOrganizationService port = service.getPort(IOrganizationService.class);
  Entity entity = new Entity();
  port.create(entity);
*/

	}



	function _getServices() {
		if(isNull(services)) {
	        var clientImpl = getClient();
	        var endpoint = clientImpl.getEndpoint();
	        var serviceInfo = endpoint.getService().getServiceInfos().get(0);
	        services = {};
	       	for(var operation in serviceInfo.getInterface().getOperations().toArray()) {
				var service = {servicename:operation.getName().getLocalPart(), operation:operation, arguments:{}};
	       		var inputMessageInfo = operation.getInput();
	       		var parts = inputMessageInfo.getMessageParts();
	       		for(var part in parts) {
	       			var type = !isNull(part.getTypeQName()) ? part.getTypeQName().getLocalPart() : part.getTypeClass().getCanonicalName();
	       			type = isNull(type) ? "" : type;
		        	service.arguments[part.getName().getLocalPart()]= type.toString();
	       		}
	       		services[service.servicename] = service;
	       	}
		}
       	return services;
	}

	function runOperation(required opName, required inputObject) {
		var service = services[opName];
		var obj = getClient().invoke(service.operation.getName(), inputObject);
		return pojo2struct(obj);
	}

	function pojo2struct(required pojo)  {
		if (isNull(pojo)) return {};
		if(isArray(pojo) && arrayLen(pojo) == 1) {
			pojo = pojo[1];
		}
		var struct = structNew("linked");
		var meths = pojo.getClass().getDeclaredMethods();
		for(var meth in meths) {
			var methodName = meth.getName();
			var returnType = meth.getReturnType().toString();
			if(methodName.startsWith("get") && returnType != "void") {
				struct[methodName.replaceAll("^get","")] = pojo[methodName]();
			} else if (methodName.startsWith("is") && returnType == "boolean") {
				struct[methodName.replaceAll("^is","")] = pojo[methodName]();
			}
		}
		struct["_pojo"] = pojo;
		return struct;
	}

	function _wsdl2java(args=['-d', getTempDirectory(),'-client','-verbose','-validate']) {
		arrayAppend(args,wsdlURL);
		var wsdl2java = java.WSDLToJava.init(args);
		var toolContext = java.ToolContext.init();
		request.debug(args);
		request.debug(wsdl2java.run(toolContext));
	}

	function _create(required className) {
		getClient();
		return createObject("java","java.lang.Thread").currentThread().getContextClassLoader().loadClass(classname).newInstance();
	}

    function onMissingMethod(missingMethodName,missingMethodArguments){
    	callMethod("_getServices",[]);
    	request.debug(arguments);
    	if(missingMethodName == "create"){
    		return callMethod("_create",missingMethodArguments);
    	}
    	else if(structKeyExists(services,missingMethodName)) {
    		return callMethod("runOperation",[missingMethodName,missingMethodArguments]);
    	} else {
	        return callMethod("_"&missingMethodName,missingMethodArguments);
    	}
    }


	/**
	 * Access point for this component.  Used for thread context loader wrapping.
	 **/
	function callMethod(methodName, required args) {
		var jThread = cl.create("java.lang.Thread");
		var cTL = jThread.currentThread().getContextClassLoader();
		jThread.currentThread().setContextClassLoader(cl.GETLOADER().getURLClassLoader());
		try{
			var theMethod = this[methodName];
			return theMethod(argumentCollection=args);
		} catch (any e) {
			jThread.currentThread().setContextClassLoader(cTL);
			throw(e);
		}
		jThread.currentThread().setContextClassLoader(cTL);
	}

}