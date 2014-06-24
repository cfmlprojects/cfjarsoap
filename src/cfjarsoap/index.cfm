
	<cffunction name="dumpvar" access="private">
		<cfargument name="var">
		<cfdump var="#var#">
		<cfabort/>
	</cffunction>

  <cffunction name="setUp" returntype="void" access="public">
 		<cfset variables.wsdl2jar = createObject("component","WSDL2Jar") />

<!--- 
		<cfset request.adminType = "web" />
		<cffile action="read" file="#expandpath("/tests/")#/cfadminpassword.txt" variable="session.passwordweb" />
 					<cfadmin action="updateJar"
					  type="web"
	          password="#session.passwordweb#"
					  jar="/workspace/railoshen/src/den/railoshen/wsdl2jar/wsjars/ym_contact/ym_contact.jar" />
 --->
  </cffunction>

	<cffunction name="testCreateJar">
		<cfscript>
/*
 			var jarLoader = variables.wsdl2jar.init("http://www.webservicex.net/uszip.asmx?WSDL","uszip");
			var zipService = jarLoader.create("NET.webserviceX.www.USZipLocator").getUSZipSoap();
			dump(zipService.getInfoByZIP("87104").get_any());
*/

 			// create the jar class loaders
 			var contactLoader = variables.wsdl2jar.init("https://api.yieldmanager.com/api-1.30/contact.php?wsdl","ym_contact");
 			var entityLoader = variables.wsdl2jar.init("https://api.yieldmanager.com/api-1.30/entity.php?wsdl","ym_entity");
 			// create services
			var contactService = contactLoader.create("com.yieldmanager.api.ContactService.ContactServiceLocator").getContactServicePort();
			var entityService = contactLoader.create("com.yieldmanager.api.EntityService.EntityServiceLocator").getEntityServicePort();
			

			var entityTypes = entityLoader.create("com.yieldmanager.api.types.Enum_ext_entity_type");
			var entities = entityLoader.create("com.yieldmanager.api.types.holders.Array_of_entityHolder");
			var entries_on_page = createObject("java","java.lang.Long").init(20);
			var page_num = createObject("java","java.lang.Long").init(1);
			var total_count = entityLoader.create("javax.xml.rpc.holders.LongHolder");
			// login stuff
			var loginOptions = contactLoader.create("com.yieldmanager.api.types.Login_options");
			var token = contactService.login("wee","hoo",loginOptions);
			
//    public void getAll(java.lang.String token, com.yieldmanager.api.types.Enum_ext_entity_type entity_type, long entries_on_page, long page_num, com.yieldmanager.api.types.holders.Array_of_entityHolder entities, javax.xml.rpc.holders.LongHolder total_count) throws java.rmi.RemoteException, com.yieldmanager.api.types.Exception_detail;
 			var idList = entityService.listAll( "token", entityTypes.Publisher ));
 			dump(idList);
 			entityService.getAll( "token", entityTypes.Publisher, entries_on_page, page_num, entities, total_count ));
 			dump(entities);
		</cfscript>
		
		getall(java.lang.String, com.yieldmanager.api.types.Enum_ext_entity_type, numeric, numeric, com.yieldmanager.api.types.holders.Array_of_entityHolder, javax.xml.rpc.holders.LongHolder)
		getAll(java.lang.String, com.yieldmanager.api.types.Enum_ext_entity_type, long, long,       com.yieldmanager.api.types.holders.Array_of_entityHolder, javax.xml.rpc.holders.LongHolder) 
	</cffunction>

<cfset setup() />
<cfset testCreateJar() />