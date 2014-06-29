component {

  	cl = new lib.LibraryLoader();
	java = {
		  System        : cl.create( 'java.lang.System' )
		, PrintWriter	: cl.create( 'java.io.PrintWriter' )
		, StringWriter	: cl.create( 'java.io.StringWriter' )
		, BatchCompiler	: cl.create( 'org.eclipse.jdt.core.compiler.batch.BatchCompiler')
	};

	function Compile( String srcDirectory, String binDirectory, String classpath="", String compilerArgs="-1.7" ) {
		var command = '-cp "#classpath#" #compilerArgs# -d "#binDirectory#" "#srcDirectory#"';
		var out = java.StringWriter.init();
		var outWriter = java.PrintWriter.init( out, true );
		outWriter.println( "Compiler Command: " & command );
		java.BatchCompiler.compile( command, outWriter, outWriter, javaCast( 'null', '' ) );
		var result = out.getBuffer().toString().trim();
		return result;
	}

	function CompileAndJar( required String srcDirectory, required String jarFile, String binDirectory="", String classpath="", String compilerArgs="") {
		binDirectory = binDirectory == ""
			? getTempDirectory() & "/" & hash(srcDirectory) & "/bin"
			: binDirectory & "/bin" ;
		var result = compile( srcDirectory, binDirectory, compilerArgs );
		if(find("ERROR",result)) {
			throw(type="cfml.javatools.compile.error",message=result);
		}
		var jar = new JarUtil().createJarFile(binDirectory,jarFile);
		directoryExists(binDirectory) ? directoryDelete(binDirectory,true) : "";
		return result;
	}

}