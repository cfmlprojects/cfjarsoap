component {

	function init(wsjars= getTempdirectory() & "/wsjars", srcdir=getTempDirectory() & "/wsdlsrc")  {
		wsdlsrc = srcdir;
		libdir = getDirectoryFromPath(getMetaData(this).path) & "lib/jars/";
		cl = new lib.LibraryLoader("#libdir#,#wsjars#/").init();
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
		WSDLs = {};
		jardir = wsjars;
		return this;
	}

	function _addWSDL(required wsdl, package="", jar="", srcdir=wsdlsrc, addJavaSrcDir="", bindings="", boolean refresh=false)  {
		jar = jar == "" ? jardir & "/" & java.URL.init(wsdl).getHost() & ".jar" : jar;
		var wssrc = srcdir & "/" & listLast(jar,"\/").replace(".jar","");
		var wsdlInfo = {url:wsdl,package:package,jar:jar,srcdir:wssrc,addJavaSrcDir:addJavaSrcDir,bindings:bindings,wsdlToJavaResult:"",compileResult:"",compiled:false};
		WSDLs[wsdl] = wsdlInfo;
	}

	function setSpringApplicationContext(required context)  {
		springContextLocation = context;
		var springFactory = java.SpringBusFactory.init();
		bus = springFactory.createBus(java.File.init(springContextLocation));
		bus.getProperties().put("soap.no.validate.parts", true);
		var pClass = cl.getLoader().getURLClassloader().loadClass("org.apache.cxf.ws.policy.PolicyInterceptorProviderRegistry");
		var pRegistry = bus.getExtension(pClass);
		pRegistry.register(cl.create("xrm.XRMAuthPolicyProvider").init());

		java.BusFactory.setDefaultBus(bus);

	}

	function compileSources(required srcdir, required bindir)  {
		var compiler = createObject("component","cfjarsoap.core.Compiler");
		var cp = arrayToList(directoryList(libdir,true,"*.jar"),":");
		var didcompile = compiler.compile(arguments.srcdir,arguments.bindir,cp);
		return didcompile;
	}

	function jarWSDLs(refresh = false)  {
		var bindir = getTempdirectory() & "/wsbin";
		if(directoryExists(bindir)) directoryDelete(bindir,true);
		if(!directoryExists(jardir)) directoryCreate(jardir);
		for(var wsInfo in WSDLs) {
			wsInfo = WSDLs[wsInfo];
			if(refresh) {
				if(directoryExists(wsInfo.srcdir)) directoryDelete(wsInfo.srcdir,true);
			}
		}
		for(var wsInfo in WSDLs) {
			wsInfo = WSDLs[wsInfo];
			if(!fileExists(wsInfo.jar) || refresh) {
				if(!directoryExists(wsInfo.srcdir)) {
				  	directoryCreate(wsInfo.srcdir);
				}
				if(wsInfo.addJavaSrcDir != ""){
					directoryCopy(wsInfo.addJavaSrcDir, wsInfo.srcdir,true);
				}
				var wsdlArgs = ['-d',wsInfo.srcdir,'-client','-verbose','-validate'];
				if(wsInfo.bindings != "") {
					arrayAppend(wsdlArgs,"-b");
					arrayAppend(wsdlArgs,wsInfo.bindings);
				}
				if(wsInfo.package != "") {
					arrayAppend(wsdlArgs,"-p");
					arrayAppend(wsdlArgs,wsInfo.package);
				}
			  	wsdlInfo.wsdlToJavaResult = _wsdlTojava(wsdl=wsInfo.url,args=wsdlArgs);
			  	wsInfo.compileResult = compileSources(wsInfo.srcdir, bindir & "/" & listLast(wsInfo.jar,"\/").replace(".jar",""));
			  	if(fileExists(wsInfo.jar)) fileDelete(wsInfo.jar);
			  	wsInfo.compiled = true;
			}
		}
		for(var wsInfo in WSDLs) {
			wsInfo = WSDLs[wsInfo];
		  	var jarFile = wsInfo.jar;
			if (!fileExists(jarFile)) {
		  		createJar(bindir & "/" & listLast(wsInfo.jar,"\/").replace(".jar",""),jarFile);
			}
		}
		return true;
	}

	function createJar(required bindir ,required jarfile)  {
		var jarer = createObject("component","cfjarsoap.core.JarUtil");
		var srcPath = arguments.bindir;
		var destFile = arguments.jarfile;
		jarer.createJarFile(srcPath,destFile,"");
	}

	function getClassLoader(refresh=false)  {
		if(isNull(checkedJars)) {
			checkedJars = jarWSDLs(refresh=refresh);
		}
		if(refresh){
			cl = new lib.LibraryLoader("#libdir#,#jardir#/",refresh).init();
		}
		return cl;
	}

	function _jar(required wsdl,required jarFile, outputdir=wsdlsrc, refresh=false)  {
		var result = "jar exists";
		outputdir = outputdir  & "/";
		if(!fileExists(jarFile) || refresh) {
			directoryExists(outputdir) ? directoryDelete(outputdir,true):"";
			directoryCreate(outputdir);
		  	var result = _wsdlTojava(wsdl=wsdl,args=['-d',outputdir & "src",'-client','-verbose','-validate']);
		  	var result &= compileSources(outputdir & "src/", outputdir & "bin/");
		  	if (find("ERROR",result)) {
			  throw(type="wsdl2jar.compile.error",message="cannot compile thingie:#result#");
			}
			if (fileExists(jarFile)) {
			  	fileDelete(jarFile);
			}
		  	createJar(outputdir & "bin/",jarFile);
		}
	  	return result;
	}


	function getClient() {
		if(springContextLocation !="") {
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

	function _wsdlTojava(required wsdl, args=['-d', getTempDirectory(),'-client','-verbose','-validate']) {
		arrayAppend(args,wsdl);
		var toolContext = java.ToolContext.init();
		var wsdl2java = java.WSDLToJava.init(args);
		try {
			wsdl2java.run(toolContext);
		} catch (any e) {
			throw(type="wsdlToJava.error",message="Could not gen: #wsdl# #args.toString()#");
		}
		return "wsdlToJava: " & args.toString();
	}

	function _create(required className) {
		getClient();
		return createObject("java","java.lang.Thread").currentThread().getContextClassLoader().loadClass(classname).newInstance();
	}

    function onMissingMethod(missingMethodName,missingMethodArguments){
        return callMethod("_"&missingMethodName,missingMethodArguments);
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