@isTest
public class CBIUSCollectionsUtilityTest {
	private static Account MakeAccountsAndProducts() {
		Account parentAcc = new Account(Name = 'ParentTestAcc',
		                                Est_un_compte_parent__c = true);

		List<Account> accs = new List<Account> ();
		for (Integer i = 0; i < 200; i++) {
			Account a = new Account(Name = 'ChildTestAcc' + i, BillingState = 'CA',
			                        Est_un_compte_parent__c = false,
			                        BillingCity = 'SF',
			                        BillingStreet = 'ST');
			accs.add(a);
		}
		TestUtil.createAccountAndSubAccounts(parentAcc, accs);
		TestUtil.createBulkProducts('228', '228-552-101', '80014016', '033544950104', '101');
		return parentAcc;
	}
	private static Account MakeAccountsAndProducts(Integer numAccs) {
		Account parentAcc = new Account(Name = 'ParentTestAcc',
		                                Est_un_compte_parent__c = true);

		List<Account> accs = new List<Account> ();
		for (Integer i = 0; i < numAccs; i++) {
			Account a = new Account(Name = 'ChildTestAcc' + i, BillingState = 'CA',
			                        Est_un_compte_parent__c = false,
			                        BillingCity = 'SF',
			                        BillingStreet = 'ST');
			accs.add(a);
		}
		TestUtil.createAccountAndSubAccounts(parentAcc, accs);
		TestUtil.createBulkProducts('228', '228-552-101', '80014016', '033544950104', '101');
		return parentAcc;
	}

	private static CBIUSCollectionsCtrlBase SetupController() {
		TestUtil.createStatesCustomSetting();
		CBIUSCollectionsCtrlBase ctrl = new CBIUSCollectionsCtrlBase();
		System.assertEquals(ctrl.States.size(), 51, 'Should find 51 states.');
		System.assertEquals(ctrl.States[0].getLabel(), 'AK', 'Sort order should be alphabetic.');
		return ctrl;
	}

