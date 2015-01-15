component {

	function init(required javaloader, wsjars= getTempdirectory() & "/wsjars", srcdir=getTempDirectory() & "/wsdlsrc")  {
		wsdlsrc = srcdir;
		cl = javaloader;
		callMethod("_initJava",cl);
		WSDLs = {};
		jardir = wsjars;
		debug = false;
		return this;
	}

	function _initJava(cl) {
		java = {
			Thread : cl.create("java.lang.Thread")
			, QName : cl.create("javax.xml.namespace.QName")
			, WSDLToJava : cl.create("org.apache.axis2.wsdl.WSDL2Java")
			, CodeGenerationEngine : cl.create("org.apache.axis2.wsdl.codegen.CodeGenerationEngine")
			, CodeGenConfiguration : cl.create("org.apache.axis2.wsdl.codegen.CodeGenConfiguration")
			, CommandLineOptionParser : cl.create("org.apache.axis2.util.CommandLineOptionParser")
			, HTTPConstants : cl.create("org.apache.axis2.transport.http.HTTPConstants")
			, URL : cl.create("java.net.URL")
			, File : cl.create("java.io.File")
			, System : cl.create("java.lang.System")
			, HashMap : cl.create("java.util.HashMap")
		}
	}

	function _addWSDL(required wsdl, endpoint="", package="", jar="", srcdir=wsdlsrc, addJavaSrcDir="", bindings="", boolean refresh=false)  {
		jar = jar == "" ? jardir & "/" & java.URL.init(wsdl).getHost() & ".jar" : jar;
		var wssrc = srcdir & "/" & listLast(jar,"\/").replace(".jar","");
		var wsdlInfo = {url:wsdl,endpoint:endpoint,package:package,jar:jar,srcdir:wssrc,addJavaSrcDir:addJavaSrcDir,bindings:bindings,wsdlToJavaResult:"",compileResult:"",compiled:false};
		WSDLs[wsdl] = wsdlInfo;
	}

	function compileSources(required srcdir, required bindir)  {
		var compiler = createObject("component","cfjarsoap.dependency.javatools.Compiler");
		var cp = arrayToList(directoryList(expandPath("/cfjarsoap/dependency/axis2"),true,"*.jar"), java.System.getProperty("path.separator"));
		var didcompile = compiler.compile(arguments.srcdir,arguments.bindir,cp,'-1.7 -nowarn');
		if(find("ERROR ",didcompile)) {
			throw(type="axis2.compile.error", message=didcompile);
		}
		return didcompile;
	}

	function jarWSDLs(refresh = false)  {
		var shouldReload = false;
		var bindir = getTempdirectory() & "/wsbin";
		if(directoryExists(bindir)) lazyDirectoryDelete(bindir,true);
		if(!directoryExists(jardir)) directoryCreate(jardir);
		for(var wsInfo in WSDLs) {
			wsInfo = WSDLs[wsInfo];
			if(refresh) {
				if(directoryExists(wsInfo.srcdir)) lazyDirectoryDelete(wsInfo.srcdir,true);
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
				var wsdlArgs = ['-o',wsInfo.srcdir,'-d', 'xmlbeans', '-s','--noBuildXML','-u'];
				if(wsInfo.package != "") {
					arrayAppend(wsdlArgs,"-p");
					arrayAppend(wsdlArgs,wsInfo.package);
				}
			  	wsdlInfo.wsdlToJavaResult = _wsdlTojava(wsdl=wsInfo.url,args=wsdlArgs);
			  	fixMSNamespace(wsInfo.srcdir,wsInfo.url);
			  	if(wsInfo.endpoint != ""){
				  	setEndpoint(wsInfo.srcdir,wsInfo.endpoint);
			  	}
			  	wsInfo.compileResult = compileSources(wsInfo.srcdir, bindir & "/" & listLast(wsInfo.jar,"\/").replace(".jar",""));
			  	if(fileExists(wsInfo.jar)) fileDelete(wsInfo.jar);
			  	wsInfo.compiled = true;
			  	shouldReload = true;
			}
		}
		for(var wsInfo in WSDLs) {
			wsInfo = WSDLs[wsInfo];
			if (!fileExists(wsInfo.jar) || refresh) {
		  		createJar(bindir & "/" & listLast(wsInfo.jar,"\/").replace(".jar",""),wsInfo.jar);
			  	shouldReload = true;
			}
		}
		return shouldReload;
	}

	function fixMSNamespace(required srcdir, wsdlURL)  {
		// some MS .net webservices have this thing...
		var files = directoryList(srcdir,true,"*.java");
		var host = reReplace(wsdlURL,"(?m)([a-z]{4}\:\/{2}[^\/]+).*","\1","all");
		for (var file in files) {
			if(file.endsWith(".java")) {
				var in = fileRead(file);
				var out = replace(in,"wsx:MetadataSection","MetadataSection","all");
				out = replace(out,"wsx:MetadataReference","MetadataReference","all");
				out = reReplace(out,"(?m)[a-z]{4}\:\/{2}(localhost|127.0.0.1)\:?[0-9]{0,4}",host,"all");
				fileWrite(file,out);
			}
		}
	}

	function setEndpoint(required srcdir, endpoint)  {
		// some MS .net webservices have this thing...
		var files = directoryList(srcdir,true,"*.java");
		for (var file in files) {
			if(file.endsWith(".java")) {
				var in = fileRead(file);
				var out = rereplace(in,'(?m)this\("[a-z]{4,5}\:\/{2}[^"]+','this("'& endpoint,"all");
				out = rereplace(out,'(?m)configurationContext,"[a-z]{4,5}\:\/{2}[^"]+','configurationContext,"'& endpoint,"all");
				fileWrite(file,out);
			}
		}
	}

	function createJar(required bindir ,required jarfile)  {
		var jarer = new cfjarsoap.dependency.javatools.JarUtil();
		var srcPath = arguments.bindir;
		var destFile = arguments.jarfile;
		jarer.createJarFile(srcPath,destFile,"");
	}

	function getClassLoader(force=false)  {
		if(force || isNull(classloader)) {
			if(debug){
				java.System.setProperty("org.apache.commons.logging.Log","org.apache.commons.logging.impl.SimpleLog");
				java.System.setProperty("org.apache.commons.logging.simplelog.showdatetime",true);
				java.System.setProperty("org.apache.commons.logging.simplelog.log.httpclient.wire","debug");
				java.System.setProperty("org.apache.commons.logging.simplelog.log.org.apache.commons.httpclient","debug");
			}
			if(isNull(needsReload)) {
				needsReload = callMethod("jarWSDLs",force);
			}
			if(force || needsReload){
			java.System.out.println("Realoaded CLASSLOADER ^^^^^^^^^^^^^^^^^^^^^^^^^")
				lock name="switchnloader" timeout="20" {
					if(force || needsReload){
						var depsdir = expandPath("/cfjarsoap/dependency/axis2");
						var newCL = cl.init(id="cfjarsoap-classloader#createUUID()#", pathlist="#depsdir#,#jardir#", force=true);
						cl = javacast("null","");
						//TODO: cleanup somehow
						cl = newCL;
					}
				}
			}
			classloader = cl;
		}
		return cl;
	}

	function _getServices() {
		if(isNull(services)) {
			services = {};
			for(var wsdlInfo in WSDLs) {
				wsdlInfo = WSDLs[wsdlInfo];
				var jar = wsdlInfo.jar;
				var zippath = "zip://"&jar&"!/";
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
								var service = {
									servicename:meth.getName(), intermediary:"",
									arguments:[], wsdlInfo: wsdlInfo
									};
								var sParams = meth.getParameterTypes();
								if(arrayLen(sParams)==1) {
							        for(var param in sParams) {
								        for(var arg in getClassLoader().create(param.getName()).getClass().getMethods()) {
								        	if(arg.getName().startsWith("set"))
								        	arrayAppend(service.arguments,{name:arg.getName().replace("set",""),type:arg.getParameterTypes()[1].getName()});
							        	}
								        service.intermediary = param.getName();
							        }
								} else {
							        for(var param in sParams) {
							        	arrayAppend(service.arguments,{name:param.getName(),type:param.getName()});
							        }
								}
						        service.locator = class;
						        service.returntype = meth.getReturnType().getName();
						        services[service.servicename] = service;
							}
						}
					}
				}
			}
		}
		return services;
	}

	function runOperation(required opName, args) {
		var service = services[opName];
		var locator = cl.create(service.locator).init();
		var obj = {};
		locator._getServiceClient().getOptions().setProperty(java.HTTPConstants.CHUNKED, "false");
		locator._getServiceClient().getOptions().setProperty("dotNetSoapEncFix", "true");
		if(service.intermediary != "") {
			var im = cl.create(service.intermediary);
			var i = 0;
			for (var arg in service.arguments) {
				i++;
				if(arrayLen(args) LT arrayLen(service.arguments)){
					throw(message="incorrect number of arguments (#arrayLen(args)#) should be #serializeJSON(service.arguments)#");
				}
				if(structKeyExists(args,arg.name)){
					im["set"&arg.name](args[arg.name]);
				} else if(isArray(args)) {
					im["set"&arg.name](args[i]);
				}
			}
			request.debug(service.servicename);
			request.debug(locator);
			request.debug(service.intermediary);
			request.debug(im);
			var result = locator[service.servicename](im);
//			obj = result["get" & service.servicename & "Result"]();
			obj = result;
		} else {
			if(arrayLen(args) == 5) {
				obj = locator[service.servicename](args[1],args[2],args[3],args[4],args[5]);
			} else if(arrayLen(args) == 4) {
				obj = locator[service.servicename](args[1],args[2],args[3],args[4]);
			} else if(arrayLen(args) == 3) {
				obj = locator[service.servicename](args[1],args[2],args[3]);
			} else if(arrayLen(args) == 2) {
				obj = locator[service.servicename](args[1],args[2]);
			} else if(arrayLen(args) == 1) {
				obj = locator[service.servicename](args[1]);
			} else {
				obj = locator[service.servicename]();
			}
		}
		return pojo2struct(obj);
	}

	function pojo2struct(required pojo, withPOJO = false)  {
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
				var key = methodName.replaceAll("^get","");
			} else if (methodName.startsWith("is") && returnType == "boolean") {
				var key = methodName.replaceAll("^is","");
			} else {
				continue;
			}
			var result = {};
			try {
				result = pojo[methodName]();
			} catch (any e) {
				result = "ERROR - #pojo.getClass().getName()# #methodName#() : #e.message#";
			}
			result = isNull(result) ? "null" : result;
			if(!isSimpleValue(result)) {
				if(isArray(result)) {
					var resArray = [];
					for(var item in result) {
						arrayAppend(resArray,pojo2struct(item,false));
					}
					result = resArray;
				} else {
					result = pojo2struct(result,false);
				}
			}
			struct[key] = result;
		}
		if(withPOJO)
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
			request.debug(cl.getClassloaderTree());
		try {
		var wsdl2java = java.CodeGenerationEngine.init(conf).generate();
		} catch (any e) {
			var cmd = 'java -cp "src/cfjarsoap/dependency/axis2/*" org.apache.axis2.wsdl.WSDL2Java';
			throw(type="wsdlToJava.error",message="Tried #cmd# #arrayToList(args,' ')# and got: #e.message#: #wsdl# #args.toString()#", detail=e.detail);
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

    function lazyDirectoryDelete(directory,recurse=true){
    	if(!directoryExists(directory))
    		return;
    	try {
    		directoryDelete(directory,recurse);
    	} catch (any e) {
    		directoryRename(directory,getTempDirectory() & "/#createUUID()#");
    	}
    }


	/**
	 * Access point for this component.  Used for thread context loader wrapping.
	 **/
	function callMethod(methodName, required args) {
		var jThread = cl.create("java.lang.Thread");
		var cTL = jThread.currentThread().getContextClassLoader();
		jThread.currentThread().setContextClassLoader(cl.getLoader().getURLClassLoader());
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