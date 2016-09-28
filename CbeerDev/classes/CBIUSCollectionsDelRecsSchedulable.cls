global class CBIUSCollectionsDelRecsSchedulable implements Schedulable {
	/**
	 * @description Executes the scheduled Apex job. 
	 * @param sc contains the job ID
	 */ 
	global void execute(SchedulableContext sc) {
		String query = 'SELECT Id FROM CBI_US_Item_Authorization_Feature__c where Deletion__c = true  ';
        CBIUSCollectionsDelRecsBatchable b = new CBIUSCollectionsDelRecsBatchable(query);
        database.executebatch(b);
	}
}