/**
 * Apex Class: TestUtil
 * Description: Utility class for testMethods
 * Created By: Dipika Gupta (Appirio Off)
 * Created Date: 17 Dec,2012
 *
 * 06/02/2016  Bryant Daniels  **Added new test Methods createBulkProducts, createBulkValidItemAuhtPKGCode,createBulkInvalidItemAuhtPKGCode
 * createBulkValidItemAuhtSKUCode, createBulkInvalidItemAuhtSKUCode, createBulkValidItemAuhtBrandCode, createBulkInvalidItemAuhtBrandCode
 * createBulkValidItemAuhtRetailerUPC, createBulkInvalidItemAuhtRetailerUPC, createBulkValidFeatureMasterPKGCode, createBulkInvalidFeatureMasterPKGCode
 * createBulkValidFeatureMasterSKUCode, createBulkInvalidFeatureMasterSKUCode,createBulkValidFeatureBrandCode,createBulkInvalidFeatureBrandCode,createBulkValidFeatureRetailerUPC
 * createBulkInvalidFeatureRetailerUPC
*/
@isTest
public class TestUtil {

	//create Intranet_Banner__c
	/*public static Intranet_Banner__c createIntranetBanner(Boolean isInsert){
	  DateTime sDate = DateTime.now().addDays(-5);
	  DateTime eDate = DateTime.now().addDays(5);
	  Intranet_Banner__c intranetBanner = new Intranet_Banner__c(Name='testBanner',
	  Start_Date__c = sDate,
	  End_Date__c = eDate,
	  Header__c = 'Virgin America',
	  Target__c = '_blank',
	  Pages__c ='Brand',
	  URL__c = 'http://www.virginamerica.com/');
	  if(isInsert) insert intranetBanner;
	  return intranetBanner;
	  }*/

	//create CollaborationGroup
	public static CollaborationGroup createGroup(Boolean isInsert) {
		CollaborationGroup collaborationGroup = new CollaborationGroup(Name = 'testGroup',
		                                                               CollaborationType = 'public');
		if (isInsert) insert collaborationGroup;
		return collaborationGroup;
	}


	//create CollaborationGroup
	public static CollaborationGroup createGroup(Boolean isInsert, String groupName) {
		CollaborationGroup collaborationGroup = new CollaborationGroup(Name = groupName,
		                                                               CollaborationType = 'public');
		if (isInsert) insert collaborationGroup;
		return collaborationGroup;
	}

	//create Intranet_CMS_Page__c
	/*public static Intranet_CMS_Page__c createContent(Boolean isInsert){
	  Intranet_CMS_Page__c content = new Intranet_CMS_Page__c(Name='testContent',
	  Status__c = 'Published',
	  Template__c ='Home',
	  URL__c='http://www.virginamerica.com/');
	  if(isInsert) insert content;
	  return content;
	  }

	  //create Intranet_CMS_Page__c
	  public static Intranet_CMS_Page__c createContent(String name ,Boolean isInsert ,Id parentPageId ,String template){
	  Intranet_CMS_Page__c content = new Intranet_CMS_Page__c(Name=name,
	  Status__c = 'Published',
	  Parent_page__c = parentPageId,
	  Template__c =template);
	  if(isInsert) insert content;
	  return content;
	  }*/

	//create Intranet_Article__c
	/*public static Intranet_Article__c createArticle(Boolean isInsert){
	  DateTime sDate = DateTime.now().addDays(-5);
	  DateTime eDate = DateTime.now().addDays(5);
	  Intranet_Article__c article = new Intranet_Article__c(Name='testContent',
	  Start_Date__c = sDate,
	  End_Date__c = eDate,
	  Pages__c ='Brand');
	  if(isInsert) insert article;
	  return article;
	  }*/

	//create Attachment
	public static Attachment createAttachment(Boolean isInsert, ID parentId) {
		Blob articleData = Blob.valueof('TestData');
		Attachment article = new Attachment(Name = 'testAttachment',
		                                    body = articleData,
		                                    ParentId = parentId);
		if (isInsert) insert article;
		return article;
	}
	public static User createUser(boolean isInsert) {
		List<Profile> profileList = [select id from Profile where Name = 'System Administrator' limit 1];
		Id profileId;
		User usr;
		if (profileList.get(0) != null) {
			profileId = profileList.get(0).Id;
		}

		usr = new User();
		usr.Email = 'test' + Integer.valueOf(Math.random()) + '@virginamerica.com';
		usr.Username = 'test' + Integer.valueOf(Math.random()) + '@testuser1.com';
		usr.LastName = 'test';
		usr.Alias = 'test';
		usr.ProfileId = profileId;
		usr.LanguageLocaleKey = 'en_US';
		usr.LocaleSidKey = 'en_US';
		usr.TimeZoneSidKey = 'America/Chicago';
		usr.EmailEncodingKey = 'UTF-8';
		if (isInsert) insert usr;
		return usr;
	}