	private static testmethod void TestRetrieveSubAccounts() {
		Account parent = MakeAccountsAndProducts();
		Test.startTest();
		CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);
		System.assert(accs != null, 'Should find 200 child Accounts');
		Test.stopTest();
	}

	private static testmethod void TestRetrieveBrands() {
		TestUtil.createBulkProducts('228', '228-552-101', '80014016', '033544950104', '101');
		Test.startTest();
		//Brands
		List<CBIUSCollectionsUtility.JSOption> brands = CBIUSCollectionsUtility.RetrieveBrands();
		System.assertEquals(1, brands.size(), 'Should be 200 brands found based on unique Brand Description.');
		Test.stopTest();
	}

	private static testmethod void TestRetrieveSkuPkgsInvalid() {
		TestUtil.createBulkProducts('228', '228-552-101', '80014016', '033544950104', '101');
		List<CBIUSCollectionsUtility.JSOption> brands = CBIUSCollectionsUtility.RetrieveBrands();
		Test.startTest();
		//Invalid params
		List<CBIUSCollectionsUtility.JSOption> skuPkgOptions = CBIUSCollectionsUtility.RetrieveSkusOrPackages(null, null);
		System.assert(skuPkgOptions.size() == 0, 'Invalid parameters should result in empty list.');
		Test.stopTest();
	}

	private static testmethod void TestRetrieveSkuPkgsValid() {
		CBI_US_Product__c p = TestUtil.createBulkProducts('228', '228-552-101', '80014016', '033544950104', '101');

		List<CBIUSCollectionsUtility.JSOption> brands = CBIUSCollectionsUtility.RetrieveBrands();
		Test.startTest();
		//1 PKG Found
		System.debug('Found the Brand Code' + p.Brand_Cd__c);
		List<CBIUSCollectionsUtility.JSOption> skuPkgOptions =
		CBIUSCollectionsUtility.RetrieveSkusOrPackages(Brands[0].OptionID, CBIUSCollectionsUtility.PKG);
		System.assert(skuPkgOptions.size() == 1, 'Should find 1 PKG for this Brand.');
		//1 SKU Found
		skuPkgOptions =
		CBIUSCollectionsUtility.RetrieveSkusOrPackages(Brands[0].OptionID, CBIUSCollectionsUtility.SKU);
		System.assert(skuPkgOptions.size() == 1, 'Should find 1 SKU for this Brand.');
		Test.stopTest();
	}
	

	//-------- ITEM AUTH SEARCH ------------------------------------------------------------
	private static testmethod void TestSearchByParentAccount() {
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	
		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);

		CBIUSCollectionsCtrlBase ctrl = SetupController();
		CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);
		
		Test.startTest();
		List<CBIUSCollectionsUtility.SearchResultWrapper> rList = CBIUSCollectionsUtility.searchItemAuthsFeatures(
		'',parent.id,'',new List<String>(),'','','','','','','',CBIUSCollectionsUtility.PKG);
		System.assertEquals(1, rList.size(), 'Should find 1 Item Auths by Parent Id.');
		Test.stopTest();
	}

	private static testmethod void TestSearchBySubAccount() {
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123',
		SUBACCOUNT_DSC__c = 'The Sub Account', RMA__c = 'Report to ',Marketing_Group__c='Marketing Group' );
		insert child;	
		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);

		CBIUSCollectionsCtrlBase ctrl = SetupController();
		CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);

		Test.startTest();
		List<CBIUSCollectionsUtility.SearchResultWrapper> rList = CBIUSCollectionsUtility.searchItemAuthsFeatures(
		'',parent.id,'',new List<String>(),'','','','','','','',CBIUSCollectionsUtility.PKG);
		System.assertEquals(1, rList.size(), 'Should find 200 Item Auths for SubAccount.');
		Test.stopTest();
	}

	private static testmethod void TestSearchByStates() {
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123',
		SUBACCOUNT_DSC__c = 'The Sub Account', RMA__c = 'Report to ',Marketing_Group__c='Marketing Group');
		insert child;

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);

		CBIUSCollectionsCtrlBase ctrl = SetupController();
		CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);

		Test.startTest();
		List<String> stateSearch = new List<String> {'AK','AZ'};
		List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
		'',parent.id, '',
		stateSearch, '', '', '', '',
		'', '', '', CBIUSCollectionsUtility.PKG);
		System.assertEquals(0, rList.size(), 'Should find 0 Item Auths for in AK or AZ.');

		stateSearch = new List<String> {'CA'};
		rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
		'',parent.id, '',
		stateSearch, '', '', '', '',
		'', '', '', CBIUSCollectionsUtility.PKG);
		System.assertEquals(1, rList.size(), 'Should find 200 Item Auths for in CA or MN.');

		Test.stopTest();
	}

	private static testmethod void TestSearchByStartDate() {
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123',
		SUBACCOUNT_DSC__c = 'The Sub Account', RMA__c = 'Report to ',Marketing_Group__c='Marketing Group');
		insert child;

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);

		CBIUSCollectionsCtrlBase ctrl = SetupController();
		CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);

		Test.startTest();

		//Start Date only. Should find records that are ON OR AFTER StartDate filter.
		//DateTime startDateFilter = DateTime.newInstance
		String startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addDays(5).format('MM/dd/yyyy');
		System.debug(LoggingLevel.INFO, 'startDate: ' + startDate);
		List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
		'',parent.id, '',
		new List<String>(), startDate, '', '', '',
		'', '', '', CBIUSCollectionsUtility.PKG);
		System.assertEquals(0, rList.size(), 'Shouldnt find StartDate of 5 days in future.');


		//Searching for StartDate filter of 5 days prior to record startdates.
		startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addDays(-5).format('MM/dd/yyyy');
		rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
		'',parent.id, '',
		new List<String>(), startDate, '', '', '',
		'', '', '', CBIUSCollectionsUtility.PKG);
		System.assertEquals(1, rList.size(), 'Should find 200 Item Auths created today when searching StartDate filter 5 days ago.');

		Test.stopTest();
	}

	private static testmethod void TestSearchByEndDate() {
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123',
		SUBACCOUNT_DSC__c = 'The Sub Account', RMA__c = 'Report to ',Marketing_Group__c='Marketing Group');
		insert child;

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);
		

		CBIUSCollectionsCtrlBase ctrl = SetupController();
		CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);

		Test.startTest();

		//End Date only: Should find records where record.EndDate ON OR BEFORE EndDate filter AND 
		//record.StartDate ON OR BEFORE EndDate filter.
		//DateTime startDateFilter = DateTime.newInstance
		String EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).addMonths(3)).format('MM/dd/yyyy');
		System.debug(LoggingLevel.INFO, 'endDate: ' + EndDate);
		
		List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures('',parent.id, '',
		new List<String>(), '', EndDate, '', '',
		'', '', '', CBIUSCollectionsUtility.PKG);
		System.assertEquals(1, rList.size(), 'Should find EndDate ON OR BEFORE Today+3months');


		//Searching for StartDate filter of 5 days prior to record startdates.
		//EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
		//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
		//'',parent.id, '',
		//new List<String>(), '', EndDate, '', '',
		//'', '', '', CBIUSCollectionsUtility.PKG);
		//System.assertEquals(0, rList.size(), 'Shouldnt find because record.EndDate not ON OR BEFORE Today+1Month');

		Test.stopTest();
	}

	//private static testmethod void TestSearchByStarAndEndDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidItemAuhtPKGCodeByAccountId(accs[0].OptionId);

	//Test.startTest();

	////End Date only. Should find records that are (ON OR AFTER StartDate) AND (ON OR BEFORE EndDate) .
	////DateTime startDateFilter = DateTime.newInstance
	//String startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//String EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'startDate: ' + startDate);
	//System.debug(LoggingLevel.INFO, 'endDate: ' + EndDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), startDate, EndDate, '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find because recordStartDate is BEFORE filter');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(-1).format('MM/dd/yyyy');
	//EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(3).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'','', 
	//new List<String>(), startDate, EndDate, '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find them because recordStartDate is AFTER filter and recordEndDate BEFOE filter');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchByResetStartDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidItemAuhtPKGCodeByAccountId(accs[0].OptionId);

	//Test.startTest();

	////Start Date only. Should find records that are ON OR AFTER StartDate filter.
	////DateTime startDateFilter = DateTime.newInstance
	//String startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addDays(5).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'startDate: ' + startDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', startDate, '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find StartDate of 5 days in future.');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addDays(-5).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', startDate, '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find 200 Item Auths created today when searching StartDate filter 5 days ago.');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchByResetEndDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidItemAuhtPKGCodeByAccountId(accs[0].OptionId);

	//Test.startTest();

	////End Date only: Should find records where record.EndDate ON OR BEFORE EndDate filter AND 
	////record.StartDate ON OR BEFORE EndDate filter.
	////DateTime startDateFilter = DateTime.newInstance
	//String EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).addMonths(3)).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'endDate: ' + EndDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', EndDate,
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find EndDate ON OR BEFORE Today+3months');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', EndDate,
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find because record.EndDate not ON OR BEFORE Today+1Month');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchByResetStartAndResetEndDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidItemAuhtPKGCodeByAccountId(accs[0].OptionId);

	//Test.startTest();

	////End Date only. Should find records that are (ON OR AFTER StartDate) AND (ON OR BEFORE EndDate) .
	////DateTime startDateFilter = DateTime.newInstance
	//String startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//String EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'startDate: ' + startDate);
	//System.debug(LoggingLevel.INFO, 'endDate: ' + EndDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '',startDate, EndDate,
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find because recordStartDate is BEFORE filter');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(-1).format('MM/dd/yyyy');
	//EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(3).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', startDate, EndDate,
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find them because recordStartDate is AFTER filter and recordEndDate BEFOE filter');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchByNewAsOf() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidItemAuhtPKGCodeByAccountId(accs[0].OptionId);

	//Test.startTest();

	////Start Date only. Should find records that are ON OR AFTER StartDate filter.
	////DateTime startDateFilter = DateTime.newInstance
	//String asOfDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).addMonths(-1)).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'asOfDate: ' + asOfDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', '',
	//asOfDate, '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Searching for 1 month in past, records created today, should find.');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//asOfDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).addMonths(1)).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', '',
	//asOfDate, '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Searching for records created after next month, these created today, dont find');

	//Test.stopTest();
	//}

	private static testmethod void TestSearchByBrand() {
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123',
		SUBACCOUNT_DSC__c = 'The Sub Account', RMA__c = 'Report to ',Marketing_Group__c='Marketing Group');
		insert child;

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);
		

		CBIUSCollectionsCtrlBase ctrl = SetupController();
		CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);

		Test.startTest();

		//Brand - p123450
		String brand ='228';
		System.debug(LoggingLevel.INFO, 'brand: ' + brand);
		List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
		'',parent.id, '',
		new List<String>(), '', '', '', '',
		'', brand, '', CBIUSCollectionsUtility.PKG);
		System.assertEquals(1, rList.size(), 'Should find brand ');

	Test.stopTest();
	}

	private static testmethod void TestSearchByPKG() {
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123',
		SUBACCOUNT_DSC__c = 'The Sub Account', RMA__c = 'Report to ',Marketing_Group__c='Marketing Group');
		insert child;

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);
		

		CBIUSCollectionsCtrlBase ctrl = SetupController();
		CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);
		List<CBIUSCollectionsUtility.JSOption> brands = CBIUSCollectionsUtility.RetrieveBrands();
		
		List<CBIUSCollectionsUtility.JSOption> skuPkgOptions =
		CBIUSCollectionsUtility.RetrieveSkusOrPackages(Brands[0].OptionID, CBIUSCollectionsUtility.PKG);

		Test.startTest();

		//PKG 
		String thePkg = skuPkgOptions[0].OptionId;
		System.debug(LoggingLevel.INFO, 'package: ' + thePkg);
		List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
		'',parent.id, '',
		new List<String>(), '', '', '', '',
		'', '', thePkg, CBIUSCollectionsUtility.PKG);
		System.assertEquals(1, rList.size(), 'Should find package ');

		Test.stopTest();
	}

	private static testmethod void TestSearchBySKU() {
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123',
		SUBACCOUNT_DSC__c = 'The Sub Account', RMA__c = 'Report to ',Marketing_Group__c='Marketing Group');
		insert child;

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);
		

		CBIUSCollectionsCtrlBase ctrl = SetupController();
		CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);
		List<CBIUSCollectionsUtility.JSOption> brands = CBIUSCollectionsUtility.RetrieveBrands();
		
		List<CBIUSCollectionsUtility.JSOption> skuPkgOptions =
		CBIUSCollectionsUtility.RetrieveSkusOrPackages(Brands[0].OptionID, CBIUSCollectionsUtility.SKU);

		Test.startTest();

		//SKU 
		String theSku = skuPkgOptions[0].OptionId;
		
		List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
		'',parent.id, '',
		new List<String>(), '', '', '', '',
		'', '', theSku, CBIUSCollectionsUtility.SKU);
		System.assertEquals(1, rList.size(), 'Should find package ');

		Test.stopTest();
	}


	////--------- FEATURE SEARCH -------------------------------------------------
	//private static testmethod void TestSearchFeatureByParentAccount() {
		//Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		//insert parent;
		//Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		//insert child;	
		//CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');
		//Account_Auth_Feature__c aa= TestUtil.createAccountAuthFeat(child.id, ia.id);

		//CBIUSCollectionsCtrlBase ctrl = SetupController();
		//CBIUSCollectionsUtility.AccountHierarchy accs = CBIUSCollectionsUtility.RetrieveAccountHierarchy(parent.Id);
		
		//Test.startTest();
		//List<CBIUSCollectionsUtility.SearchResultWrapper> rList = CBIUSCollectionsUtility.searchItemAuthsFeatures(
		//'',parent.id,'',new List<String>(),'','','','','','','',CBIUSCollectionsUtility.PKG);
		//System.assertEquals(1, rList.size(), 'Should find 1 Item Auths by Parent Id.');
		//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureBySubAccount() {
	//Account pAcc = MakeAccountsAndProducts();
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//'',accs[0].OptionId, '',
	//new List<String>(), '', '', '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find 200 Item Auths for SubAccount.');
	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByStates() {
	//Account pAcc = MakeAccountsAndProducts();
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();
	//List<String> stateSearch = new List<String> {'AK','AZ'};
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//stateSearch, '', '', '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Should find 0 Item Auths for in AK or AZ.');

	//stateSearch = new List<String> {'CA','MN'};
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//stateSearch, '', '', '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find 200 Item Auths for in CA or MN.');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByStartDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();

	////Start Date only. Should find records that are ON OR AFTER StartDate filter.
	////DateTime startDateFilter = DateTime.newInstance
	//String startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addDays(5).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'startDate: ' + startDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), startDate, '', '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find StartDate of 5 days in future.');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addDays(-5).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), startDate, '', '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find 200 Item Auths created today when searching StartDate filter 5 days ago.');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByEndDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();

	////End Date only: Should find records where record.EndDate ON OR BEFORE EndDate filter AND 
	////record.StartDate ON OR BEFORE EndDate filter.
	////DateTime startDateFilter = DateTime.newInstance
	//String EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).addMonths(3)).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'endDate: ' + EndDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', EndDate, '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find EndDate ON OR BEFORE Today+3months');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', EndDate, '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find because record.EndDate not ON OR BEFORE Today+1Month');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByStarAndEndDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();

	////End Date only. Should find records that are (ON OR AFTER StartDate) AND (ON OR BEFORE EndDate) .
	////DateTime startDateFilter = DateTime.newInstance
	//String startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//String EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'startDate: ' + startDate);
	//System.debug(LoggingLevel.INFO, 'endDate: ' + EndDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), startDate, EndDate, '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find because recordStartDate is BEFORE filter');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(-1).format('MM/dd/yyyy');
	//EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(3).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), startDate, EndDate, '', '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find them because recordStartDate is AFTER filter and recordEndDate BEFOE filter');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByResetStartDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();

	////Start Date only. Should find records that are ON OR AFTER StartDate filter.
	////DateTime startDateFilter = DateTime.newInstance
	//String startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addDays(5).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'startDate: ' + startDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', startDate, '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find StartDate of 5 days in future.');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addDays(-5).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', startDate, '',
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find 200 Item Auths created today when searching StartDate filter 5 days ago.');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByResetEndDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();

	////End Date only: Should find records where record.EndDate ON OR BEFORE EndDate filter AND 
	////record.StartDate ON OR BEFORE EndDate filter.
	////DateTime startDateFilter = DateTime.newInstance
	//String EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).addMonths(3)).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'endDate: ' + EndDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', EndDate,
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find EndDate ON OR BEFORE Today+3months');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', EndDate,
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find because record.EndDate not ON OR BEFORE Today+1Month');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByResetStartAndResetEndDate() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();

	////End Date only. Should find records that are (ON OR AFTER StartDate) AND (ON OR BEFORE EndDate) .
	////DateTime startDateFilter = DateTime.newInstance
	//String startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//String EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(1).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'startDate: ' + startDate);
	//System.debug(LoggingLevel.INFO, 'endDate: ' + EndDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '',startDate, EndDate,
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Shouldnt find because recordStartDate is BEFORE filter');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//startDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(-1).format('MM/dd/yyyy');
	//EndDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day())).addMonths(3).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', startDate, EndDate,
	//'', '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Should find them because recordStartDate is AFTER filter and recordEndDate BEFOE filter');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByNewAsOf() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();

	////Start Date only. Should find records that are ON OR AFTER StartDate filter.
	////DateTime startDateFilter = DateTime.newInstance
	//String asOfDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).addMonths(-1)).format('MM/dd/yyyy');
	//System.debug(LoggingLevel.INFO, 'asOfDate: ' + asOfDate);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', '',
	//asOfDate, '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(200, rList.size(), 'Searching for 1 month in past, records created today, should find.');


	////Searching for StartDate filter of 5 days prior to record startdates.
	//asOfDate = (DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).addMonths(1)).format('MM/dd/yyyy');
	//rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', '',
	//asOfDate, '', '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(0, rList.size(), 'Searching for records created after next month, these created today, dont find');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByBrand() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);
	//List<CBIUSCollectionsUtility.JSOption> brands = CBIUSCollectionsUtility.RetrieveBrands();
	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();

	////Brand - p123450
	//String brand ='p123450';
	//System.debug(LoggingLevel.INFO, 'brand: ' + brand);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', '',
	//'', brand, '', CBIUSCollectionsUtility.PKG);
	//System.assertEquals(1, rList.size(), 'Should find brand ');

	//Test.stopTest();
	//}

	//private static testmethod void TestSearchFeatureByPKG() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);
	//List<CBIUSCollectionsUtility.JSOption> brands = CBIUSCollectionsUtility.RetrieveBrands();

	////1 PKG Found
	//List<CBIUSCollectionsUtility.JSOption> skuPkgOptions  = 
	//CBIUSCollectionsUtility.RetrieveSkusOrPackages(brands[0].OptionId,CBIUSCollectionsUtility.PKG);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterPKGCode(accs[0].OptionId);

	//Test.startTest();

	////PKG 
	//String thePkg = skuPkgOptions[0].OptionId;
	//System.debug(LoggingLevel.INFO, 'package: ' + thePkg);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', '',
	//'', '', thePkg, CBIUSCollectionsUtility.PKG);
	//System.assertEquals(1, rList.size(), 'Should find package ');

	//Test.stopTest();
	//}
	//private static testmethod void TestSearchFeatureBySKU() {
	//Account pAcc = MakeAccountsAndProducts(2);
	//CBIUSCollectionsCtrlBase ctrl = SetupController();
	//List<CBIUSCollectionsUtility.JSOption> accs = CBIUSCollectionsUtility.findAccountsByParentAccountId(pAcc.Id);
	//List<CBIUSCollectionsUtility.JSOption> brands = CBIUSCollectionsUtility.RetrieveBrands();

	////1 SKU Found
	//List<CBIUSCollectionsUtility.JSOption> skuPkgOptions  = 
	//CBIUSCollectionsUtility.RetrieveSkusOrPackages(brands[0].OptionId,CBIUSCollectionsUtility.SKU);

	////Create 200 Item Auths for 1 subaccount.
	//TestUtil.createBulkValidFeatureMasterSKUCode(accs[0].OptionId);

	//Test.startTest();

	////sku 
	//String theSku = skuPkgOptions[0].OptionId;
	//System.debug(LoggingLevel.INFO, 'sku: ' + theSku);
	//List<CBIUSCollectionsUtility.SearchResultWrapper> rList =  CBIUSCollectionsUtility.searchItemAuthsFeatures(
	//(String)pAcc.Id,'', '',
	//new List<String>(), '', '', '', '',
	//'', '', theSku, CBIUSCollectionsUtility.SKU);
	//System.assertEquals(1, rList.size(), 'Should find package ');

	//Test.stopTest();
	//}
}