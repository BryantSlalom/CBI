public class CBIUSItemFeatTriggerHandler {

	private static Boolean alreadyProcessedCreateAsyncRequests = false;


	public static void HandleAfterInsert(List<CBI_US_Item_Authorization_Feature__c> rows, Map<ID, CBI_US_Item_Authorization_Feature__c> newMap) {
		System.debug('In CBIUSItemFeatTriggerHandler.HandleAfterInsert: ' + alreadyProcessedCreateAsyncRequests);
		//if (alreadyProcessedCreateAsyncRequests != true) {
		alreadyProcessedCreateAsyncRequests = true;
		CBIUSStoreSetAutomation.CreateAsyncRequests(rows, newMap, null, true);
		//}
	}
	public static void HandleAfterUpdate(List<CBI_US_Item_Authorization_Feature__c> rows, Map<ID, CBI_US_Item_Authorization_Feature__c> newMap, Map<ID, CBI_US_Item_Authorization_Feature__c> oldMap) {
		System.debug('In CBIUSItemFeatTriggerHandler.HandleAfterUpdate: ' + alreadyProcessedCreateAsyncRequests);
		//if (alreadyProcessedCreateAsyncRequests != true) {
		alreadyProcessedCreateAsyncRequests = true;
		CBIUSStoreSetAutomation.CreateAsyncRequests(rows, newMap, oldMap, false);
		//}
	}

	public static void validateCBIUSCollectionCodes(List<CBI_US_Item_Authorization_Feature__c> itemAuthFeat) {

		//empty set
		Set<String> masterPkgCode = new Set<String> ();
		Set<String> masterSkuCode = new Set<String> ();
		Set<String> brandCode = new Set<String> ();
		Set<String> gtinCode = new Set<String> ();

		for (CBI_US_Product__c p :[Select Master_pkg_cd__c, MASTER_SKU_CD__c, BRAND_CD__c, GTIN_NO__c from CBI_US_Product__c where BEV_SEG_CD__c = '101'])
		{
			if (!String.isBlank(p.MASTER_PKG_CD__c)) {
				masterPkgCode.add(p.MASTER_PKG_CD__c);
			}
			if (!String.isBlank(p.MASTER_SKU_CD__c)) {
				masterSkuCode.add(p.MASTER_SKU_CD__c);
			}
			if (!String.isBlank(p.BRAND_CD__c)) {
				brandCode.add(p.BRAND_CD__c);
			}	
			if (!String.isBlank(p.GTIN_NO__c)) {
				gtinCode.add(p.GTIN_NO__c);
			}	

		}

		for (CBI_US_Item_Authorization_Feature__c iaF : itemAuthFeat) {
			if (!masterPkgCode.contains(iaF.MASTER_PKG_CD__c) && iaF.MASTER_PKG_CD__c != null )
			{
				iaF.addError(label.Invalid_Master_Package_Code);
			}
			if (!masterSkuCode.contains(iaF.MASTER_SKU_CD__c)&& iaF.MASTER_SKU_CD__c != null) 
			{

				iaF.addError(label.Invalid_Master_SKU_Code);
			}
			if (!brandCode.contains(iaF.BRAND_CD__c)&& iaF.BRAND_CD__c != null) {

				iaF.addError(label.Invalid_Brand_Code);
			}
			if (!gtinCode.contains(iaF.GTIN_NO__c)&& iaF.GTIN_NO__c != null) {

				iaF.addError(label.Invalid_Retailer_UPC);
			}

		}


	}
}