<cfcomponent extends="mxunit.framework.TestCase">
	<cfsetting requesttimeout="333"/>
	<!--- set to false when not testing generation to prevent memory leak --->
	<cfset regenerate = true />
	<cfset thisdir = getDirectoryFromPath(getMetadata(this).path) />
	<cfset jardir = thisdir & "/wsjars" />
	<cfset srcdir = thisdir & "/wssrc" />

	<cffunction name="beforeTests" returntype="void" access="public">
<!---
		<cfif directoryExists(jardir)>
			<cftry>
			<cfset directoryDelete(jardir,true) />
			<cfset directoryCreate(jardir) />
			<cfcatch></cfcatch>
			</cftry>
		</cfif>
 --->
	</cffunction>

	<cffunction name="setUp" returntype="void" access="public">
	</cffunction>

	<cffunction name="testWeather">
		<cfscript>
			wsdl = "http://wsf.cdyne.com/WeatherWS/Weather.asmx?wsdl";
			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
			cfsoap.addWSDL(wsdl=wsdl);
			var c = cfsoap.getClassLoader();
			request.debug("loaded jars:" & c.getClassloaderJars());
			try{
				cb = c.create("com.cdyne.ws.weatherws.WeatherStub");
				debug(cb);
				debug(cb.getCityWeatherByZIP("87104"));
				debug(cfsoap.pojo2struct(cb.getCityWeatherByZIP("87104")));
			} catch (any e) {
				debug(e.message);
			}
			debug(cfsoap.getCityWeatherByZIP(87104));
			debug(cfsoap.getServices());
		</cfscript>
	</cffunction>

	<cffunction name="testDisco">
		<cfscript>
			if(directoryExists(srcdir))
				directoryDelete(srcdir,true);
			wsdl = "https://disco.crm.dynamics.com/XRMServices/2011/Discovery.svc?wsdl";
			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
			cfsoap.addWSDL(wsdl=wsdl);
			var c = cfsoap.getClassLoader(true);
			request.debug("loaded jars:" & c.getClassloaderJars());
			try{
				cb = c.create("com.microsoft.schemas.xrm._2011.contracts.DiscoveryServiceStub");
				debug(cb);
			} catch (any e) {
				debug(e.message);
			}
			debug(cfsoap.getServices());
		</cfscript>
	</cffunction>

	<cffunction name="test404_disabled" access="private">
		<cfscript>
			if(directoryExists(srcdir)) directoryDelete(srcdir,true);
			wsdl = "http://www.itis.gov/ITISWebService/services/ITISService?wsdl";
			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
//			cfsoap.addWSDL(wsdl=wsdl,endpoint="http://www.itis.gov/ITISWebService/services/ITISService/getCredibilityRatings/");
//			cfsoap.addWSDL(wsdl=wsdl,endpoint="http://www.itis.gov/ITISWebService/services/ITISService/searchByCommonName/");
//			cfsoap.addWSDL(wsdl=wsdl,endpoint="http://www.itis.gov/ITISWebService/services/ITISService/");
			cfsoap.addWSDL(wsdl=wsdl);
//			cfsoap.addWSDL(wsdl=wsdl);
			var c = cfsoap.getClassLoader(true);
//			debug(cfsoap.getServices());
			debug(cfsoap.searchByCommonName("bullfrog"));
//			debug(cfsoap.searchForAnyMatchPaged("is",2,5,true));

//			debug(cfsoap.searchByScientificNameEndsWith("is"));
		</cfscript>
	</cffunction>

	<cffunction name="testMultiSameHost">
		<cfscript>
//			if(directoryExists(srcdir)) directoryDelete(srcdir,true);
			wsdl = "http://opendap.co-ops.nos.noaa.gov/axis/services/ActiveStations?wsdl";
			wsdl2 = "http://opendap.co-ops.nos.noaa.gov/axis/services/WaterLevelVerifiedHourly?wsdl";
			wsdl3 = "http://opendap.co-ops.nos.noaa.gov/axis/webservices/waterlevelverifieddaily/wsdl/WaterLevelVerifiedDaily.wsdl";

			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
			cfsoap.addWSDL(wsdl=wsdl);
			cfsoap.addWSDL(wsdl=wsdl2);
			cfsoap.addWSDL(wsdl=wsdl3);
			var c = cfsoap.getClassLoader();
//			debug(cfsoap.getServices());
//			var stub = c.create("gov.noaa.nos.co_ops.opendap.axis.webservices.activestations.wsdl.ActiveStationsServiceStub");
//			stub = stub.init(wsdl);
//			request.debug(cfsoap.pojo2struct(stub.getActiveStations()));
			var stations = cfsoap.getActiveStations().stations.station;
			assertTrue(arrayLen(stations));
			debug(stations[1]);
			var daily = cfsoap.getWaterLevelVerifiedDaily(beginDate="#dateFormat(dateAdd('m',-7,now()),'YYYYMMDD')#",endDate="#dateFormat(dateAdd('m',-6,now()),'YYYYMMDD')#",datum="IGLD",Unit=0,stationId="9044020");
			var hourly = cfsoap.getWaterLevelVerifiedHourly(beginDate="#dateFormat(dateAdd('m',-7,now()),'YYYYMMDD')#",endDate="#dateFormat(dateAdd('m',-6,now()),'YYYYMMDD')#",datum="STND",Unit=0,stationId=stations[1].name,timezone="0");
			assertTrue(arrayLen(hourly.data.item));
			assertTrue(arrayLen(daily.data.item));
		</cfscript>
	</cffunction>

	<cffunction name="testLowLevel">
		<cfscript>
			if(directoryExists(srcdir)) directoryDelete(srcdir,true);
			wsdl = "http://opendap.co-ops.nos.noaa.gov/axis/services/ActiveStations?wsdl";
			wsdl2 = "http://opendap.co-ops.nos.noaa.gov/axis/services/WaterLevelVerifiedHourly?wsdl";
			wsdl3 = "http://opendap.co-ops.nos.noaa.gov/axis/webservices/waterlevelverifieddaily/wsdl/WaterLevelVerifiedDaily.wsdl";

			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