	//create Intranet_Banner__c
	/*public static Intranet_Links__c createIntranetLink(Boolean isInsert){
	  DateTime sDate = DateTime.now().addDays(-5);
	  DateTime eDate = DateTime.now().addDays(5);
	  Intranet_Links__c intranetLink = new Intranet_Links__c(Name='testBanner',
	  Start_Date__c = sDate,
	  End_Date__c = eDate,
	  Target__c = '_blank',
	  Pages__c ='Brand',
	  URL__c = 'http://www.virginamerica.com/');
	  if(isInsert) insert intranetLink;
	  return intranetLink;
	  }*/
	/*public static Intranet_Performance__c createIntranetPerformance(Boolean isInsert){
	  Intranet_Performance__c intranetPerformance =  new Intranet_Performance__c(Name='Monthly Performance');
	  if(isInsert) insert intranetPerformance;
	  return intranetPerformance;
	  }*/


	//Create intranet_Config__c custom setting
	public static Intranet_Content__c createIntranetConfig(Boolean isInsert, String name, String value) {
		String recordTypeId = Schema.SObjectType.Intranet_Content__c.getRecordTypeInfosByName().get('Config - Portal').getRecordTypeId();
		Intranet_Content__c intranetConfing = new Intranet_Content__c(Name = name, Value__c = value, RecordTypeId = recordTypeId);
		if (isInsert) {
			insert intranetConfing;
		}
		return intranetConfing;
	}

	//create Intranet_Form__c
	/*public static Intranet_Form__c createForm(Boolean isInsert){
	  Intranet_Form__c form = new Intranet_Form__c();
	  if(isInsert) insert form;
	  return form;
	  }

	  //create form list record
	  public static IntranetFormList__c createFormList(Boolean isInsert,Id approverId){
	  IntranetFormList__c formList = new IntranetFormList__c();
	  formList.Active__c = true;
	  formList.Select_Approver__c = approverId;
	  if(isInsert) insert formList;
	  return formList;
	  }

	  //create form list fields record
	  public static IntranetFormListFields__c createFormListField(Boolean isInsert,Id formTypeId,Integer SequenceOrder,String fieldAPIName){
	  IntranetFormListFields__c formListField = new IntranetFormListFields__c();
	  formListField.Related_Form__c = formTypeId;
	  formListField.Sequence_Order__c = SequenceOrder;
	  formListField.Field_API_Name__c = fieldAPIName;
	  if(isInsert) insert formListField;
	  return formListField;
	  }

	  //Create intranet_Form_Config__c custom setting
	  public static Intranet_Form_Config__c createIntranetFromConfig(Boolean isInsert,String name, String FormFieldAPIName, String RelatedUserFieldAPIName){
	  Intranet_Form_Config__c formConfig = new Intranet_Form_Config__c();
	  formConfig.Name = name;
	  formConfig.Form_Field_API_Name__c = FormFieldAPIName;
	  formConfig.Related_User_Field_API_Name__c = RelatedUserFieldAPIName;
	  if(isInsert) insert formConfig;
	  return formConfig;
	  }*/

	public static Intranet_Content__c createIntranetContent(String name, Id recTypeId, Boolean isInsert) {
		Intranet_Content__c ic = new Intranet_Content__c();
		ic.Name = name;
		ic.RecordTypeId = recTypeId;
		if (isInsert) {
			insert ic;
		}
		return ic;
	}

	public static FeedItem createFeedItem(Id parentId, String title, String feedBody, Boolean isInsert) {
		FeedItem feedI = new FeedItem();
		if (title == null || title.trim() == '') feedI.Title = 'Test';
		feedI.Body = feedBody;
		if (feedBody == null || feedBody.trim() == '') {
			feedI.Body = 'Test Feed Body';
		}
		feedI.ParentId = parentId;
		if (isInsert) {
			insert feedI;
		}
		return feedI;
	}

	public static PermissionSet createPermissionSet(String name, Boolean isInsert) {
		PermissionSet ps = new PermissionSet();
		if (name == null || name.trim() == '') ps.Name = 'Test PS';
		if (isInsert) {
			insert ps;
		}
		return ps;
	}

