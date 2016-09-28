public with sharing class CBIUSCollectionsEditCtrl extends CBIUSCollectionsCtrlBase
{
	public String currentAuthFeatureId { get; set; }

	public ItemWrapper Wrapper { get; set; }

	public CBIUSCollectionsUtility.AccountHierarchy Hierarchy { get; set; }
	public List<CBIUSCollectionsUtility.JSOption> Brands { get; set; }
	public List<CBIUSCollectionsUtility.JSOption> SkusPackages { get; set; }

	public String BrandDisplay { get; set; }
	public String PkgSkuDisplay { get; set; }

	public String TDLinxCodesToAdd { get; set; }
	public String StoresToRemove { get; set; }

	//public CBI_US_Item_Authorization_Feature__c similar { get; set; }




	public CBIUSCollectionsEditCtrl() {
		//Set variables
		currentAuthFeatureId = ApexPages.currentPage().getParameters().get('cid');

		system.debug(currentAuthFeatureId);
		TDLinxCodesToAdd = '';
		StoresToRemove = '';
		//Validate querystring
		if (String.isBlank(currentAuthFeatureId)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'URL missing Auth/Feature Id, cannot continue.'));
			return;
		}
		//SOQL for Auth/Feature
		RefreshItem();
		//Build Sales Hierarchy options for SubAccounts, MarketingGroups, ReportTos.
		Hierarchy = CBIUSCollectionsUtility.RetrieveAccountHierarchy(Wrapper.Item.Ultimate_Parent__c);
		Brands = CBIUSCollectionsUtility.RetrieveBrands();

		//Based on BRAND_CD__c, find the display name.
		for (CBIUSCollectionsUtility.JSOption b : Brands) {
			if (b.OptionId == Wrapper.Item.BRAND_CD__c) {
				BrandDisplay = b.OptionLabel;
				break;
			}
		}
		//Determine if the Auth/Feat is SKU or Package oriented
		String pkgOrSku = '';
		String pkgOrSkuCode = '';
		if (!String.isEmpty(Wrapper.Item.MASTER_PKG_CD__c)) {
			pkgOrSku = CBIUSCollectionsUtility.PKG;
			pkgOrSkuCode = Wrapper.Item.MASTER_PKG_CD__c;
		}
		if (!String.isEmpty(Wrapper.Item.MASTER_SKU_CD__c)) {
			pkgOrSku = CBIUSCollectionsUtility.SKU;
			pkgOrSkuCode = Wrapper.Item.MASTER_SKU_CD__c;
		}
		//Retrieve the possible Pkgs/Skus and iterate them to find the correct Display. Keep in mind
		//there could be multiple codes for a given description, separated by |
		SkusPackages = CBIUSCollectionsUtility.RetrieveSkusOrPackages(Wrapper.Item.BRAND_CD__c, pkgOrSku);
		for (CBIUSCollectionsUtility.JSOption o : SkusPackages) {
			if (o.OptionId.contains(pkgOrSkuCode)) {
				PkgSkuDisplay = o.OptionLabel;
				break;
			}
		}

	}
	private void RefreshItem() {
		//Query for Feature/Auth and build wrapper to support UI
		CBI_US_Item_Authorization_Feature__c theItem = [SELECT Id, Add_all_Parent_Account_stores__c, Ultimate_Parent__c, Ultimate_Parent__r.Name, Name, RecordType.Name, RecordType.DeveloperName, TYPE_DSC__c, BRAND_CD__c, MASTER_PKG_CD__c, MASTER_SKU_CD__c, SET_PERIOD_BEGIN_DT_ID__c, SET_PERIOD_END_DT_ID__c, RESET_PERIOD_BEGIN_DT_ID__c, RESET_PERIOD_END_DT_ID__c, Sub_Accounts__c, States__c, Report_To_Codes__c, Marketing_Groups__c, NOTES_TXT__c, ON_MENU_FLG__c, NEW_SET_FLG__c, FEATURE_PRICE__c FROM CBI_US_Item_Authorization_Feature__c WHERE Id = :currentAuthFeatureId LIMIT 1];
		Wrapper = new ItemWrapper(theItem);
	}
	public PageReference CreateSimilar() {
	 System.debug('this is the developer name: ' + Wrapper.item.RecordType.DeveloperName);
		PageReference p;
		if (Wrapper.item.RecordType.DeveloperName == 'Item_Authorization') {
			p = Page.cbiusitemauthorizationcreate;
			
		} else {
			p = Page.cbiusfeaturecreate;
		}
		    p.getParameters().put('cid', Wrapper.item.id);
			p.setRedirect(true);
			return p;
	}
	public void SaveItem() {
		try {
			Wrapper.Item.SET_PERIOD_END_DT_ID__c = CBIUSCollectionsUtility.makeDate(Wrapper.EndDate);
			Wrapper.Item.RESET_PERIOD_BEGIN_DT_ID__c = CBIUSCollectionsUtility.makeDate(Wrapper.ResetStartDate);
			Wrapper.Item.RESET_PERIOD_END_DT_ID__c = CBIUSCollectionsUtility.makeDate(Wrapper.ResetEndDate);
			Wrapper.Item.NEW_SET_FLG__c = Wrapper.NewSet;
			Wrapper.Item.ON_MENU_FLG__c = Wrapper.OnMenu;
			Wrapper.Item.Sub_Accounts__c = Wrapper.SubAccountsDisplay;
			Wrapper.Item.Marketing_Groups__c = Wrapper.MarketingGroupsDisplay;
			Wrapper.Item.Report_To_Codes__c = Wrapper.ReportTosDisplay;
			Wrapper.Item.States__c = Wrapper.StatesDisplay;
			Wrapper.Item.FEATURE_PRICE__c = (Wrapper.Item.RecordType.DeveloperName == 'Feature' && !String.isBlank(Wrapper.Price)) ? Decimal.valueOf(Wrapper.Price) : null;
			Wrapper.Item.Add_all_Parent_Account_stores__c = Wrapper.AddAllParentsDisplay;
			update Wrapper.Item;
		} catch(System.DmlException dmle) {
			ApexPages.addMessages(dmle);
		} catch(Exception e) {
			ApexPages.addMessages(e);
		}
	}
	public void EndItemToday() {
		try {
			Wrapper.Item.SET_PERIOD_END_DT_ID__c = Date.today();
			update Wrapper.Item;
		} catch(System.DmlException dmle) {
			ApexPages.addMessages(dmle);
		} catch(Exception e) {
			ApexPages.addMessages(e);
		}
	}
	public void SaveStoresByTDLinxCodes() {
		Set<String> requestedTDLinx = new Set<String> ();
		Set<String> foundTDLinxCodes = new Set<String> ();
		List<Account_Auth_Feature__c> stores = new List<Account_Auth_Feature__c> ();
		Boolean isError = false;

		//Validate
		if (String.isBlank(TDLinxCodesToAdd)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please supply at least 1 TDLinx Submission Code.'));
			TDLinxCodesToAdd = '';
			return;
		}
		List<String> tdLinxCodes = TDLinxCodesToAdd.split(',');
		if (tdLinxCodes.size() < 1) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please supply at least 1 TDLinx Submission Code.'));
			TDLinxCodesToAdd = '';
			return;
		}
		//Remember which TDLinx were requested in a set.
		requestedTDLinx.addAll(tdLinxCodes);

		//Find Accounts that match TDLinx Code (Store_Code__c)		
		for (Account a :[SELECT Id, Store_Code__c FROM Account WHERE Parent.Id = :Wrapper.Item.Ultimate_Parent__c AND Store_Code__c IN :tdLinxCodes]) {
			//Create junction record
			stores.add(new Account_Auth_Feature__c(Account__c = a.Id, CBI_US_Item_Authorization_Feature__c = currentAuthFeatureId));
			//Remember the TDLinx was found.
			foundTDLinxCodes.add(a.Store_Code__c);
		}
		//Validate stores found
		if (foundTDLinxCodes.size() < 1) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Stores matched your TDLinx Submission Code(s).'));
			TDLinxCodesToAdd = '';
			return;
		}
		if (foundTDLinxCodes.size() != requestedTDLinx.size()) {
		System.debug('this is the found code: ' + foundTDLinxCodes);
		System.debug('this is the requested code: ' + requestedTDLinx);
			isError = true;
			String msg = 'The following TDLinx Codes were not found: ';
			List<String> tmpNotFound = new List<String> ();
			for (String s : requestedTDLinx) {
				if (!foundTDLinxCodes.contains(s)) {
					tmpNotFound.add(s);
				}
			}
			msg += String.join(tmpNotFound, ', ');
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, msg));
		}

		//Use Database class Insert to allow partial save
		Integer foundCount = stores.size();
		Integer successResults = 0;
		Integer failures = 0;
		Database.SaveResult[] results = Database.insert(stores, false);
		for (Database.SaveResult sr : results) {
			if (sr.isSuccess()) {
				successResults++;
			} else {
				failures++;
				IsError = true;
				for (Database.Error err : sr.getErrors()) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.getMessage()));
				}
			}
		}
		if (successResults != foundCount || IsError == true) {
			String msg2 = 'Store(s) attempted: ' + foundCount + ', Store(s) add succesfully: ' + successResults + ', Store(s) failed: ' + failures;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg2));
		}
		//Clear out TDLinx Codes		
		TDLinxCodesToAdd = '';
		return;
	}
	public void RemoveStores() {
		Boolean IsError = false;
		Integer successResults = 0;
		Integer failures = 0;
		if (String.isBlank(StoresToRemove)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose at least one store to remove.'));
			StoresToRemove = '';
			return;
		}
		List<String> removeIds = StoresToRemove.split(',');
		List<Account_Auth_Feature__c> recs = new List<Account_Auth_Feature__c> ();
		try {
			for (String s : removeIds) {
				recs.add(new Account_Auth_Feature__c(Id = Id.valueOf(s.trim())));
			}
			Database.DeleteResult[] results = Database.delete(recs, false);
			for (Database.DeleteResult sr : results) {
				if (sr.isSuccess()) {
					successResults++;
				} else {
					failures++;
					IsError = true;
					for (Database.Error err : sr.getErrors()) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.getMessage()));
					}
				}
			}
			if (successResults != removeIds.size() || IsError == true) {
				String msg2 = 'Store(s) to be removed: ' + removeIds.size() + ', Store(s) removed succesfully: ' + successResults + ', Store(s) failed: ' + failures;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg2));
			}
		} catch(System.DmlException dmle) {
			ApexPages.addMessages(dmle);
		} catch(Exception e) {
			ApexPages.addMessages(e);
		}
		StoresToRemove = '';
	}

	public class SuccessErrorResponse {
		public List<String> SuccessMsgs { get; set; }
		public List<String> ErrorMsgs { get; set; }
		public SuccessErrorResponse() {
			SuccessMsgs = new List<String> ();
			ErrorMsgs = new List<String> ();
		}
	}

	public class ItemWrapper {
		public CBI_US_Item_Authorization_Feature__c Item { get; set; }
		public String StartDate { get; set; }
		public String EndDate { get; set; }
		public String ResetStartDate { get; set; }
		public String ResetEndDate { get; set; }
		public String NewSet { get; set; }
		public String OnMenu { get; set; }
		public String Price { get; set; }
		public String SubAccountsDisplay { get; set; }
		public String MarketingGroupsDisplay { get; set; }
		public String ReportTosDisplay { get; set; }
		public String StatesDisplay { get; set; }
		public Boolean AddAllParentsDisplay { get; set; }

		public ItemWrapper(CBI_US_Item_Authorization_Feature__c i) {
			this.Item = i;
			this.StartDate = GetDateStringOrSpace(i.SET_PERIOD_BEGIN_DT_ID__c);
			this.EndDate = GetDateStringOrSpace(i.SET_PERIOD_END_DT_ID__c);
			this.ResetStartDate = GetDateStringOrSpace(i.RESET_PERIOD_BEGIN_DT_ID__c);
			this.ResetEndDate = GetDateStringOrSpace(i.RESET_PERIOD_END_DT_ID__c);
			this.NewSet = GetBoolValueOrNo(i.NEW_SET_FLG__c);
			this.OnMenu = GetBoolValueOrNo(i.ON_MENU_FLG__c);
			this.SubAccountsDisplay = TurnPipeDelimitedToStringOrSpace(i.Sub_Accounts__c);
			this.MarketingGroupsDisplay = TurnPipeDelimitedToStringOrSpace(i.Marketing_Groups__c);
			this.ReportTosDisplay = TurnPipeDelimitedToStringOrSpace(i.Report_To_Codes__c);
			this.StatesDisplay = TurnPipeDelimitedToStringOrSpace(i.States__c);
			this.Price = i.FEATURE_PRICE__c != null ? i.FEATURE_PRICE__c.format() : '';
			this.AddAllParentsDisplay = i.Add_all_Parent_Account_stores__c;
		}



		public String GetDateStringOrSpace(Date d) {
			if (d != null) {
				return d.format();
			}
			return 'None';
		}
		public String GetBoolValueOrNo(String s) {
			if (!String.isBlank(s)) {
				return s;
			}
			return 'No';
		}
		public String TurnPipeDelimitedToStringOrSpace(String s) {
			if (!String.isBlank(s)) {
				List<String> values = s.split('\\|');
				return String.join(values, ', ');
			}
			return 'None';
		}
		
	}
}