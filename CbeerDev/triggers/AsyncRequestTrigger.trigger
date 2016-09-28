trigger AsyncRequestTrigger on AsyncRequest__c (after insert)  { 
	System.debug('In AsyncRequestTrigger');
	AsyncRequestTriggerHandler.HandleAfterInsert(trigger.new, trigger.newMap, trigger.oldMap, trigger.isInsert);
}