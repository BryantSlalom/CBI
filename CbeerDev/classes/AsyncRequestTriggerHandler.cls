public class AsyncRequestTriggerHandler {

	public AsyncRequestTriggerHandler() {}
	
	//Handles AfterInsert
	public static void HandleAfterInsert(List<AsyncRequest__c> reqList, Map<ID, AsyncRequest__c> newMap, Map<ID,AsyncRequest__c> oldMap, Boolean isInsert) 
	{
		System.debug('In AsyncRequestTriggerHandler.HandleAfterInsert');
		//We don't actually care about any of the AsyncRequests created right now, we just want to start a Queueable if we can.
		//The Queueable Job determines what AsyncRequests are in the queue, and tries to process them.
		if (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
			try {
				AsyncRequestQueueable.EnqueueAsyncJob(null);
			} catch(Exception e) {
				//Ignore for now. 
				//Next time trigger fires, it will try to start Queueable chain again.
			}
		}
	}
}