component {

	function init(wsjars= getTempdirectory() & "/wsjars")  {
		WSDLs = {};
		jardir = wsjars;
		wsdl2jar = new cfjarsoap.WSDL2Jar();
		return this;
	}

	function addWSDL(required wsdl, boolean refresh=false)  {
		WSDLs[wsdl] = wsdl2jar.jar(wsdl=wsdl, jarfile=jardir & "/#hash(wsdl)#.jar", refresh=refresh);
	}

	function getServices()  {
		var jars = directoryList(jardir);
		if(isNull(services)) {
			services = {};
			for(var jar in jars) {
				var zippath = "zip://"&jardir&"!/";
				var classes = directoryList(zippath,true);
				for(var class in classes) {
					if(class.endsWith("Locator.class")) {
						class = rereplace(class,".*![\/]+","");
						class = rereplace(class,"\.class$","");
						class = replace(class,"/",".","all");
						var locator = getClassLoader().create(class).init();
						var meths = locator.getClass().getDeclaredMethods();
						for(var meth in meths) {
							if(meth.getName().endsWith("Soap")) {
								var soaper = locator[meth.getname()]();
								var stub = getClassLoader().create(class.replace("Locator","SoapStub")).init();
								var fldClasses = stub.getClass().getDeclaredField("_operations");
						        fldClasses.setAccessible(true);
						        var operations = fldClasses.get(stub);
						        for(var operation in operations) {
									var service = {servicename:operation.getName(), arguments:{}};
							        for(var param in operation.getParameters()) {
							        	service.arguments[param.getName()]= param.getJavaType().toString();
							        }
							        service.returntype = operation.getReturnType().getLocalPart();
							        service.locator = class;
							        service.soap = meth.getName();
							        services[service.servicename] = service;
						        }
							}
						}
					}
				}
			}
		}
		return services;
	}

	function getClassLoader()  {
		if(isNull(classLoader)) {
			classLoader = wsdl2jar.getClassLoader(jardir);
		}
		return classLoader;
	}

	function pojo2struct(required pojo)  {
		if (isNull(pojo)) return {};
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

   function onMissingMethod( missingMethodName, missingMethodArguments ) {
   	var services = getServices();
   	if(listFindNoCase(structKeyList(services),missingMethodName)) {
   		var service = services[missingMethodName];
   		var locator = getClassLoader().create(service.locator);
   		var soap = locator[service.soap]();
   		var pojo = "";
   		switch(listLen(structKeyList(service.arguments))) {
   			case 1:
	   			return pojo2struct(soap[service.servicename](missingMethodArguments[1]));
   			case 2:
	   			return pojo2struct(soap[service.servicename](missingMethodArguments[1],missingMethodArguments[2]));
   			case 3:
	   			return pojo2struct(soap[service.servicename](missingMethodArguments[1],missingMethodArguments[2],missingMethodArguments[3]));
   		}
   	}
   	throw(type="jarsoap.service.notfound",message="the service #missingMethodName# was not found. Available services:#structKeyList(services)#");
   }

}