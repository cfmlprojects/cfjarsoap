# cfjarsoap

This is a package for generating webservice clients.

It aims to support axis, axis2, and CXF.

## Installation
Copy ./cfjarsoap to your webroot, copy tests/test.cfc there too, then call test.cfm.

## Usage
generally:

wsdl = "http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl";
var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
cfsoap.addWSDL(wsdl=wsdl);
var c = cfsoap.getClassLoader(true);
dump(cfsoap.getServices());
cb = c.create("com.cdyne.ws.weatherws.WeatherStub");
dump(cb);
dump(cb.getCityWeatherByZIP("87104"));
dump(cfsoap.pojo2struct(cb.getCityWeatherByZIP("87104")));
dump(cfsoap.getCityWeatherByZIP(87104));

If you've generated the jars once, do cfsoap.getClassLoader(false) to prevent memory leaks.
Setting it to true forces the classes to be regenerated and a new classloader.  To be utterly
sure you're working with the latest WSDL definition, delete the generated jars and restart 
the server.

This uses cfdependency to download the necessary libraries at runtime.  Eventually there 
will be provisioned packages available for download as well.  To force the dependencies to be
downloaded fresh, delete the "repo" dir (theoretically in ./tests) and sub-directories in
./cfjarsoap/dependency/, leaving only Manager.cfc in there.

## Building/Development

Theoretically, downlaod the zipball, and run:
./cfjarsoap build
then
./cfjarsoap runwar.start.fg
then browse to:
http://127.0.0.1:8088/tests/test.cfm

To clean all downloaded dependencies:
./cfjarsoap clean 