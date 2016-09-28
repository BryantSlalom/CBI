@isTest
private class CBIUSCollectionsEditCtrlTest {


	@isTest
	private static void testEditPageValid() {
		////Create test Data
		Account a = TestUtil.createAccountCBBD('Parent Account', true, true);
		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(a.id, 'Feature');

		//Verify if this is being used
		CBIUSCollectionsEditCtrl.SuccessErrorResponse su = new CBIUSCollectionsEditCtrl.SuccessErrorResponse();
		su = new CBIUSCollectionsEditCtrl.SuccessErrorResponse();

		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);

		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();
		pageRef.getParameters().put('cid', ia.id);

		controller = new CBIUSCollectionsEditCtrl();

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for (Apexpages.Message msg : msgs) {
			if (msg.getDetail().contains('URL missing Auth/Feature Id, cannot continue.')) b = true;
		}
		system.assert(b);
	}


	@isTest
	private static void testEditPageInvalid() {

		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);

		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();
		pageRef.getParameters().put('cid', '');

		controller = new CBIUSCollectionsEditCtrl();

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for (Apexpages.Message msg : msgs) {
			if (msg.getDetail().contains('URL missing Auth/Feature Id, cannot continue.')) b = true;
		}
		system.assert(b);
	}

	@isTest
	private static void testCreateSimilar() {

		Account a = TestUtil.createAccountCBBD('Parent Account', true, true);
		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(a.id, 'Feature');

		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();

		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);

		pageRef.getParameters().put('cid', ia.id);

		controller = new CBIUSCollectionsEditCtrl();
		controller.createSimilar();
		String cs = controller.createSimilar().getUrl();
		System.assertEquals('/apex/cbiusfeaturecreate?cid=' + ia.id, cs);
	}
	@isTest
	private static void testSaveItem() {

		Account a = TestUtil.createAccountCBBD('Parent Account', true, true);
		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(a.id, 'Feature');

		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);

		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();

		pageRef.getParameters().put('cid', ia.id);
		controller = new CBIUSCollectionsEditCtrl();
		controller.Wrapper.onMenu = 'no';
		controller.saveItem();
		CBI_US_Item_Authorization_Feature__c rst = [select ON_MENU_FLG__c from CBI_US_Item_Authorization_Feature__c where id = :ia.id];
		System.assertEquals('no', rst.ON_MENU_FLG__c);

	}
	@isTest
	private static void testSaveItemInvalid() {

		try {
			Account a = TestUtil.createAccountCBBD('Parent Account', true, true);
			CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(a.id, 'Feature');
			String note = 'asdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasda,';
			note += 'faasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaas,';
			note += 'faasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaas,';
			note += 'asdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdf,';
			note += 'aasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasd,';
			note += 'aasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasdfaasd';

			PageReference pageRef = Page.cbiusitemauthorizationedit;
			Test.setCurrentPageReference(pageRef);

			CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();

			pageRef.getParameters().put('cid', ia.id);
			controller = new CBIUSCollectionsEditCtrl();
			controller.Wrapper.Item.NOTES_TXT__c = note;
			controller.saveItem();

		} catch(DMLException e) {
			Boolean expectedExceptionThrown = (e.getMessage().contains('STRING_TOO_LONG') ? true : false);
			System.AssertEquals(expectedExceptionThrown, true);
		}
	}

	@isTest
	private static void testEndDate() {

		Account a = TestUtil.createAccountCBBD('Parent Account', true, true);
		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(a.id, 'Feature');

		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();

		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);

		pageRef.getParameters().put('cid', ia.id);

		controller = new CBIUSCollectionsEditCtrl();
		controller.EndItemToday();
		CBI_US_Item_Authorization_Feature__c rst = [select SET_PERIOD_END_DT_ID__c from CBI_US_Item_Authorization_Feature__c where id = :ia.id];
		System.AssertEquals(String.Valueof(Date.Today()), String.Valueof(rst.SET_PERIOD_END_DT_ID__c));
	}
	@isTest
	private static void testSaveStoresByTDLinxCodes() {

		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');		
		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();
		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('cid', ia.id);		
		controller = new CBIUSCollectionsEditCtrl();
		controller.TDLinxCodesToAdd = '123';
		controller.SaveStoresByTDLinxCodes();
	    List<Account_Auth_Feature__c> junc = [select CBI_US_Item_Authorization_Feature__c from Account_Auth_Feature__c where CBI_US_Item_Authorization_Feature__c =: ia.id];
		System.AssertEquals(1,junc.size());
	}

	@isTest
	private static void testSaveStoresByTDLinxCodesNoStore() {

		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');		
		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();
		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('cid', ia.id);		
		controller = new CBIUSCollectionsEditCtrl();
		controller.TDLinxCodesToAdd = '';
		controller.SaveStoresByTDLinxCodes();
	    List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for (Apexpages.Message msg : msgs) {
			if (msg.getDetail().contains('Please supply at least 1 TDLinx Submission Code')) b = true;
			system.debug('Get My Message' + msg.getDetail());
		}
		system.assert(b);
	}
	@isTest
	private static void testSaveStoresByTDLinxCodesNoStores() {

		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');		
		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();
		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('cid', ia.id);		
		controller = new CBIUSCollectionsEditCtrl();
		controller.TDLinxCodesToAdd = ',';
		controller.SaveStoresByTDLinxCodes();
	    List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for (Apexpages.Message msg : msgs) {
			if (msg.getDetail().contains('Please supply at least 1 TDLinx Submission Code')) b = true;
			system.debug('Get My Message' + msg.getDetail());
		}
		system.assert(b);
	}

	@isTest
	private static void testSaveStoresByTDLinxCodesWrongStore() {

		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');		
		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();
		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('cid', ia.id);		
		controller = new CBIUSCollectionsEditCtrl();
		controller.TDLinxCodesToAdd = '567';
		controller.SaveStoresByTDLinxCodes();
	    List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for (Apexpages.Message msg : msgs) {
			if (msg.getDetail().contains('No Stores matched your TDLinx Submission Code(s).')) b = true;			
		}
		system.assert(b);
	}

	@isTest
	private static void testSaveStoresByTDLinxCodesOneValidOneInvalid() {

		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');		
		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();
		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('cid', ia.id);		
		controller = new CBIUSCollectionsEditCtrl();
		controller.TDLinxCodesToAdd = '123,987';		
		controller.SaveStoresByTDLinxCodes();
	    List<Account_Auth_Feature__c> junc = [select CBI_US_Item_Authorization_Feature__c from Account_Auth_Feature__c where CBI_US_Item_Authorization_Feature__c =: ia.id];
		System.AssertEquals(1,junc.size());
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for (Apexpages.Message msg : msgs) {
			if (msg.getDetail().contains('The following TDLinx Codes were not found:')) b = true;
			system.debug('Get My Message' + msg.getDetail());			
		}
		system.assert(b);
		

	}
	@isTest
	private static void testRemoveStores() {

		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);
		String recid = aa.id;	
		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();
		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('cid', ia.id);		
		controller = new CBIUSCollectionsEditCtrl();
		controller.StoresToRemove = recid;
		controller.RemoveStores();
	    List<Account_Auth_Feature__c> junc = [select id from Account_Auth_Feature__c where CBI_US_Item_Authorization_Feature__c =: ia.ID];
		System.AssertEquals(0,junc.size());
		

	}
	@isTest
	private static void testRemoveStoresNoStores() {

		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);
			
		CBIUSCollectionsEditCtrl controller = new CBIUSCollectionsEditCtrl();
		PageReference pageRef = Page.cbiusitemauthorizationedit;
		Test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('cid', ia.id);		
		controller = new CBIUSCollectionsEditCtrl();
		controller.StoresToRemove = '';
		controller.RemoveStores();	    
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for (Apexpages.Message msg : msgs) {
			if (msg.getDetail().contains('Please choose at least one store to remove.')) b = true;
			system.debug('Get My Message' + msg.getDetail());
		}
		system.assert(b);
	}
}