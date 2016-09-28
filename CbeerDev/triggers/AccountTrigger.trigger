/**
 ** @author Reid Beckett, Cloudware Connections
 ** @created Feb 5/2014
 **
 ** Trigger to populate the Account migration key
 ** In Quebec, if Store_Number__c is blank then copy it from AccountNumber
 ** rev1 : 07/10/2014 Shirish
 ** modification: added condition for checking record type of account. 
 ** No need to set Migration Key, Store Number and call EDWHelper method for US Account record type
 ** Added code to set parent account id based on Ultimate Parent Code
 ** rev 2: 03/12/2015 Shirish
 ** Added logic for creating notifications: Identify if the updates are in the fields defined in the custom setting, then create notification records
 ** rev 3 :10/8/2015 Madhav Kuchimanhi
 ** Current logic is failing to import more than 100 Account records at a time . 
 ** Added logic EDWTriggerHelper.onBeforeAccount for handling bulk records at a time. 
  **/
trigger AccountTrigger on Account(before insert, before update, after insert, after update) { //, after update

	//Store Set Automation
	try {
		if (trigger.isAfter && trigger.isInsert) {
			CBBDAccountTriggerHandler.HandleAfterInsert(trigger.new, trigger.newMap);
		} else if (trigger.isAfter && trigger.isUpdate) {
			CBBDAccountTriggerHandler.HandleAfterUpdate(trigger.new, trigger.newMap, trigger.oldMap);
		}
	} catch(Exception e) {
		//supress
	}





	if (trigger.isUpdate && trigger.isAfter) {
		Set<String> fieldsSet = new Set<String> ();
		String fieldsStr = '';
		for (On_Change_Fields_Map__c changeFieldRec :[SELECT id, Name, Object_Name__c, Fields__c From On_Change_Fields_Map__c Where Object_Name__c = 'Account']) {
			fieldsSet.add(changeFieldRec.Fields__c.trim());
			fieldsStr = fieldsStr + changeFieldRec.Fields__c.trim() + ',';
		}

		System.debug('fieldsSet:::' + fieldsSet + 'fieldsStr  :::' + fieldsStr);

		System.debug('fieldsSet:::' + fieldsSet + 'fieldsStr  :::' + fieldsStr);
		List<Account> accList = new List<Account> ();
		Set<Id> accIds = new Set<Id> ();
		Map<Id, NotificationHelper.FieldHistoryClass> accIdToFieldChanged = new Map<Id, NotificationHelper.FieldHistoryClass> ();
		Set<Id> acctIds = trigger.newMap.keyset();
		String query = 'Select ' + fieldsStr + 'id ' + ' , ' + 'Name' + ' , ' + ' lastModifiedById' + ' From Account Where Id in : acctIds ';
		System.debug('query :::' + query);
		List<Account> acctList = database.query(query);
		System.debug('acctList :::' + acctList);
		for (Account a : acctList) {
			Boolean isChanged = false;
			isChanged = NotificationHelper.hasChanged(fieldsSet, (sObject) a, (sObject) trigger.oldMap.get(a.id));
			if (isChanged) {
				accList.add(a);
				accIds.add(a.id);
				accIdToFieldChanged.put(a.Id, NotificationHelper.fieldNameWrap);
			}
		}
		if (!accList.isEmpty()) {
			AccountTriggerHandler handler = new AccountTriggerHandler();
			handler.doAfterInsert(accList, accIds, accIdToFieldChanged);
		}

	} else {
		Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType> ();
		Set<Id> accIds = new Set<Id> ();
		//Set<Id> acctids = new Set<Id>(); //maddy
		//List<Account> canAccs = new List<Account>(); //maddy
		List<Account> childAccs = new List<Account> ();
		Set<Id> accIdsForChannelAssetsDelete = new Set<Id> ();
		for (Account a : Trigger.new) {
			if (!recordTypeMap.containsKey(a.RecordTypeId)) {
				recordTypeMap.put(a.RecordTypeId, null);
			}

		}
		for (RecordType rt :[select Id, DeveloperName from RecordType where Id in :recordTypeMap.keySet()]) {
			recordTypeMap.put(rt.Id, rt);
		}



		for (Account a : Trigger.new) {
			String recTypeName = '';
			if (recordTypeMap.containsKey(a.RecordTypeId)) {
				recTypeName = recordTypeMap.get(a.RecordTypeId).DeveloperName;
			}
			//after insert or before update and if account is not a parent account
			if ((trigger.isafter && trigger.isInsert && !a.Est_un_compte_parent__c) ||
			(trigger.isUpdate && !a.Est_un_compte_parent__c
			 && a.ParentId == trigger.oldMap.get(a.Id).ParentId //no change in parent id on the account - 
			 //this will prevent the trigger from re-firing when the parent id is assigned
			 //&& a.Ultimate_Parent_Code__c != trigger.oldMap.get(a.Id).Ultimate_Parent_Code__c
			)) {
				//create a set and list of child accounts and their Ids
				if (recTypeName != '' && recTypeName.equalsIgnoreCase('US_Account')) {
					accIds.add(a.Id);
					childAccs.add(a);
				}
			}
			//deleteChannelAssetLinks
			//if Ultimate parent code of an account is being updated, i.e. the account's parent is changing, we need to delete all the channel assets for that account
			if (trigger.isUpdate && a.Ultimate_Parent_Code__c != trigger.oldMap.get(a.Id).Ultimate_Parent_Code__c) {
				accIdsForChannelAssetsDelete.add(a.Id);
			}
			//execute this portion of trigger for accounts with record type not equal to US Account 
			//as this was running into governor limits with integration data load
			if (trigger.isbefore && (recTypeName != '' && !recTypeName.equalsIgnoreCase('US_Account'))) {
				if (a.Province__c == 'Quebec' && String.isBlank(a.Store_Number__c)) {
					a.Store_Number__c = a.AccountNumber;
				}
				if (recordTypeMap.containsKey(a.RecordTypeId)) {
					String migrationKey = ChannelUtil.getMigrationKey(a, recordTypeMap.get(a.RecordTypeId).DeveloperName);
					//if(migrationKey != null){
					a.Migration_Key__c = migrationKey;
					//}
				}


			}
		}

		List<Account> listacct = new List<Account> ();
		if (trigger.isBefore) {
			EDWTriggerHelper.onBeforeAccount(Trigger.new);

		}




		if (accIds.size() > 0) {
			//in case of insert, update the accounts in future call to set the parent id since the parent might be inserted at the same time as the child
			//if(trigger.isInsert){
			//AccountTriggerHelper.asyncSetParentIdOnAccount(accIds);
			// }
			//in case of update, since the parent account already exists we can update the child account in the same transaction
			/*if(trigger.isUpdate){
			  AccountTriggerHelper.syncSetParentIdOnAccount(childAccs);
			  } */
			AccountTriggerHelper.setParentIdOnAccount(accIds, Trigger.isBefore);
		}
		if (accIdsForChannelAssetsDelete.size() > 0) {
			AccountTriggerHelper.deleteChannelAssetLinks(accIdsForChannelAssetsDelete);
		}
	}
}