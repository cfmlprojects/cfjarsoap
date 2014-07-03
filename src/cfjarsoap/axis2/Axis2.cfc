component {

	function init(required javaloader, wsjars= getTempdirectory() & "/wsjars", srcdir=getTempDirectory() & "/wsdlsrc")  {
		wsdlsrc = srcdir;
		cl = javaloader;
		java = {
			Thread : cl.create("java.lang.Thread")
			, QName : cl.create("javax.xml.namespace.QName")
			, WSDLToJava : cl.create("org.apache.axis2.wsdl.WSDL2Java")
			, CodeGenerationEngine : cl.create("org.apache.axis2.wsdl.codegen.CodeGenerationEngine")
			, CodeGenConfiguration : cl.create("org.apache.axis2.wsdl.codegen.CodeGenConfiguration")
			, CommandLineOptionParser : cl.create("org.apache.axis2.util.CommandLineOptionParser")
			, URL : cl.create("java.net.URL")
			, File : cl.create("java.io.File")
			, HashMap : cl.create("java.util.HashMap")
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

	function compileSources(required srcdir, required bindir)  {
		var compiler = createObject("component","cfjarsoap.dependency.javatools.Compiler");
		var cp = arrayToList(directoryList(expandPath("/cfjarsoap/dependency/axis2"),true,"*.jar"),":");
		var didcompile = compiler.compile(arguments.srcdir,arguments.bindir,cp);
		if(find("ERROR ",didcompile)) {
			throw(type="axis2.compile.error", message=didcompile);
		}
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
				var wsdlArgs = ['-o',wsInfo.srcdir,'-d', 'adb', '-s','-u','-uw'];
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
		var jarer = new cfjarsoap.dependency.javatools.JarUtil();
		var srcPath = arguments.bindir;
		var destFile = arguments.jarfile;
		jarer.createJarFile(srcPath,destFile,"");
	}

	function getClassLoader(refresh=false)  {
		if(isNull(checkedJars)) {
			checkedJars = jarWSDLs(refresh=refresh);
		}
		if(refresh){
			cl = cl.init(expandPath("/cfjarsoap/dependencies/axis2") & ",#jardir#/",true,refresh);
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
		var jars = directoryList(jardir);
		if(isNull(services)) {
			services = {};
			for(var jar in jars) {
				var zippath = "zip://"&jardir&"!/";
				var classes = directoryList(zippath,true);
				for(var class in classes) {
					if(class.endsWith("Stub.class")) {
						class = rereplace(class,".*![\/]+","");
						class = rereplace(class,"\.class$","");
						class = replace(class,"/",".","all");
						var stub = getClassLoader().create(class).init();
						var meths = stub.getClass().getMethods();
						for(var meth in meths) {
							if( arrayLen(meth.getExceptionTypes()) > 0
							&& meth.getExceptionTypes()[1].toString() == "class java.rmi.RemoteException") {
								var service = {servicename:meth.getName(), arguments:{}};
						        for(var param in meth.getParameterTypes()) {
						        	service.arguments[param.getName()]= param.toString();
						        }
						        service.locator = class;
						        service.returntype = meth.getReturnType().toString();
						        services[service.servicename] = service;
							}
						}
					}
				}
			}
		}
		return services;
	}

	function runOperation(required opName, required inputObject) {
		var service = services[opName];
		var locator = cl.create(service.locator);
		var obj = locator[service.servicename](inputObject);
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
			if(methodName.startsWith("get") && returnType != "void"
				&& arrayLen(meth.getParameterTypes()) == 0) {
				struct[methodName.replaceAll("^get","")] = pojo[methodName]();
			} else if (methodName.startsWith("is") && returnType == "boolean") {
				struct[methodName.replaceAll("^is","")] = pojo[methodName]();
			}
		}
		struct["_pojo"] = pojo;
		return struct;
	}

	function _wsdlTojava(required wsdl, args=['-o', getTempDirectory()]) {
		arrayAppend(args,"-uri");
		arrayAppend(args,wsdl);
		var map = java.HashMap.init();
		var conf = java.CommandLineOptionParser.init(args)
		//var conf = java.CodeGenConfiguration.init(map);
		//conf.setOutputLocation(java.File.init(getTempDirectory()));
		//conf.setOutputLanguage("jax-ws");
        //conf.setParametersWrapped(false);
		try {
		var wsdl2java = java.CodeGenerationEngine.init(conf).generate();
		} catch (any e) {
			throw(type="wsdlToJava.error",message="#e.message#: #wsdl# #args.toString()#");
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