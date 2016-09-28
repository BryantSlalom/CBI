public class CBIUSCollectionsUtility {

	public CBIUSCollectionsUtility() { }
	public CBIUSCollectionsUtility(CBIUSCollectionsCtrlBase ctrl) { }

	//Private
	private static final String[] BeverageCodes = new List<String> { '101' }; //Beer products only, not wine, etc.
	public static String SKU = 'SKU'; //Corresponds to Radio button values
	public static String PKG = 'PKG'; //Corresponds to Radio button values
	public static String Auth_RecordType = 'Item_Authorization';
	public static String Feature_RecordType = 'Feature';

	@RemoteAction
	public static List<SelectOption> LoadStatesForUSA() {
		List<SelectOption> States = new List<SelectOption> ();

		// Find all the states we have in custom settings.
		Map<String, Country_State__c> allstates = Country_State__c.getAll();

		// Filter states that belong to USA
		Map<String, Country_State__c> statesMap = new Map<String, Country_State__c> ();
		for (Country_State__c state : allstates.values()) {
			if (state.Country__c == 'USA') {
				statesMap.put(state.name, state);
			}
		}

		// Sort the states based on their names
		List<String> stateNames = new List<String> ();
		stateNames.addAll(statesMap.keySet());
		stateNames.sort();

		// Generate the Select Options based on the final sorted list
		//States.add(new SelectOption('','Please Select'));
		for (String stateName : stateNames) {
			Country_State__c state = statesMap.get(stateName);
			States.add(new SelectOption(state.name, state.name));
		}
		return States;
	}

	@RemoteAction
	public static List<JSOption> RetrieveBrands() {
		set<String> masterBrandCodes = new Set<String> ();
		List<JSOption> Brands = new List<JSOption> ();

		//Query for all Beer CBI Products (Bev Seg Code = 101)
		//Find unique Brand codes for Brand dropdown, use a Set for uniqueness.    
		for (CBI_US_Product__c p :[SELECT Id, BRAND_DSC__c, BRAND_CD__c, MASTER_PKG_CD__c, MASTER_PKG_DSC__c, MASTER_SKU_CD__c, MASTER_SKU_DSC__c
		     FROM CBI_US_Product__c
		     WHERE BEV_SEG_CD__c IN :BeverageCodes
		     ORDER BY BRAND_DSC__c ASC]) {

			if (!masterBrandCodes.contains(p.BRAND_CD__c)) {
				//Add it to the master set for later use, but also create Brand Dropdown option.
				masterBrandCodes.add(p.BRAND_CD__c);
				Brands.add(new JSOption(p.BRAND_CD__c, p.BRAND_DSC__c));
			}
		}
		return Brands;
	}

	@RemoteAction
	public static List<JSOption> RetrieveSkusOrPackages(String brandCode, String pkgOrSku) {
		List<CBI_US_Product__c> prods = new List<CBI_US_Product__c> ();
		Set<String> uniqueDescriptions = new Set<String> ();
		Map<String, Set<String>> descriptionsToCodes = new Map<String, Set<String>> ();
		List<JSOption> options = new List<JSOption> ();

		//Validate parameters
		if (String.isEmpty(brandCode) || String.isEmpty(pkgOrSku)) {
			return options;
		}

		//Package SOQL
		if (pkgOrSku == PKG) {
			prods = [SELECT Id, BRAND_DSC__c, BRAND_CD__c, MASTER_PKG_CD__c, MASTER_PKG_DSC__c, MASTER_SKU_CD__c, MASTER_SKU_DSC__c
			         FROM CBI_US_Product__c
			         WHERE BEV_SEG_CD__c IN :BeverageCodes AND BRAND_CD__c = :brandCode AND MASTER_PKG_CD__c != null AND MASTER_PKG_DSC__c != null
			         ORDER BY MASTER_PKG_CD__c DESC];
		}
		//SKU SOQL
		if (pkgOrSku == SKU) {
			prods = [SELECT Id, BRAND_DSC__c, BRAND_CD__c, MASTER_PKG_CD__c, MASTER_PKG_DSC__c, MASTER_SKU_CD__c, MASTER_SKU_DSC__c
			         FROM CBI_US_Product__c
			         WHERE BEV_SEG_CD__c IN :BeverageCodes AND BRAND_CD__c = :brandCode AND MASTER_SKU_CD__c != null AND MASTER_SKU_DSC__c != null
			         ORDER BY MASTER_SKU_CD__c DESC];
		}

		//Iterate products to find unique Descriptions. Multiple CBI Product records can 'share' the same Description but have different
		//Codes. We only want the Description to show up once in the Dropdown, but when we search for Item Auths, we want it to use all the Codes for that 
		//Description. We'll use a | character in the Value of the option and later Split it into array for searching.
		for (CBI_US_Product__c p : prods) {

			String theDescription = '';
			String theCode = '';

			if (pkgOrSku == PKG) {
				theDescription = p.MASTER_PKG_DSC__c;
				theCode = p.MASTER_PKG_CD__c;
			} else if (pkgOrSku == SKU) {
				theDescription = p.MASTER_SKU_DSC__c;
				theCode = p.MASTER_SKU_CD__c;
			}

			//Do we not have the description yet?
			if (!uniqueDescriptions.contains(theDescription)) {
				//Add it.
				uniqueDescriptions.add(theDescription);
				//Also create a Map to store all the Codes for that Description.
				descriptionsToCodes.put(theDescription, new Set<String> ());
			}
			//Does that Description's set not contain that Code yet?
			if (!descriptionsToCodes.get(theDescription).contains(theCode)) {
				descriptionsToCodes.get(theDescription).add(theCode);
			}
		}

		//Now iterate all the Maps we created, and build their JSOption. Some may need | concatenation.
		for (String descKey : descriptionsToCodes.keySet()) {
			List<String> iterableCodes = new List<String> ();
			iterableCodes.addAll(descriptionsToCodes.get(descKey));
			String codesConcatenated = String.join(iterableCodes, '|');
			options.add(new JSOption(codesConcatenated, descKey));
		}
		return options;
	}

	

	@RemoteAction
	public static AccountHierarchy RetrieveAccountHierarchy(String ultAccId) {
		AccountHierarchy h = new AccountHierarchy();
		Set<String> subs = new Set<String> ();
		Set<String> mgroups = new Set<String> ();
		Set<String> repTos = new Set<String> ();
		if (String.isBlank(ultAccId)) {
			return h;
		}

		h.UltimateAccountId = ultAccId;

		for (Account a :[SELECT Id, RMA__c, Marketing_Group__c, SUBACCOUNT_DSC__c FROM Account WHERE ParentId = :ultAccId]) {
			if (!String.isBlank(a.SUBACCOUNT_DSC__c)) {
				subs.add(a.SUBACCOUNT_DSC__c);
			}
			if (!String.isBlank(a.RMA__c)) {
				repTos.add(a.RMA__c);
			}
			if (!String.isBlank(a.Marketing_Group__c)) {
				mgroups.add(a.Marketing_Group__c);
			}
		}

		//Add sets to Lists and sort them.
		if (subs.size() > 0) {
			h.SubAccounts.addAll(subs);
			h.SubAccounts.sort();
		}
		if (repTos.size() > 0) {
			h.ReportToCodes.addAll(repTos);
			h.ReportToCodes.sort();
		}
		if (mgroups.size() > 0) {
			h.MarketingGroups.addAll(mgroups);
			h.MarketingGroups.sort();
		}
		return h;
	}

	public static Date makeDate(String sDate) {
		//  MM/DD/YYYY
		System.debug('mm/dd/yyyy: ' + sDate);
		if (!String.isBlank(sDate) && sDate.contains('/')) {
			String[] mmddyy = sDate.split('/');
			System.debug('array: ' + mmddyy);
			if (mmddyy.size() == 3) {
				System.debug('array has 3 parts');
				return Date.newInstance(Integer.valueOf((mmddyy[2])), Integer.valueOf(mmddyy[0]), Integer.valueOf(mmddyy[1]));
			}
		}
		return null;
	}
	

	@RemoteAction
	public static List<SearchResultWrapper> searchItemAuthsFeatures(String authOrFeature, String accId, String subAccDesc,
	                                                                String[] states, String startDate, String endDate, String resetStartDate, String resetEndDate,
	                                                                String newStoreDate, String brandId, String pkgSkuId, String pkgSkuRadio) {

		//public static List<SearchResultWrapper> searchItemAuths(String accId, String subAccId,
		//String[] states, String startDate, String endDate, String resetStartDate, String resetEndDate,
		//String newStoreDate, String brandId, String pkgSkuId, String pkgSkuRadio)


		String q = 'SELECT Id,Account__c,CBI_US_Item_Authorization_Feature__c,';
		q += 'CBI_US_Item_Authorization_Feature__r.Name,CBI_US_Item_Authorization_Feature__r.SET_PERIOD_BEGIN_DT_ID__c,';
		q += 'CBI_US_Item_Authorization_Feature__r.SET_PERIOD_END_DT_ID__c,CBI_US_Item_Authorization_Feature__r.RESET_PERIOD_BEGIN_DT_ID__c,CBI_US_Item_Authorization_Feature__r.RESET_PERIOD_END_DT_ID__c,';
		q += 'Account__r.Name,Account__r.Store_Number_EDW__c,Account__r.BillingState,Account__r.BillingPostalCode,';
		q += 'Account__r.Parent.Id,Account__r.Parent.Name,Account__r.Store_Code__c,Account__r.SUBACCOUNT_DSC__c,';
		q += 'CBI_US_Item_Authorization_Feature__r.BRAND_CD__c,CBI_US_Item_Authorization_Feature__r.MASTER_PKG_CD__c,CBI_US_Item_Authorization_Feature__r.MASTER_SKU_CD__c,Account__r.CreatedDate';
		q += ',CBI_US_Item_Authorization_Feature__r.RecordType.DeveloperName';

		//FROM
		q += ' FROM Account_Auth_Feature__c ';

		//WHERE
		String qWhere = ' WHERE ';

		//Always filter by Ultimate Account
		qWhere += ' Account__r.Parent.Id =\'' + accId + '\' ';

		//Search by a single SubAccount or all SubAccounts.
		//TODO Chang t
		if (!String.isEmpty(subAccDesc)) {
			//Search by single SubAccount
			qWhere += 'AND CBI_US_Item_Authorization_Feature__r.Sub_Accounts__c LIKE \'%' + subAccDesc + '%\' ';
		}

		//Record Type - Item Auth vs Feature
		if (authOrFeature == 'IA') {
			qWhere += ' AND CBI_US_Item_Authorization_Feature__r.RecordType.DeveloperName = :Auth_RecordType';
		} else {
			qWhere += ' AND CBI_US_Item_Authorization_Feature__r.RecordType.DeveloperName = :Feature_RecordType';
		}

		//States Search
		if (states != null && states.size() > 0) {
			for (String st : states) {
				qWhere += ' AND CBI_US_Item_Authorization_Feature__r.States__c LIKE \'%' + st + '%\' ';
			}
		}

		//SkuPkg preceeds Brand, no need to search bo both.
		if (!String.isEmpty(pkgSkuId)) {
			//Split the pkgSkuId (which could have ids delimited by | char) into array.
			String[] pkgSkuArray = pkgSkuId.split('\\|');
			if (pkgSkuRadio == PKG) {
				qWhere += ' AND CBI_US_Item_Authorization_Feature__r.MASTER_PKG_CD__c IN :pkgSkuArray ';
			} else {
				qWhere += ' AND CBI_US_Item_Authorization_Feature__r.MASTER_SKU_CD__c IN :pkgSkuArray ';
			}
		} else if (!String.isEmpty(brandId)) {
			//qWhere += ' AND BRAND_CD__c = :brandId ';
			//Work around because Item Auths dont have Brand_Cd__c populated.
			String wildCardBrand = '%' + brandId + '%';
			qWhere += ' AND (CBI_US_Item_Authorization_Feature__r.MASTER_PKG_CD__c LIKE :wildCardBrand OR CBI_US_Item_Authorization_Feature__r.MASTER_SKU_CD__c LIKE :wildCardBrand) ';
		}

		//StartDate & EndDate  
		System.debug(LoggingLevel.Info, 'StartDate: ' + startDate);
		System.debug(LoggingLevel.Info, 'EndDate: ' + endDate);
		System.debug(LoggingLevel.Info, 'RestStartDate: ' + resetStartDate);
		System.debug(LoggingLevel.Info, 'RestEndDate: ' + resetEndDate);
		System.debug(LoggingLevel.Info, 'NewAsOf: ' + newStoreDate);
		Date sDate;
		Date eDate;
		Date resetsDate;
		Date reseteDate;
		Date nDate;
		if (!String.isEmpty(startDate) && !String.isEmpty(endDate)) {
			sDate = makeDate(startDate);
			eDate = makeDate(endDate);
			System.debug(LoggingLevel.Info, 's and e: ' + sDate + ' ' + eDate);
			qWhere += ' AND (CBI_US_Item_Authorization_Feature__r.SET_PERIOD_BEGIN_DT_ID__c >= :sDate AND CBI_US_Item_Authorization_Feature__r.SET_PERIOD_END_DT_ID__c <= :eDate ) ';
		} else if (!String.isEmpty(startDate)) {
			sDate = makeDate(startDate);
			System.debug(LoggingLevel.Info, 's: ' + sDate);
			qWhere += ' AND (CBI_US_Item_Authorization_Feature__r.SET_PERIOD_BEGIN_DT_ID__c >= :sDate AND (CBI_US_Item_Authorization_Feature__r.SET_PERIOD_END_DT_ID__c=null OR CBI_US_Item_Authorization_Feature__r.SET_PERIOD_END_DT_ID__c >= :sDate ) ) ';
		} else if (!String.isEmpty(endDate)) {
			eDate = makeDate(endDate);
			System.debug(LoggingLevel.Info, 'e: ' + eDate);
			qWhere += ' AND (CBI_US_Item_Authorization_Feature__r.SET_PERIOD_BEGIN_DT_ID__c <= :eDate AND CBI_US_Item_Authorization_Feature__r.SET_PERIOD_END_DT_ID__c <= :eDate) ';
		} else { }

		//ResetStartDate & ResetEndDate    
		if (!String.isEmpty(resetStartDate) && !String.isEmpty(resetEndDate)) {
			resetsDate = makeDate(resetStartDate);
			reseteDate = makeDate(resetEndDate);
			qWhere += ' AND (CBI_US_Item_Authorization_Feature__r.RESET_PERIOD_BEGIN_DT_ID__c >= :resetsDate AND CBI_US_Item_Authorization_Feature__r.RESET_PERIOD_END_DT_ID__c <= :reseteDate ) ';
		} else if (!String.isEmpty(resetStartDate)) {
			resetsDate = makeDate(resetStartDate);
			qWhere += ' AND (CBI_US_Item_Authorization_Feature__r.RESET_PERIOD_BEGIN_DT_ID__c >= :resetsDate AND (CBI_US_Item_Authorization_Feature__r.RESET_PERIOD_END_DT_ID__c=null OR CBI_US_Item_Authorization_Feature__r.RESET_PERIOD_END_DT_ID__c >= :resetsDate ) ) ';
		} else if (!String.isEmpty(resetEndDate)) {
			reseteDate = makeDate(resetEndDate);
			qWhere += ' AND (CBI_US_Item_Authorization_Feature__r.RESET_PERIOD_BEGIN_DT_ID__c <= :reseteDate AND CBI_US_Item_Authorization_Feature__r.RESET_PERIOD_END_DT_ID__c <= :reseteDate) ';
		} else { }

		//New Store As Of - any SubAccount.CreatedDate ON OR AFTER user input
		if (!String.isEmpty(newStoreDate)) {
			nDate = makeDate(newStoreDate);
			qWhere += ' AND (Account__r.CreatedDate >= :nDate ) ';
		}

		//Query the results, and then find the PKG/SKU/BRAND Description for table results.
		q += qWhere;
		q += ' LIMIT 15000 ';
		System.debug(LoggingLevel.Info, 'Query: ' + q);
		System.debug(LoggingLevel.Info, 'QueryLength: ' + q.length());
		List<SearchResultWrapper> auths = new List<SearchResultWrapper> ();
		Set<String> skuPkgSet = new Set<String> ();
		Set<String> brandSet = new Set<String> ();
		System.debug('Junction Limits before loop' + Limits.getHeapSize() + ' Heap Size used against Limits: ' + Limits.getLimitHeapSize());

		for (List<sObject> results : Database.query(q)) {
			for (sObject s : results) {
				SearchResultWrapper w = new SearchResultWrapper((Account_Auth_Feature__c) s);
				System.debug('Inside Junction for loop ' + Limits.getHeapSize() + ' Heap Size used against Limits: ' + Limits.getLimitHeapSize());
				//If user specifically chose a Sku/Pkg, then be precise in finding that Description.
				//Otherwise, cast a wide net to avoid missing some Descriptions. (add Pkg & Sku)
				if (!String.isEmpty(pkgSkuId)) {
					if (pkgSkuRadio == PKG && !String.isEmpty(w.MasterPkgCode)) {
						skuPkgSet.add(w.MasterPkgCode);
					} else if (pkgSkuRadio == SKU && !String.isEmpty(w.MasterSkuCode)) {
						skuPkgSet.add(w.MasterSkuCode);
					}
				} else {
					if (!String.isEmpty(w.MasterPkgCode)) {
						skuPkgSet.add(w.MasterPkgCode);
					}
					if (!String.isEmpty(w.MasterSkuCode)) {
						skuPkgSet.add(w.MasterSkuCode);
					}
				}
				auths.add(w);
			}
		}
		System.debug('Junction Limits after loop' + Limits.getHeapSize() + ' Heap Size used against Limits: ' + Limits.getLimitHeapSize());

		Map<String, String> codeToDescription = new Map<String, String> ();
		List<CBI_US_Product__c> prods = new List<CBI_US_Product__c> ();
		String prodQ = 'SELECT Id, BRAND_DSC__c, BRAND_CD__c, MASTER_PKG_CD__c, MASTER_PKG_DSC__c, MASTER_SKU_CD__c, MASTER_SKU_DSC__c ';
		prodQ += ' FROM CBI_US_Product__c ';
		prodQ += ' WHERE MASTER_PKG_CD__c IN :skuPkgSet OR  MASTER_SKU_CD__c IN :skuPkgSet ';

		//prods = (List<CBI_US_Product__c>) Database.query(prodQ);
		System.debug('Product Limits before loop' + Limits.getHeapSize() + ' Heap Size used against Limits: ' + Limits.getLimitHeapSize());
		for (List<sObject> products : Database.query(prodQ)) {
			for (sObject p : products) {
				CBI_US_Product__c theProd = (CBI_US_Product__c) p;
				prods.add(theProd);
				String code = '';
				String description = '';
				if (!String.isEmpty(theProd.MASTER_PKG_CD__c) && !codeToDescription.containsKey(theProd.MASTER_PKG_CD__c)) {
					codeToDescription.put(theProd.MASTER_PKG_CD__c, theProd.MASTER_PKG_DSC__c);
				}
				if (!String.isEmpty(theProd.MASTER_SKU_CD__c) && !codeToDescription.containsKey(theProd.MASTER_SKU_CD__c)) {
					codeToDescription.put(theProd.MASTER_SKU_CD__c, theProd.MASTER_SKU_DSC__c);
				}
			}
		}
		System.debug('Product Limits after loop' + Limits.getHeapSize() + ' Heap Size used against Limits: ' + Limits.getLimitHeapSize());

		//Iterate all the Auths and update the Description.
		for (SearchResultWrapper w : auths) {
			//If user was specific about Sku/Pkg, be sure to use that.
			if (!String.isEmpty(pkgSkuId)) {
				if (pkgSkuRadio == PKG) {
					w.PkgSkuDescription = codeToDescription.get(w.MasterPkgCode);
				} else {
					w.PkgSkuDescription = codeToDescription.get(w.MasterSkuCode);
				}
			} else {
				//Simply try to find it using Package first, Sku second.
				if (!String.isEmpty(w.MasterPkgCode) &&
				    codeToDescription.containsKey(w.MasterPkgCode)) {
					w.PkgSkuDescription = codeToDescription.get(w.MasterPkgCode);
				} else if (!String.isEmpty(w.MasterSkuCode) &&
				           codeToDescription.containsKey(w.MasterSkuCode)) {
					w.PkgSkuDescription = codeToDescription.get(w.MasterSkuCode);
				}
			}
			if (String.isEmpty(w.PkgSkuDescription)) { w.PkgSkuDescription = ''; }
		}
		return auths;
	}


	@RemoteAction
	public static List<Account_Auth_Feature__c> FindStoresByItemId(String authFeatureId) {
		return[SELECT Id, Name, Account__c, Account__r.Name, Account__r.TDLinx_ID__c, Account__r.Store_Number_EDW__c, Account__r.Store_Code__c, Account__r.BillingStreet, Account__r.BillingCity, Account__r.BillingState FROM Account_Auth_Feature__c WHERE CBI_US_Item_Authorization_Feature__c = : authFeatureId];
	}



	public class JSOption {
		public String OptionId { get; set; }
		public String OptionLabel { get; set; }
		public Boolean IsSelected { get; set; }
		public JSOption(String theId, String theLabel) {
			OptionId = theId;
			OptionLabel = theLabel;
		}
	}

	public class AccountHierarchy {
		public ID UltimateAccountId { get; set; }
		public List<String> SubAccounts { get; set; }
		public List<String> MarketingGroups { get; set; }
		public List<String> ReportToCodes { get; set; }
		public AccountHierarchy() {
			SubAccounts = new List<String> ();
			MarketingGroups = new List<String> ();
			ReportToCodes = new List<String> ();
		}
	}

	public class SearchResultWrapper {
		public String Id { get; set; }
		public String AuthFeatId { get; set; }
		public String Name { get; set; }
		public String AccountName { get; set; }
		public String SubAccountName { get; set; }
		public String StartDate { get; set; }
		public String EndDate { get; set; }
		public String TDLinxSubCode { get; set; }
		public String Store { get; set; }
		public String State { get; set; }
		public String ZIP { get; set; }
		public String MasterPkgCode { get; set; }
		public String MasterSkuCode { get; set; }
		public String MasterBrandCode { get; set; }
		public String PkgSkuDescription { get; set; }
		public JSOption RedirectEditLink { get; set; }

		public String FormatDateToString(Date theDate) {
			if (theDate == null) { return ''; }
			return DateTime.newInstance(theDate.year(),
			                            theDate.month(),
			                            theDate.day()).format('MM/dd/yyyy');
		}

		public SearchResultWrapper() { }
		public SearchResultWrapper(Account_Auth_Feature__c item) {
			this.Id = item.Id;
			this.AuthFeatId = item.CBI_US_Item_Authorization_Feature__c;
			this.Name = item.CBI_US_Item_Authorization_Feature__r.Name;
			this.SubAccountName = !String.isBlank(item.Account__r.SUBACCOUNT_DSC__c) ? item.Account__r.SUBACCOUNT_DSC__c : '';
			this.AccountName = item.Account__r.Parent.Name;
			this.StartDate = FormatDateToString(item.CBI_US_Item_Authorization_Feature__r.SET_PERIOD_BEGIN_DT_ID__c);
			this.EndDate = FormatDateToString(item.CBI_US_Item_Authorization_Feature__r.SET_PERIOD_END_DT_ID__c);
			this.TDLinxSubCode = !String.isBlank(item.Account__r.Store_Code__c) ? item.Account__r.Store_Code__c : '';
			this.Store = !String.isBlank(item.Account__r.Store_Number_EDW__c) ? item.Account__r.Store_Number_EDW__c : '';
			this.State = !String.isBlank(item.Account__r.BillingState) ? item.Account__r.BillingState : '';
			this.ZIP = !String.isBlank(item.Account__r.BillingPostalCode) ? item.Account__r.BillingPostalCode : '';
			this.MasterPkgCode = item.CBI_US_Item_Authorization_Feature__r.MASTER_PKG_CD__c;
			this.MasterSkuCode = item.CBI_US_Item_Authorization_Feature__r.MASTER_SKU_CD__c;
			this.MasterBrandCode = item.CBI_US_Item_Authorization_Feature__r.BRAND_CD__c;

			PageReference tmpEditLink;
			if (item.CBI_US_Item_Authorization_Feature__r.RecordType.DeveloperName == CBIUSCollectionsUtility.Auth_RecordType) {
				tmpEditLink = Page.CBIUSItemAuthorizationEdit;
			} else {
				tmpEditLink = Page.CBIUSFeatureEdit;
			}
			tmpEditLink.getParameters().put('cid', this.AuthFeatId);
			this.RedirectEditLink = new JSOption(tmpEditLink.getUrl(), this.Name);

		}

	}

}