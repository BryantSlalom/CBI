//Test class for testing following classes:
/*
// AsyncRequest__c
//AsyncRequestSetting__mdt

Triggers:
AccountTrigger.trigger (updated)
CBIUSItemAuthorizationFeatureTrigger.trigger (new)
AsyncRequestTrigger.trigger (new)

Classes:
AccountTriggerHandler (updated)
CBIUSItemFeatTriggerHandler (new) 
AsyncRequestTriggerHandler (new)
AsyncRequestQueueable (new) 
CBIUSStoreSetAutomation (new)
*/

@isTest
public class CBIUSStoreSetAutomationTest { 

	private static Id GetRTAuthOrFeature(String devName) {
		RecordType rt = [select id, Name from RecordType where SobjectType = 'CBI_US_Item_Authorization_Feature__c' and RecordType.DeveloperName = :devName Limit 1];
		System.assert(rt != null, 'Shouldve found recordtype for Auth/Feature');
		return rt.Id;
	}
	private static Id GetRTUSAccountId() {
		RecordType rt = [select id, Name FROM RecordType WHERE SobjectType = 'Account' AND RecordType.DeveloperName = 'US_Account' Limit 1];
		System.assert(rt != null, 'Shouldve found recordtype for Account.');
		return rt.Id;
	}
	private static Account MakeAccounts(Integer numStores, String billingState, String subAccount, String mGroup, String reportTo) {
		Account parentAcc = new Account(Name = 'ParentTestAcc', 
			Est_un_compte_parent__c = true);
		
		Id recordTypeUSAccount = GetRTUSAccountId();
		
		List<Account> accs = new List<Account>();
		for (Integer i = 0; i < numStores; i++) {
			Account a = new Account(Name = 'ChildTestAcc'+i, 
			SUBACCOUNT_DSC__c = subAccount,
			Marketing_Group__c = mGroup,
			RMA__c = reportTo,
			Est_un_compte_parent__c = false,
			BillingState = billingState, 
			BillingCity = 'SF', 
			BillingStreet = 'ST',
			RecordTypeId = recordTypeUSAccount);
			accs.add(a);
		}		
		TestUtil.createAccountAndSubAccounts(parentAcc, accs);
		
		return parentAcc;
	}

	@isTest
	private static void  TestEnqueue() {		
		Test.startTest();
		AsyncRequestQueueable.EnqueueAsyncJob(null);
		Test.stopTest();

		List<AsyncApexJob> jobs =
            [SELECT Id, Status, ExtendedStatus
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND
            ApexClass.Name='AsyncRequestQueueable'];

		System.assertEquals(1, jobs.size(), 'Should find one job');
	}
	@isTest
	private static void  TestEnqueueFuture() {		
		Test.startTest();
		AsyncRequestQueueable.EnqueueAsyncJobFuture(null);
		Test.stopTest();

		List<AsyncApexJob> jobs =
            [SELECT Id, Status, ExtendedStatus
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND
            ApexClass.Name='AsyncRequestQueueable'];

		System.assertEquals(1, jobs.size(), 'Should find one job');
	}

	@isTest
	private static void TestNoStoreSetCriteria() {
		TestUtil.createBulkProductsCBBD();
		Id itemRTID = GetRTAuthOrFeature('Feature');
		Account ultAcc = MakeAccounts(10,'CA','','','');

		Test.startTest();

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		insert item;

		Test.stopTest();

		List<Account_Auth_Feature__c> stores = GetRelatedStores(item.Id);

		System.assertEquals(0, stores.size(), 'Should find no associated stores.');
	}
	@isTest
	private static void TestStateStoreSetCriteria() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(10,'CA','','','');
		Id itemRTID = GetRTAuthOrFeature('Feature');

		Test.startTest();

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.States__c = 'CA';
		insert item;
		
		Test.stopTest();

