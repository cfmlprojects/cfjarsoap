# cfjarsoap

This is a package for generating webservice clients.

It aims to support axis, axis2, and CXF.

## Installation
Copy ./cfjarsoap to your webroot, copy tests/test.cfc there too, then call test.cfm.

## Usage
generally:

```javascript
var thisdir = getDirectoryFromPath(getTemplatePath());
var jardir = thisdir & "/wsjars";
var srcdir = thisdir & "/wssrc";

var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);

var wsdl = "http://my.cool.host/myawesomeservice.asmx?wsdl";

cfsoap.addWSDL(wsdl=wsdl);  // just adds the WSDL, no compilation at this point

var c = cfsoap.getClassLoader(true);  // compiles/loads WSDLs

dump(cfsoap.getServices()); // tries to list available services
cb = c.create("com.cdyne.ws.weatherws.WeatherStub"); // javaloader to create service
dump(cb);
dump(cb.getCityWeatherByZIP("87104"));
dump(cfsoap.pojo2struct(cb.getCityWeatherByZIP("87104")));

dump(cfsoap.getCityWeatherByZIP(87104)); // or try using OnMissingMethod
```

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
```
./cfjarsoap build
```
then
```
./cfjarsoap runwar.start.fg
```
and browse to:
```
http://127.0.0.1:8088/tests/test.cfm
```
use ctrl-c to stop the server.


To clean all downloaded dependencies, run:
```
./cfjarsoap clean 
```