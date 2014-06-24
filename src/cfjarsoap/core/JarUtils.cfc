<!--- Document Information -----------------------------------------------------

Title:      JarUtils.cfc

Author:     Denny Valliant
Email:      valliantster@gmail.com

Website:    http://coldshen.com

Purpose:    Jars up directories

Usage:      createJarFile(sources,destJarFile,jarEntryPrefix)

Modification Log:

Name			Date			Description
================================================================================
Denny Valliant		03/07/2008		Created

------------------------------------------------------------------------------->

<cfcomponent name="JarUtils" hint="Component for createing jar files">

<cfscript>
	instance = StructNew();
</cfscript>

<cffunction name="dumpvar">
  <cfargument name="var">
  <cfargument name="abort" default="true">
  <cftry>
	  <cfdump var="#var#">
	<cfcatch>
	  <cfset writeoutput(cfcatch.Message & " " & cfcatch.Detail & " " & cfcatch.TagContext[1].line & " " & cfcatch.stacktrace) />
	</cfcatch>
	</cftry>
	<cfif arguments.abort>
	  <cfabort />
	</cfif>
</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="JarUtils" output="false">
	<cfscript>
		return this;
	</cfscript>
</cffunction>

<cffunction name="createJarFile" access="public">
	<cfargument name="srcPath" />
	<cfargument name="destFile" default="#arguments.srcPath#/wee.jar" />
	<cfargument name="jarPrefix" default="" />
	<cfscript>
		var src = createObject("java", "java.io.File").init(arguments.srcPath);
		var prefix = arguments.jarPrefix;
//		var out = CreateObject("java","java.io.ByteArrayOutputStream").init();
		var destF = CreateObject("java","java.io.File").Init(arguments.destFile);
//		var wee = dumpvar(destFile & destF.exists());
	  	var out = CreateObject("java","java.io.FileOutputStream").Init(destF);
	    var jout = createObject("java","java.util.jar.JarOutputStream").init(out);
	    for(var dir in directorylist(srcPath)) {
	    	var fdir = createObject("java", "java.io.File").init(dir);
			jar(jout,fdir, prefix);
	    }
		jout.close();
		out.close();
	</cfscript>
<!---
	<cffile action="write" file="#arguments.destFile#" output="#out.toString()#" />
--->
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="jar" access="private" output="false" hint="recursive adding action">
	<cfargument name="jaroutstream" />
	<cfargument name="srcPath" />
	<cfargument name="inbuffer" default="" />
	<cfargument name="jarprefix" default="" />
	<cfscript>
		var prefix = arguments.jarPrefix;
    var jout = arguments.jaroutstream;
		var byteClass = createObject("java", "java.lang.Byte");
		var buffer = createObject("java","java.lang.reflect.Array").newInstance(byteClass["TYPE"],1024);
		var src = arguments.srcPath;
		var entry = "";
		var len = "";
		var files = "";
		var i = 0;
		var infile = "";
        if (src.isDirectory())
        {
           // create / init the zip entry
           prefix = prefix & src.getName() & "/";
           entry = createObject("java","java.util.zip.ZipEntry").init(prefix);
           entry.setTime(src.lastModified());
           entry.setMethod(jout.STORED);
           entry.setSize(0);
           entry.setCrc(0);
           jout.putNextEntry(entry);
           jout.closeEntry();

           // process the sub-directories
           files = src.listFiles();
           for (i = 1; i lte arrayLen(files); i = i + 1)
           {
              jar(arguments.jaroutstream,files[i], buffer, prefix);
           }
        }
        else if (src.isFile())
        {
           prefix = prefix & src.getName();
           entry = createObject("java","java.util.zip.ZipEntry").init(prefix);
           entry.setTime(src.lastModified());
           jout.putNextEntry(entry);

           infile = CreateObject("java","java.io.FileInputStream").init(src);

           len = infile.read(buffer, 0, len(buffer));
           while (len neq -1) {
             jout.write(buffer, 0, len);
             len = infile.read(buffer, 0, len(buffer));
           }
           infile.close();
           jout.closeEntry();
        }
	</cfscript>
</cffunction>


</cfcomponent>