//			cfsoap.addWSDL(wsdl=wsdl);
			cfsoap.addWSDL(wsdl=wsdl2);
//			cfsoap.addWSDL(wsdl=wsdl3);
			var c = cfsoap.getClassLoader();
//			debug(cfsoap.getServices());

/*
			var sstub = c.create("gov.noaa.nos.co_ops.opendap.axis.webservices.activestations.wsdl.ActiveStationsServiceStub");
			sstub = sstub.init(wsdl);
			var stations = sstub.getActiveStations().getStations().getStation();
*/
			var stub = c.create("gov.noaa.nos.co_ops.opendap.axis.webservices.waterlevelverifiedhourly.wsdl.WaterLevelVerifiedHourlyServiceStub");
			var qry = c.create("gov.noaa.nos.co_ops.opendap.axis.webservices.waterlevelverifiedhourly.wsdl.Parameters4");
			stub = stub.init(wsdl2);
			qry.setBeginDate(dateFormat(dateAdd('m',-7,now()),'YYYYMMDD'));
			qry.setEndDate(dateFormat(dateAdd('m',-6,now()),'YYYYMMDD'));
			qry.setDatum("STND");
			qry.setUnit(0);
			qry.setStationId("9044020");
			qry.setTimezone(0);
			request.debug(qry);
			request.debug(stub);
			var hourly = stub.getWaterLevelVerifiedHourly(qry);
			request.debug(cfsoap.pojo2struct(hourly));
			var stations = cfsoap.getActiveStations().stations.station;
			assertTrue(arrayLen(stations));
			debug(stations[1]);
			var daily = cfsoap.getWaterLevelVerifiedDaily(beginDate="#dateFormat(dateAdd('m',-7,now()),'YYYYMMDD')#",endDate="#dateFormat(dateAdd('m',-6,now()),'YYYYMMDD')#",datum="IGLD",Unit=0,stationId="9044020");
			var hourly = cfsoap.getWaterLevelVerifiedHourly(beginDate="#dateFormat(dateAdd('m',-7,now()),'YYYYMMDD')#",endDate="#dateFormat(dateAdd('m',-6,now()),'YYYYMMDD')#",datum="STND",Unit=0,stationId=stations[1].name,timezone="0");
			assertTrue(arrayLen(hourly.data.item));
			assertTrue(arrayLen(daily.data.item));
		</cfscript>
	</cffunction>

	<cffunction name="testMultiWSDL">
		<cfscript>
			if(directoryExists(srcdir))
				directoryDelete(srcdir,true);

			var wsdl1 = "http://www.webservicex.net/uszip.asmx?WSDL";
			var wsdl2 = "http://www.webservicex.com/globalweather.asmx?WSDL";
			var cfsoap = new cfjarsoap.JarSoap("axis2",jardir,srcdir);
			cfsoap.addWSDL(wsdl=wsdl1);
			cfsoap.addWSDL(wsdl=wsdl2);
			var loader = cfsoap.getClassLoader();
 			// create services
 			var services = cfsoap.getServices();
 			request.debug(services);
 			var serv = loader.create(services["getInfoByZip"].locator);
 			var opd = loader.create("org.apache.axis2.jaxws.description.impl.OperationDescriptionImpl");
 			var ops = serv._getServiceClient().getAxisService().getOperations();
 			var ops = serv._getServiceClient().getAxisService().getPublishedOperations();
 			var aserv = serv._getServiceClient().getAxisService();
 			var tsb = createObject("java","org.apache.commons.lang.builder.ToStringBuilder");
 			request.debug(cfsoap.pojo2struct(aserv.getEndpoints().values().iterator().next().getBinding().getChildren().next().getChildren().next().getAxisBindingOperation().getName().toString()));
 			request.debug(tsb.reflectionToString(aserv.getEndpoints().values().iterator().next().getBinding().getChildren().next().getChildren().next().getAxisBindingOperation()));
 			request.debug(tsb.reflectionToString(aserv));
 			for(var op in ops) {
 				op = ops[2];
	 			request.debug(tsb.reflectionToString(op));
	 			request.debug(aserv.getAxisConfiguration().getDocumentation());
	 			sv = aserv.getAxisConfiguration().getServices().values().iterator().next();
	 			request.debug(tsb.reflectionToString(sv));
	 			request.debug("PARAMERTS");
	 			request.debug(sv.getOperations().next());
	 			request.debug(op.getParameters());
	 			request.debug(op.getDocumentationNode());
	 			var chil = op.getChildren();
	 			request.debug(tsb.reflectionToString(chil.next()));
	 			request.debug(tsb.reflectionToString(chil.next().getParameters()));
	 			request.debug(op.getMessageReceiver());
	 			var msgs = op.getMessages();
	 			while(msgs.hasNext()) {
	 				msg = msgs.next();
	 				msg = msgs.next();
	 				request.debug(serv);
	 				throw('fart')
	 				request.debug(tsb.reflectionToString(msg));
	 			}
	 			throw("wee")
			}
		</cfscript>
	</cffunction>

   </cfcomponent>