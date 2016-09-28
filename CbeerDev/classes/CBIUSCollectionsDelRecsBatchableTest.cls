@isTest
private class CBIUSCollectionsDelRecsBatchableTest {

	@isTest static void testCBIUSItemAuthDeleted() {

		//The query used by the batch job
		String query = 'SELECT Id FROM CBI_US_Item_Authorization_Feature__c where Deletion__c = true AND SET_PERIOD_END_DT_ID__c != null ';

		//Create Test Data
		
		TestUtil.createBulkValidItemAuthFlag2Del();

		//Start Test
		Test.startTest();
		CBIUSCollectionsDelRecsBatchable b = new CBIUSCollectionsDelRecsBatchable(query);
		database.executebatch(b);
		Test.stopTest();

		//verify cbi us item authorizations were deleted
		Integer i = [SELECT count() FROM CBI_US_Item_Authorization_Feature__c where Deletion__c = true AND SET_PERIOD_END_DT_ID__c != null ];
		System.assertEquals(i, 0);

	}

	@isTest static void testCBIUSItemAccountAuthDeleted() {

		//The query used by the batch job
		String query = 'SELECT Id FROM Account_Auth_Feature__c where Store_CD__c = null ';

		//Create Test Data
		//TestUtil.createBulkProducts();
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);

		delete child;

		//Start Test
		Test.startTest();
		CBIUSCollectionsDelRecsBatchable b = new CBIUSCollectionsDelRecsBatchable(query);
		database.executebatch(b);
		Test.stopTest();

		//verify cbi us item authorizations were deleted
		Integer i = [SELECT count() FROM Account_Auth_Feature__c where Store_CD__c = null ];
		System.assertEquals(i, 0);

	}
}