	public static PermissionSetAssignment createPermissionSetAssignment(Id permissionSet, Id assignTo, Boolean isInsert) {
		PermissionSetAssignment psa = new PermissionSetAssignment();
		psa.AssigneeId = assignTo;
		psa.PermissionSetId = permissionSet;
		if (isInsert) {
			insert psa;
		}
		return psa;
	}

	public static Tags__c createTag(String tagName, Boolean isInsert) {
		Tags__c testTag = new Tags__c();
		testTag.Tag__c = tagName;
		if (isInsert) {
			insert testTag;
		}
		return testTag;
	}

	//This method will create Intranet Content Tags record
	public static Intranet_Content_Tags__c createIntranetContentTags(String contentId, String tagId, Boolean isInsert) {
		Intranet_Content_Tags__c testContentTag = new Intranet_Content_Tags__c();
		testContentTag.Intranet_Content__c = contentId;
		testContentTag.Tags__c = tagId;
		if (isInsert) {
			insert testContentTag;
		}
		return testContentTag;
	}

	public static Intranet_Content_Version__c createIntranetContentVersion(String contentId, Boolean isInsert) {
		Intranet_Content_Version__c intraContVer = new Intranet_Content_Version__c();
		intraContVer.Intranet_Content__c = contentId;
		intraContVer.Name = 'Test Intranet Content Version';
		if (isInsert) {
			insert intraContVer;
		}
		return intraContVer;
	}

	public static ContentVersion createContentVersion(Boolean isInsert) {
		ContentVersion libdoc = new ContentVersion();
		Blob beforeblob = Blob.valueOf('Testing base 64 encode');
		libdoc.VersionData = beforeblob;
		libdoc.Title = 'title1';
		libdoc.PathOnClient = 'xyz';
		if (isInsert) {
			insert libdoc;
		}
		return libdoc;
	}

	//----------------------------------------------------------------------------------------------------------
	// Create Account instance
	//----------------------------------------------------------------------------------------------------------
	public static Account createAccount(String name, Boolean isInsert) {
		Account acc = new Account();
		acc.Name = name;
		if (isInsert) {
			insert acc;
		}
		return acc;
	}
	public static Account createAccountCBBD(String name, Boolean isInsert, Boolean isParent) {
		Account acc = new Account();
		acc.Name = name;
		acc.Est_un_compte_parent__c = isParent;
		acc.Store_Code__c = '1234567890';
		acc.SUBACCOUNT_DSC__c = 'the sub Account';
		if (isInsert) {
			insert acc;
		}
		return acc;
	}
	public static Account createAccountAndSubAccounts(Account a, List<Account> subAccounts) {
		if (a != null) {
			insert a;
			if (subAccounts != null && subAccounts.size() > 0) {
				for (Account acc : subAccounts) {
					acc.ParentId = a.Id;
				}
				insert subAccounts;
			}
		}
		return a;
	}


	//----------------------------------------------------------------------------------------------------------
	// Create Contact instance
	//----------------------------------------------------------------------------------------------------------
	public static Contact createContact(String lName, Id accId, Boolean isInsert) {
		Contact cnt = new Contact();
		cnt.lastName = lName;
		cnt.AccountId = accId;
		if (isInsert) {
			insert cnt;
		}
		return cnt;
	}

	//----------------------------------------------------------------------------------------------------------
	// Create Task instance
	//----------------------------------------------------------------------------------------------------------
	public static Task createTask(Id parentId, Boolean isInsert) {
		Task tsk = new Task();
		tsk.whatId = parentId;
		if (isInsert) {
			insert tsk;
		}
		return tsk;
	}

	//----------------------------------------------------------------------------------------------------------
	// Create Task instance
	//----------------------------------------------------------------------------------------------------------
	public static Distributor_Location__c createDistributorLocation(id retailAccId, Id dbAccId, Boolean isInsert) {
		Distributor_Location__c dl = new Distributor_Location__c();
		dl.RetailAccount__c = retailAccId;
		dl.DistributorAccount__c = dbAccId;
		if (isInsert) {
			insert dl;
		}
		return dl;
	}

	//----------------------------------------------------------------------------------------------------------
	// Create Message Record
	//----------------------------------------------------------------------------------------------------------
	public static Message__c createMessage(String message, Boolean isInsert) {
		Message__c msg = new Message__c();
		msg.Message__c = message;
		msg.Category__c = 'Information';
		msg.Title__c = 'Test';
		msg.Publish_Start_Date__c = Date.today().addDays(- 1);
		msg.Publish_End_Date__c = Date.today().addDays(+ 10);
		if (isInsert) {
			insert msg;
		}
		return msg;
	}

