public class CBIUSCollectionsCreateCtrl extends CBIUSCollectionsCtrlBase {
	public ID rtId { get; set; }
	public CBI_US_Item_Authorization_Feature__c iaFet { get; Set; }
	public List<CBIUSCollectionsUtility.JSOption> Brands { get; set; }
	public string rt { get; set; }
	//public Account acct { get; set; }
	public Set<String> reportToCode;
	public id UltimateAccount { get; set; }
	public String currentAuthFeatureId { get; set; }
//	public CBI_US_Item_Authorization_Feature__c itemToClone { get; set; }
	public string cloneNote { get; set; }
	public string startDate { get; set; }
	public string endDate { get; set; }
	public string resetStartDate { get; set; }
	public string resetEndDate { get; set; }
	public string newSet { get; set; }
	public string onMenu { get; set; }
	public Decimal Price { get; set; }
	public String SubAccountsDisplay { get; set; }
	public String MarketingGroupsDisplay { get; set; }
	public String ReportTosDisplay { get; set; }
	public String StatesDisplay { get; set; }
	public String typeCode { get; set; }
	//public String brandCode { get; set; }
	public String skuCode { get; set; }
	public String pkgCode { get; set; }
	public String BrandNumber { get; set; }
	public String ultimateParent { get; set; }
	public String ultimateParentID { get; set; }
	public String pkgOrSkuCode { get; set; }
	public List<CBIUSCollectionsUtility.JSOption> PreloadedSkuPkgs { get; set; }
	

	//This method is used to get the recordtype f
	public string loadRecordType {
		get {
			makePageRecordType();
			return '';
		}
	}
	public CBIUSCollectionsCreateCtrl() {
		currentAuthFeatureId = ApexPages.currentPage().getParameters().get('cid');

		Brands = new LIst<CBIUSCollectionsUtility.JSOption> ();
		Brands.add(new CBIUSCollectionsUtility.JSOption('', 'Please Select'));
		Brands.addAll(CBIUSCollectionsUtility.RetrieveBrands());

		if (!String.isblank(currentAuthFeatureId)) {
			RefreshItem();

			iaFet.Id = null;
			cloneNote = iafet.NOTES_TXT__c;
			startDate = FormatDateToString(iafet.SET_PERIOD_BEGIN_DT_ID__c);
			endDate = FormatDateToString(iafet.SET_PERIOD_END_DT_ID__c);
			resetStartDate = FormatDateToString(iafet.RESET_PERIOD_BEGIN_DT_ID__c);
			resetEndDate = FormatDateToString(iafet.RESET_PERIOD_END_DT_ID__c);
			newSet = iaFet.NEW_SET_FLG__c;
			onMenu = iaFet.ON_MENU_FLG__c;
			typeCode = iaFet.Type_CD__c;
			SubAccountsDisplay = TurnPipeDelimitedToStringOrSpace(iaFet.Sub_Accounts__c);
			MarketingGroupsDisplay = TurnPipeDelimitedToStringOrSpace(iaFet.Marketing_Groups__c);
			ReportTosDisplay = TurnPipeDelimitedToStringOrSpace(iaFet.Report_To_Codes__c);
			StatesDisplay = TurnPipeDelimitedToStringOrSpace(iaFet.States__c);
			skuCode = iaFet.MASTER_SKU_CD__c;
			pkgCode = iaFet.MASTER_PKG_CD__c;
			ultimateParent = iaFet.Ultimate_Parent__r.Name;
			ultimateParentID = iaFet.Ultimate_Parent__c;
			BrandNumber = iaFet.BRand_CD__C;
			price = iaFet.FEATURE_PRICE__c;

			String pkgOrSku = 'PKG';
			pkgOrSkuCode = '';
			if (!String.isEmpty(iaFet.MASTER_PKG_CD__c)) {
				pkgOrSku = 'PKG';
				pkgOrSkuCode = iaFet.MASTER_PKG_CD__c;
			}
			if (!String.isEmpty(iaFet.MASTER_SKU_CD__c)) {
				pkgOrSku = 'SKU';
				pkgOrSkuCode = iaFet.MASTER_SKU_CD__c;
			}


			PreloadedSkuPkgs = new LIst<CBIUSCollectionsUtility.JSOption> ();
			PreloadedSkuPkgs.add(new CBIUSCollectionsUtility.JSOption('', 'Please Select'));
			PreloadedSkuPkgs.addAll(CBIUSCollectionsUtility.RetrieveSkusOrPackages(iaFet.BRAND_CD__c, pkgOrSku));

		}
	}
	public void makePageRecordType() {
		rtID = Schema.SObjectType.CBI_US_Item_Authorization_Feature__c.getRecordTypeInfosByName().get(rt).getRecordTypeId();
		iaFet = new CBI_US_Item_Authorization_Feature__c();
		iaFet.RecordTypeID = rtID;
	}
	private void RefreshItem() {
		//Query for Feature/Auth and build wrapper to support UI
		iaFet = [SELECT Id, Add_all_Parent_Account_stores__c, Type_CD__c, Ultimate_Parent__c, Ultimate_Parent__r.Name, Name, RecordType.Name, RecordType.DeveloperName, TYPE_DSC__c, BRAND_CD__c, MASTER_PKG_CD__c, MASTER_SKU_CD__c, SET_PERIOD_BEGIN_DT_ID__c, SET_PERIOD_END_DT_ID__c, RESET_PERIOD_BEGIN_DT_ID__c, RESET_PERIOD_END_DT_ID__c, Sub_Accounts__c, States__c, Report_To_Codes__c, Marketing_Groups__c, NOTES_TXT__c, ON_MENU_FLG__c, NEW_SET_FLG__c, FEATURE_PRICE__c FROM CBI_US_Item_Authorization_Feature__c WHERE Id = :currentAuthFeatureId LIMIT 1];
	}
	public String FormatDateToString(Date theDate) {
		if (theDate == null) { return ''; }
		return DateTime.newInstance(theDate.year(),
		                            theDate.month(),
		                            theDate.day()).format('MM/dd/yyyy');
	}
	public String TurnPipeDelimitedToStringOrSpace(String s) {
		if (!String.isBlank(s)) {
			List<String> values = s.split('\\|');
			return String.join(values, ', ');
		}
		return 'None';
	}
	public PageReference done() {

		PageReference p;
		try {
			insert(iaFet);
			p = Page.CBIUSItemAuthorizationEdit;
			p.setredirect(true);
			p.getParameters().put('cid', iaFet.id);
			return p;
		} catch(System.DMLException e) {
			ApexPages.addMessages(e);
			return null;
		}
		return p;
	}

	public PageReference cancelCollection() {
		return null;
	}
}