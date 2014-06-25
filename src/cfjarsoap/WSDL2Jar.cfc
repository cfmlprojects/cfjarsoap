component {

	wsdlsrc = getTempDirectory() & "/wsdlsrc";

	function init()  {
		directoryExists(wsdlsrc) ? directoryDelete(wsdlsrc,true):"";
		return this;
	}

	function createJavaSources(required wsdl, outputdir=wsdlsrc, refresh=false)  {
		var wsdl2java = "";
		var inArgs = "";
		var secMan = "";
		var tmpsrc = arguments.outputdir & "/_tmpsrc";
		if(refresh) {
			directoryExists(outputdir) ? directoryDelete(outputdir,true):"";
		}
		for(var awsdl in listToArray(wsdl,",")) {
			directoryExists(tmpsrc)?directoryDelete(tmpsrc,true):"";
			inArgs = arrayNew(1);
			secMan = createObject("java","java.lang.SecurityManager");
			// cmdln opts : https://wso2.org/project/wsas/java/1.1/docs/tools/cmd/code_gen.html
			// http://ws.apache.org/axis/java/user-guide.html#WSDL2JavaBuildingStubsSkeletonsAndDataTypesFromWSDL
	//		arrayAppend(inArgs,"-p");
	//		arrayAppend(inArgs,"org.funk.asds");
			arrayAppend(inArgs,"--NStoPkg");
			arrayAppend(inArgs,"http://tempuri.org/=ws");
			arrayAppend(inArgs,"-o");
			arrayAppend(inArgs,tmpsrc);
			arrayAppend(inArgs,"-v"); // verbose
//			arrayAppend(inArgs,"-a"); // all
			arrayAppend(inArgs,"-H"); // helpers
//			arrayAppend(inArgs,"-w"); // wrap arrays
			arrayAppend(inArgs,awsdl);
			var result = runMainNoExit("org.apache.axis.wsdl.WSDL2Java",inArgs);
			copyDir(tmpsrc,outputdir);
		}
		directoryExists(tmpsrc)?directoryDelete(tmpsrc,true):"";
		return result;
	}

	function compileSources(required srcdir, required bindir)  {
		var compiler = createObject("component","core.Compiler");
		var didcompile = compiler.compile(arguments.srcdir,expandPath("/WEB-INF/lib/"),arguments.bindir);
		return didcompile;
	}

	function createJar(required bindir ,required jarfile)  {
		var jarer = createObject("component","core.JarUtils");
		var srcPath = arguments.bindir;
		var destFile = arguments.jarfile;
		jarer.createJarFile(srcPath,destFile,"");
	}

	function getClassLoader(required wsjars)  {
		var paths = directoryList(path=wsjars,filter="*.jar");
		var loader = createObject("component", "core.javaloader.JavaLoader").init(paths,true,false);
		return loader;
	}

	function jar(required wsdl,required jarFile, outputdir=wsdlsrc, refresh=false)  {
		var result = "jar exists";
		outputdir = outputdir  & "/";
		if(!fileExists(jarFile) || refresh) {
			directoryExists(outputdir) ? directoryDelete(outputdir,true):"";
			directoryCreate(outputdir);
		  	var result = createJavaSources(arguments.wsdl, outputdir & "src");
		  	if(!find("Generating",result)) {
		  		throw(type="WSDL2Jar.error", message="could not create sources:" & result);
		  	}
		  	var compileResult = compileSources(outputdir & "src/", outputdir & "bin/");
		  	if (NOT compileResult.success) {
			  throw(type="wsdl2jar.compile.error",message="cannot compile thingie:#compileResult.errors#");
			}
			if (fileExists(jarFile)) {
			  	fileDelete(jarFile);
			}
		  	createJar(outputdir & "bin/",jarFile);
		}
	  	return result;
	}

	function jarAndLoad(required wsdl ,required jarFile ,outputdir="" ,refresh=false)  {
		jar(wsdl,jarFile);
		return getJarLoader(jarFile);
	}

	function runMainNoExit(class,funkargs){
		var sys = createObject("java","java.lang.System");
		var runtim = createObject("java","java.lang.Runtime");
		var secMan = sys.getSecurityManager();
		var CtMethod = createObject("java","javassist.CtMethod");
		var pool = createObject("java","javassist.ClassPool").getDefault();
		var PrintStream = createObject("java","java.io.PrintStream");
		var outStream = createObject("java","java.io.ByteArrayOutputStream").init();
		var errStream = createObject("java","java.io.ByteArrayOutputStream").init();
		var outPrint = PrintStream.init(outStream);
		var errPrint = PrintStream.init(errStream);
		var origOut = sys.out;
		var origErr = sys.err;
		sys.setOut(outPrint);
		sys.setErr(errPrint);
		try {
			NoExitManager = createObject("java","den.NoExitManager");
		} catch (any e) {
			var ch = pool.makeClass("den.NoExitManager");
			ch.setSuperclass(pool.get("java.lang.SecurityManager"));
			var m = CtMethod.make( 'public void checkExit(int status){super.checkExit(status); throw new java.lang.SecurityException("exit:"+status);}', ch);
			ch.addMethod(m);
			m = CtMethod.make( 'public void checkPermission(java.security.Permission perm) {}', ch);
			ch.addMethod(m);
			m = CtMethod.make( 'public void checkPermission(java.security.Permission perm, Object context){}', ch);
			ch.addMethod(m);
			h = ch.toClass();
			NoExitManager = h.newInstance();
		}

		sys.setSecurityManager( NoExitManager );
		try{
			createObject("java",class).main(funkargs);
		} catch (any e) {
			if(!isNull(secMan)) {
				sys.setSecurityManager( secMan );
			} else {
				sys.setSecurityManager( javacast("null","") );
			}
			if(e.type == "java.lang.SecurityException") {
				errStream.reset();
			}
		}
		sys.setOut(origOut);
		sys.setErr(origErr);
		var retOut = outStream.toString();
		var retErr = errStream.toString();
		if(find("java.lang.SecurityException",retErr)) {
			// trim off stacktrace from noExitManager-- better would be just to cut out the exit bit
			retErr = rereplace(retErr,".*java.lang.SecurityException(.*)","\1");
		}
		// sys.err is where some non-error shit goes.  Awesome.
		if(find("Parsing XML file",retErr)) {
			retOut &= retErr;
			retErr = "";
		}
		if(len(trim(retErr)) != 0) {
			throw(type="wsdl2jar.error",message= retOut & retErr & " (" & serializeJson(funkargs) & ")");
		}
		return retOut;

	}


	private function copyDir(required string source ,required string destination ,required nameconflict ="overwrite ")  {
	    var contents = "";
	    var dirDelim = createObject("java", "java.lang.System").getProperty("file.separator");
	    if (not(directoryExists(arguments.destination))) {
	        directoryCreate(arguments.destination);
	    }
	    directory action="list" directory="#arguments.source#" name="contents";
	    for(var i=1; i lte contents.recordcount; i=i+1) {
	    	var name = contents.name[i];
	    	var type = contents.type[i];
	        if (type eq "file") {
	         	file action="copy" source="#arguments.source#/#name#" destination="#arguments.destination#/#name#" nameconflict="#arguments.nameConflict#";
        	}
	        else if (type eq "dir") {
	            copyDir(arguments.source & dirDelim & name, arguments.destination & dirDelim & name);
	        }
	    }
	}

	function deserializeObject(xmlInput, qName, javaType){
		try {
			// add the SOAP envelope since we we aren't expecting a SOAP object
			var temp = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body>' & xmlInput & '</soapenv:Body></soapenv:Envelope>';
			var aserver = createObject("java","org.apache.axis.server.AxisServer").init();
			var AxisEngine = createObject("java","org.apache.axis.server.AxisEngine").init();
			aserver.setOption(AxisEngine.PROP_DOMULTIREFS, true);
			var msgContext = createObject("java","org.apache.axis.MessageContext").init(aserver);
			var reader = createObject("java","java.io.StringReader").init(temp);
			var dser = createObject("java","DeserializationContext").init(createObject("java","org.xml.sax.InputSource").init(reader),msgContext,createObject("java","org.apache.axis.Message").REQUEST);
			dser.parse();
			var env = dser.getEnvelope();
			var rpcElem = env.getFirstBody();
			var struct = rpcElem.getRealElement();
			var result = struct.getValueAsType(qName,javaType);
			return result;
		} catch (Exception e) {
			throw new Exception("Could not deserialize the XML object:" + e.getMessage());
		}
	}

}