	//----------------------------------------------------------------------------------------------------------
	// Create User Message Record
	//----------------------------------------------------------------------------------------------------------
	public static User_Message__c createUsrMessage(Id msgId, Id usrId, Boolean isInsert) {
		User_Message__c usrMsg = new User_Message__c();
		usrMsg.User__c = usrId;
		usrMsg.Message__c = msgId;
		if (isInsert) {
			insert usrMsg;
		}
		return usrMsg;
	}

	//-----------------------------------------------------------------------------------------------------------
	//Test Data For CBI Collections
	//-----------------------------------------------------------------------------------------------------------

	//----------------------------------------------------------------------------------------------------------
	// Create Item Authorization or Feature
	//----------------------------------------------------------------------------------------------------------
	public static CBI_US_Item_Authorization_Feature__c createItemAuthOrFeature(ID parentID, String rType) {
		createBulkProducts('228', '228-552-101', '80014016', '033544950104', '101');
		CBI_US_Item_Authorization_Feature__c rec = new CBI_US_Item_Authorization_Feature__c();

		RecordType rt = [select id, Name from RecordType where SobjectType = 'CBI_US_Item_Authorization_Feature__c' and RecordType.DeveloperName = :rType Limit 1];

		String typeCode;
		if (rType == 'Feature') {
			typeCode = 'BE';
		} else if(rType == 'Item_Authorization'){
			typeCode = 'CM';
		}

		rec.Ultimate_Parent__c = parentID;
		rec.Sub_Accounts__c = 'subAccount';
		rec.NEW_SET_FLG__c = 'Yes';
		rec.ON_MENU_FLG__c = 'Yes';
		rec.NOTES_TXT__c = 'Test Note';
		rec.Brand_Cd__c = '228';
		rec.MASTER_PKG_CD__c = '228-552-101';
		rec.MASTER_SKU_CD__c = '80014016';
		rec.GTIN_NO__c = '033544950104';
		rec.FEATURE_PRICE__c = 12.99;
		rec.SET_PERIOD_BEGIN_DT_ID__c = Date.Today();
		rec.SET_PERIOD_END_DT_ID__c = Date.Today();
		rec.RESET_PERIOD_BEGIN_DT_ID__c = Date.Today();
		rec.RESET_PERIOD_END_DT_ID__c = Date.Today();
		rec.Add_all_Parent_Account_stores__c = true;
		rec.Sub_Accounts__c = 'Sub Account';
		rec.Marketing_Groups__c = 'Marketing Group';
		rec.Report_To_Codes__c = 'rpt Code';
		rec.States__c = 'CA';
		rec.Type_CD__c = typeCode;
		rec.RecordTypeID = rt.id;

		insert rec;
		return rec;

	}

	//----------------------------------------------------------------------------------------------------------
	// Create Account Auth Feat Junction 
	//----------------------------------------------------------------------------------------------------------

	public static Account_Auth_Feature__c createAccountAuthFeat(Id childOfParentId, ID iafId) {
		Account_Auth_Feature__c aaf = new Account_Auth_Feature__c();
		aaf.CBI_US_Item_Authorization_Feature__c = iafId;
		aaf.Account__c = childOfParentId;
		insert aaf;
		return aaf;
	}
	//----------------------------------------------------------------------------------------------------------
	// Create Account Auth Feat Junction 
	//----------------------------------------------------------------------------------------------------------

	public static void createBulkAccountAuthFeat(Id childOfParentId, ID iafId) {
		List<Account_Auth_Feature__c> listToAdd = new List<Account_Auth_Feature__c> ();
		for (Integer i = 0; i < 200; i++) {
			Account_Auth_Feature__c aaf = new Account_Auth_Feature__c();
			aaf.CBI_US_Item_Authorization_Feature__c = iafId;
			aaf.Account__c = childOfParentId;
			listToAdd.add(aaf);
		}

		insert listToAdd;
	}


	//----------------------------------------------------------------------------------------------------------
	// Create Product
	//----------------------------------------------------------------------------------------------------------
	public static CBI_US_Product__c createBulkProducts(String brand, String Pkg, String sku, String gtin, String BevSeg) {
		CBI_US_Product__c p = new CBI_US_Product__c();
		p.Brand_Cd__c = brand;
		p.MASTER_PKG_CD__c = Pkg;
		p.MASTER_SKU_CD__c = sku;
		p.GTIN_NO__c = gtin;
		p.BEV_SEG_CD__c = BevSeg;
		p.MASTER_PKG_DSC__c = 'Corona 6 Pack';
		p.MASTER_SKU_DSC__c = 'Corona Keg';
		insert p;
		return p;
	}