		System.assertEquals(10, GetRelatedStores(item.Id).size(), 'Should find 10 associated stores with CA BillingState.');	
	}
	@isTest
	private static void TestStateStoreSetCriteriaUpdate() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(10,'CA','','','');
		Id itemRTID = GetRTAuthOrFeature('Feature');

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.States__c = 'CA';
		insert item;

		Test.startTest();

		item.States__c = '';
		update item;
		
		Test.stopTest();

		System.assertEquals(0, GetRelatedStores(item.Id).size(), 'Should find 0 associated stores with CA BillingState.');	
	}
	@isTest
	private static void TestSubAccountStoreSetCriteria() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(10,'CA','SubAccountA','','');
		Id itemRTID = GetRTAuthOrFeature('Feature');

		Test.startTest();

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Sub_Accounts__c = 'SubAccountA';
		insert item;
		
		Test.stopTest();

		System.assertEquals(10, GetRelatedStores(item.Id).size(), 'Should find 10 associated stores with SubAccountA .');	
	}
	@isTest
	private static void TestSubAccountStoreSetCriteriaUpdate() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(10,'CA','SubAccountA','','');
		Id itemRTID = GetRTAuthOrFeature('Feature');

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Sub_Accounts__c = 'SubAccountA';
		insert item;

		Test.startTest();

		item.Sub_Accounts__c = '';
		update item;
		
		Test.stopTest();

		System.assertEquals(0, GetRelatedStores(item.Id).size(), 'Should find 0 associated stores with SubAccountA .');	
	}
	@isTest
	private static void TestMarketingGroupStoreSetCriteria() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(10,'CA','','MGroup1','');
		Id itemRTID = GetRTAuthOrFeature('Feature');

		Test.startTest();

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Marketing_Groups__c = 'MGroup1';
		insert item;
		
		Test.stopTest();

		System.assertEquals(10, GetRelatedStores(item.Id).size(), 'Should find 10 associated stores with MGroup1 .');	
	}
	@isTest
	private static void TestMarketingGroupStoreSetCriteriaUpdate() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(10,'CA','','MGroup1','');
		Id itemRTID = GetRTAuthOrFeature('Feature');

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Marketing_Groups__c = 'MGroup1';
		insert item;

		Test.startTest();

		item.Marketing_Groups__c = '';
		update item;
		
		Test.stopTest();

		System.assertEquals(0, GetRelatedStores(item.Id).size(), 'Should find 0 associated stores with MGroup1 .');	
	}
	@isTest
	private static void TestReportToStoreSetCriteria() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(10,'CA','','','ReportTo1');
		Id itemRTID = GetRTAuthOrFeature('Feature');

		Test.startTest();

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Report_To_Codes__c = 'ReportTo1';
		insert item;
		
		Test.stopTest();

		System.assertEquals(10, GetRelatedStores(item.Id).size(), 'Should find 10 associated stores with ReportTo1 .');	
	}
	@isTest
	private static void TestReportToStoreSetCriteriaUpdate() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(10,'CA','','','ReportTo1');
		Id itemRTID = GetRTAuthOrFeature('Feature');

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Report_To_Codes__c = 'ReportTo1';
		insert item;

		Test.startTest();

		item.Report_To_Codes__c = '';
		update item;
		
		Test.stopTest();

		System.assertEquals(0, GetRelatedStores(item.Id).size(), 'Should find 0 associated stores with ReportTo1 .');	
	}
	@isTest
	private static void TestCheckAllStoresSetCriteria() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(200,'CA','','','');
		Id itemRTID = GetRTAuthOrFeature('Feature');

		Test.startTest();

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Add_all_Parent_Account_stores__c = true;
		insert item;
		
		Test.stopTest();

		System.assertEquals(200, GetRelatedStores(item.Id).size(), 'Should find 200 associated stores.');	
	}
	@isTest
	private static void TestCheckAllStoresSetCriteriaUpdate() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(200,'CA','','','');
		Id itemRTID = GetRTAuthOrFeature('Feature');
		
		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Add_all_Parent_Account_stores__c = true;
		insert item;

		Test.startTest();

		item.Add_all_Parent_Account_stores__c = false;
		update item;		
		
		Test.stopTest();

		System.assertEquals(0, GetRelatedStores(item.Id).size(), 'Should find 0 associated stores.');	
	}
	@isTest
	private static void TestCheckAllStoresSetCriteriaUpdateTry2() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(200,'CA','','','');
		Id itemRTID = GetRTAuthOrFeature('Feature');
		
		
		Test.startTest();

		//Create the Feat with no Store set criteria, assert no Junctions were created.
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Add_all_Parent_Account_stores__c = true;
		insert item;

		item.Add_all_Parent_Account_stores__c = false;
		update item;		
		
		Test.stopTest();

		System.assertEquals(0, GetRelatedStores(item.Id).size(), 'Should find 0 associated stores.');	
	}
	@isTest
	private static void TestCreateAccount() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(0,'CA','','','');
		Id itemRTID = GetRTAuthOrFeature('Feature');
		Id recordTypeUSAccount = GetRTUSAccountId();
		
		//Create the Feat with all storesc checked, (but no stores exists)
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.Add_all_Parent_Account_stores__c = true;
		insert item;

		Test.startTest();

		Account sub1  = new Account(Name = 'ChildTestAcc', 
			ParentId = ultAcc.Id,
			SUBACCOUNT_DSC__c = '',
			Marketing_Group__c = '',
			RMA__c = '',
			Est_un_compte_parent__c = false,
			BillingState = 'AZ', 
			BillingCity = 'SF', 
			BillingStreet = 'ST',
			RecordTypeId = recordTypeUSAccount);

		insert sub1;	
		
		Test.stopTest();

		List<Account_Auth_Feature__c> junctions = GetRelatedStores(item.Id);

		System.assertEquals(1, junctions.size(), 'Should find 1 associated stores.');	
		System.assertEquals(sub1.Id, junctions[0].Account__c, 'Should match the one store created.');
	}
	@isTest
	private static void TestUpdateAccount() {
		TestUtil.createBulkProductsCBBD();		
		Account ultAcc  = MakeAccounts(1,'CA','','','');
		Id itemRTID = GetRTAuthOrFeature('Feature');
		Id recordTypeUSAccount = GetRTUSAccountId();

		Account sub1 = [SELECT Id, BillingState FROM Account WHERE ParentId = :ultAcc.Id LIMIT 1];
		System.assert(sub1 != null, 'Should have found 1 created child account.');
		
		CBI_US_Item_Authorization_Feature__c item = defaultItem(ultAcc.Id, 'Feature', itemRTID);
		item.States__c = 'AZ';
		insert item;

		Test.startTest();

		sub1.BillingState = 'AZ';
		update sub1;	
		
		Test.stopTest();

		List<Account_Auth_Feature__c> junctions = GetRelatedStores(item.Id);

		System.assertEquals(1, junctions.size(), 'Should find 1 associated stores.');	
		System.assertEquals(sub1.Id, junctions[0].Account__c, 'Should match the one store created.');
	}

	@isTest
	private static void TestAsyncRequestTriggerHandler(){

	AsyncRequestTriggerHandler a = new AsyncRequestTriggerHandler();

	}

	@isTest
	private static void TestBadParams() {
		AsyncRequest__c req = new AsyncRequest__c(AsyncType__c = AsyncRequestQueueable.TYPE_STORE_SET_AUTOMATION_ITEM,
			Params__c = '');

		Test.startTest();

		insert req;
		
		Test.stopTest();

		List<AsyncRequest__c> requests = [SELECT Id, Error__c FROM AsyncRequest__c];

		System.assertEquals(1, requests.size(), 'Should find 1 request record');	
		System.assertEquals(true, requests[0].Error__c, 'Should be marked as error.');
	}
	
	private static List<Account_Auth_Feature__c> GetRelatedStores(Id itemId) {
		return [SELECT Id, System_Managed__c, Account__c, Account__r.Name, CBI_US_Item_Authorization_Feature__c 
                    FROM Account_Auth_Feature__c where CBI_US_Item_Authorization_Feature__c = :itemId];
	}

	public static CBI_US_Item_Authorization_Feature__c defaultItem(ID parentID, String rtDevName, Id rtId) {
		
		CBI_US_Item_Authorization_Feature__c rec = new CBI_US_Item_Authorization_Feature__c();
		rec.RecordTypeID = rtId;		
		if (rtDevName == 'Feature') {
			rec.Type_CD__c = 'BE';
		} else if(rtDevName == 'Item_Authorization'){
			rec.Type_CD__c = 'CM';
		}
		rec.Ultimate_Parent__c = parentID;
		rec.Sub_Accounts__c = '';
		rec.NEW_SET_FLG__c = '';
		rec.ON_MENU_FLG__c = '';
		rec.NOTES_TXT__c = '';
		rec.Brand_Cd__c = 'b123450';
		rec.MASTER_PKG_CD__c = 'p123450';
		rec.MASTER_SKU_CD__c = '';
		rec.GTIN_NO__c = null;
		rec.FEATURE_PRICE__c = 12.99;
		rec.SET_PERIOD_BEGIN_DT_ID__c = Date.Today();
		rec.SET_PERIOD_END_DT_ID__c = Date.Today();
		rec.RESET_PERIOD_BEGIN_DT_ID__c = Date.Today();
		rec.RESET_PERIOD_END_DT_ID__c = Date.Today();
		rec.Add_all_Parent_Account_stores__c = false;
		rec.Sub_Accounts__c = '';
		rec.Marketing_Groups__c = '';
		rec.Report_To_Codes__c = '';
		rec.States__c = '';
		return rec;
	}

	

}