trigger CBIUSItemAuthorizationFeatureTrigger on CBI_US_Item_Authorization_Feature__c(before insert,
                                                                                     before update, before delete, after insert, after update, after delete, after undelete) {

	if (trigger.isBefore) {
		
		if (trigger.isInsert) {
		//TODO: refactor old validation logic from old triggers.
		CBIUSItemFeatTriggerHandler.validateCBIUSCollectionCodes(Trigger.new);
		}
		if (trigger.isUpdate){
		//TODO: refactor old validation logic from old triggers.
		CBIUSItemFeatTriggerHandler.validateCBIUSCollectionCodes(Trigger.new);
		}

	} else {
		//Insert
		if (trigger.isInsert) CBIUSItemFeatTriggerHandler.HandleAfterInsert(trigger.new, trigger.newMap);
		//Update
		if (trigger.isUpdate) CBIUSItemFeatTriggerHandler.HandleAfterUpdate(trigger.new, trigger.newMap, trigger.oldMap);
		

	}
}