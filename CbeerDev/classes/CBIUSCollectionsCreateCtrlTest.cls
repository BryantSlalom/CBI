@isTest
private class CBIUSCollectionsCreateCtrlTest {

	@isTest
	private static void testCreateNewItemAuthValid() {

		//Create test Data
		Account a = TestUtil.createAccountCBBD('Parent', true, true);
		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(a.id, 'Feature');

		CBIUSCollectionsCreateCtrl controller = new CBIUSCollectionsCreateCtrl();
		PageReference pageRef = Page.cbiusitemauthorizationcreate;
		Test.setCurrentPageReference(pageRef);

		pageRef.getParameters().put('cid', ia.id);

		controller = new CBIUSCollectionsCreateCtrl();
		controller.Done();
		controller.rt = 'Feature';
		controller.UltimateAccount = ia.id;
		controller.makePageRecordType();

	}

	@isTest
	private static void testCreateNewItemAuthInvalid() {

		test.startTest();

		try {
		    Account a = TestUtil.createAccountCBBD('Parent', true, true);
			CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(a.id, 'Feature');
			ia.Ultimate_Parent__c = null;
			update ia;
			CBIUSCollectionsCreateCtrl controller = new CBIUSCollectionsCreateCtrl();
			PageReference pageRef = Page.cbiusitemauthorizationcreate;
			Test.setCurrentPageReference(pageRef);			

			controller = new CBIUSCollectionsCreateCtrl();
			controller.Done();
			controller.rt = 'Feature';
			controller.makePageRecordType();

			System.assert(false, 'Exception expected');
		} catch(DMLException e) {
			Boolean expectedExceptionThrown = (e.getMessage().contains('REQUIRED_FIELD_MISSING') ? true : false);
			System.AssertEquals(expectedExceptionThrown, true);
		}
		test.stopTest();

	}
	@isTest
	private static void cancelPage() {

		//Create test Data
		Account a = TestUtil.createAccountCBBD('Parent', true, true);
		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(a.id, 'Feature');

		CBIUSCollectionsCreateCtrl controller = new CBIUSCollectionsCreateCtrl();
		PageReference pageRef = Page.cbiusitemauthorizationcreate;
		Test.setCurrentPageReference(pageRef);

		pageRef.getParameters().put('cid', ia.id);

		controller = new CBIUSCollectionsCreateCtrl();
		controller.cancelCollection();

	}

}