	//Creates a products in bulk
	public static List<CBI_US_Product__c> createBulkProductsCBBD() {
		List<CBI_US_Product__c> tempProdList = new List<CBI_US_Product__c> ();
		for (Integer i = 0; i < 200; i++) {
			CBI_US_Product__c p = new CBI_US_Product__c();
			p.MASTER_SKU_CD__c = 's12345' + i;
			p.MASTER_PKG_CD__c = 'p12345' + i;
			p.BRAND_CD__c = 'b12345' + i;
			p.GTIN_NO__c = 'u12345' + i;
			p.BEV_SEG_CD__c = '101';

			tempProdList.add(p);
		}
		insert tempProdList;
		return tempProdList;

	}

	//----------------------------------------------------------------------------------------------------------
	// Create Invalid Codes that will be used on the 
	//----------------------------------------------------------------------------------------------------------

	public static void createInvalidBrandCode() {
		Account a = createAccountCBBD('Parent Account', true, true);
		CBI_US_Item_Authorization_Feature__c ia = createItemAuthOrFeature(a.id, 'Feature');
		ia.Brand_CD__c = 'invalidBrand';
		update ia;

	}
	public static void createInvalidPkgCode() {
		Account a = createAccountCBBD('Parent Account', true, true);
		CBI_US_Item_Authorization_Feature__c ia = createItemAuthOrFeature(a.id, 'Feature');
		ia.Master_PKG_CD__c = 'invalidPkg';
		update ia;

	}
	public static void createInvalidSkuCode() {
		Account a = createAccountCBBD('Parent Account', true, true);
		CBI_US_Item_Authorization_Feature__c ia = createItemAuthOrFeature(a.id, 'Feature');
		ia.Master_SKU_CD__c = 'invalidSku';
		update ia;

	}
	public static void createInvalidGtinCode() {
		Account a = createAccountCBBD('Parent Account', true, true);
		CBI_US_Item_Authorization_Feature__c ia = createItemAuthOrFeature(a.id, 'Feature');
		ia.Gtin_NO__c = 'invalidgtin';
		update ia;

	}


	public static void createBulkValidItemAuhtSKUCodeByAccountId(Id accountId) {
		List<CBI_US_Item_Authorization__c> tempItemList = new List<CBI_US_Item_Authorization__c> ();

		for (Integer i = 0; i < 200; i++) {
			CBI_US_Item_Authorization__c ia = new CBI_US_Item_Authorization__c();
			ia.Master_SKU_CD__c = 's12345' + i;
			ia.TDLinx_Submission_Code__c = accountId;
			ia.ITEM_AUTH_CD__c = 'CD123' + i;
			ia.SET_PERIOD_BEGIN_DT_ID__c = Date.today();
			ia.SET_PERIOD_END_DT_ID__c = Date.today().addMonths(2);
			ia.RESET_PERIOD_BEGIN_DT_ID__c = Date.today();
			ia.RESET_PERIOD_END_DT_ID__c = Date.today().addMonths(2);
			tempItemList.add(ia);
		}
		insert tempItemList;

	}



	//Creates valid item authorization that will be flagged for deletion
	public static void createBulkValidItemAuthFlag2Del() {
		Date beginDate = Date.newInstance(2014, 6, 7);
		Date endDate = Date.newInstance(2015, 6, 6);

		Account a = createAccountCBBD('Parent Account', true, true);
		CBI_US_Item_Authorization_Feature__c ia = createItemAuthOrFeature(a.id, 'Feature');

		ia.SET_PERIOD_BEGIN_DT_ID__c = beginDate;
		ia.SET_PERIOD_END_DT_ID__c = endDate;
		ia.Deletion__c = true;
		update ia;

	}



	public static void createStatesCustomSetting() {
		List<Country_State__c> states = new List<Country_State__c> ();
		states.add(new Country_State__c(Country__c = 'USA', Name = 'AK'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'AL'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'AR'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'AZ'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'CA'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'CO'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'CT'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'DC'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'DE'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'FL'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'GA'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'HI'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'IA'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'ID'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'IL'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'IN'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'KS'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'KY'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'LA'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'MA'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'MD'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'ME'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'MI'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'MN'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'MO'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'MS'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'MT'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'NC'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'ND'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'NE'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'NH'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'NJ'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'NM'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'NV'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'NY'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'OH'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'OK'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'OR'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'PA'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'RI'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'SC'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'SD'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'TN'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'TX'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'UT'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'VA'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'VT'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'WA'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'WI'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'WV'));
		states.add(new Country_State__c(Country__c = 'USA', Name = 'WY'));

		insert states;

	}



}