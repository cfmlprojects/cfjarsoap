<cfcomponent name="compiler">


<cffunction name="dumpvar">
  <cfargument name="var">
  <cfargument name="abort" default="true">
  <cftry>
<!---
 		<cfset class = createObject("java","java.lang.Class") />
		<cfset meths = var.getDeclaredMethods() />
		<cfset ms = structNew() />
		<cfloop from="1" to="#arrayLen(meths)#" index="m">
		  <cfset ms[meths[m].toString()] = structNew() />
		  <cfset ms[meths[m].toString()]["public"] = meths[m].public>
		  <cfset mps = meths[m].getParameterTypes()>
			<cfloop from="1" to="#arrayLen(mps)#" index="p">
			  <cfset ms[meths[m].toString()][mps[p].getName()] = mps[p].getName() />
			</cfloop>
		</cfloop>
	  <cfdump var="#ms#" />
--->
	  <cfdump var="#var#" />
	<cfcatch>
	  <cfset writeoutput(cfcatch.Message & " " & cfcatch.Detail & " " & cfcatch.TagContext[1].line & " " & cfcatch.stacktrace) />
	</cfcatch>
	</cftry>
	<cfif arguments.abort>
	  <cfabort />
	</cfif>
</cffunction>

<cffunction name="loadDirectory" hint="Loads the JAR file paths into the array" access="public" returntype="array" output="false">
	<cfargument name="path" hint="The path to oad" type="string" required="Yes">
	<cfargument name="library" hint="The array of classpaths" type="array" required="Yes">
	<cfscript>
		var qJars = 0;
	</cfscript>
	<cfif right(arguments.path,1) neq "/">
		<cfset arguments.path = arguments.path & "/">
	</cfif>
	<cfdirectory action="list" directory="#arguments.path#" filter="*.jar" name="qJars">
	<cfloop query="qJars">
		<cfscript>
			ArrayAppend(arguments.library, arguments.path & name);
		</cfscript>
	</cfloop>
	<cfscript>
		ArrayAppend(arguments.library, arguments.path);
		return arguments.library;
	</cfscript>
</cffunction>

	<cffunction name="compile" access="public" output="false" hint="compiles java files">
		<cfargument name="srcdir">
		<cfargument name="classpath" default="">
		<cfargument name="outFileDir" default="#arguments.srcdir#">
		<cfargument name="options" default="">
		<cfscript>
			var paths = loadDirectory(listFirst(arguments.classpath),listToArray(getDirectoryFromPath(getCurrentTemplatePath())&"jdt-compiler-3.1.1.jar"));
//			var wee = dumpvar(paths);
			var loader = createObject("component", "javaloader.JavaLoader").init(paths,true,false);
			var compiler = loader.create('org.eclipse.jdt.internal.compiler.batch.Main');
			var didCompile = structNew();
			// get the system class path
			var	system = CreateObject("java", "java.lang.System");
			var filesep = system.getProperty("file.separator");
			var	outStream = CreateObject("java","java.io.ByteArrayOutputStream").init();
			var	outS = createObject("java","java.io.ByteArrayOutputStream").init();
			var	errS = createObject("java","java.io.ByteArrayOutputStream").init();
			var	outWriter = createObject("java","java.io.PrintWriter").init(outS);
			var	errWriter = createObject("java","java.io.PrintWriter").init(errS);
			var jarsArray = arrayNew(1);
			arguments.outFileDir = getDirectoryFromPath(arguments.outFileDir);
			// set the class deliminator for windows/linux
			switch(filesep){
				case "/":
					classdelim = ":";
				break;
				case "\":
					classdelim = ";";
				break;
			}
			syslibpath = replacenocase(system.getProperty("java.library.path"),'../lib','lib');
			bootpath = replacenocase(system.getProperty("sun.boot.class.path"),'../lib','lib');
			catalina = replacenocase(system.getProperty("catalina.ext.dirs"),'../lib','lib');
			jbosslibs = replacenocase(system.getProperty("jboss.server.lib.url"),'../lib','lib');
			if (arguments.classpath eq "") {
				webinflibs = "";
				//classpath = """" & system.getProperty("java.class.path") & classdelim & system.getProperty("java.library.path") & classdelim & arrayToList(variables._loader.queryJars(),classdelim) &"""" ;
				classpath = """" & system.getProperty("java.class.path") & classdelim & syslibpath & classdelim & bootpath
				& classdelim & catalina &
				classdelim & jbosslibs &
				classdelim & webinflibs &
				 """" ;
				request.debug(system.getProperties());
				request.debug(server);
			}
			else {
				//classpath = """" & arguments.classpath & classdelim &  arrayToList(variables._loader.queryJars(),classdelim)  &"""" ;
				for(x = 1; x lte listLen(arguments.classpath); x = x+1) {
				  jarsArray = loadDirectory(listGetAt(arguments.classpath,x),jarsArray);
				}
			  //jarsArray = loadDirectory(syslibpath,jarsArray);
			  //jarsArray = loadDirectory(bootpath,jarsArray);
			  //jarsArray = loadDirectory(catalina,jarsArray);
			  //jarsArray = loadDirectory(jbosslibs,jarsArray);
				classpath = arrayToList(jarsArray,classdelim);
			}
			didCompile["outFileDir"] = arguments.outFileDir;
			didCompile["command"] = '#arguments.options# -nowarn -classpath "#classpath#" "#arguments.srcdir#" -d "#arguments.outFileDir#"';
			//didCompile["success"] = compiler.compile("-nowarn -sourcepath #sourcepath# -classpath #classpath# #arguments.javaFile# -d #arguments.outFileDir#",outWriter,errWriter);
			didCompile["success"] = compiler.compile(didCompile["command"],outWriter,errWriter);
			didCompile["errors"] = replace(errS.toString(),chr(13)&chr(10),"<br>","all");
			didCompile["out"] = outS.toString();
			outStream.close();
			outS.close();
			errS.close();
			outWriter.close();
			errWriter.close();
			return didCompile;
		</cfscript>
	</cffunction>

</cfcomponent>