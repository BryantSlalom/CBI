global class CBIUSCollectionDelAccountAuthFeat implements Schedulable {
	/**
	 * @description Executes the scheduled Apex job. 
	 * @param sc contains the job ID
	 */ 

	global void execute(SchedulableContext sc) {
		String query = 'SELECT Id FROM Account_Auth_Feature__c where Store_CD__c = null';
        CBIUSCollectionsDelRecsBatchable b = new CBIUSCollectionsDelRecsBatchable(query);
        database.executebatch(b);
	}
}