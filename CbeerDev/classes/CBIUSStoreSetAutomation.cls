public class CBIUSStoreSetAutomation { 
    private AsyncRequest__c r;
    private static final String recordTypeAccount = 'US_Account';
    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_INACTIVE = 'Inactive';
    private static Set<String> StoreSetFields = new Set<String> {'Sub_Accounts__c',
        'Marketing_Groups__c','Report_To_Codes__c','States__c'};
    
    //Defaults - gets overridden by Custom Metadata.
    private Decimal maxAuthsToProcessInQueueable = 200; 
    private Decimal pctUsageDMLStatements = .60; 
    private Decimal pctUsageDMLRows = .60;
    private Decimal pctUsageSOQLQueries = .60;
    private Decimal pctUsageSOQLRows = .60;
    private Decimal pctUsageHeap = .90;
    private Decimal padDMLStatements = 15;
    private Decimal padDMLRows = 1000;
    private Decimal padSOQLQueries = 20;
    private Decimal padSOQLRows = 5000; 
    private Boolean appEnabled = true;

    //Constructor accepts AsyncRequest__c 
    public CBIUSStoreSetAutomation(AsyncRequest__c req) {
        if (req == null) throw new AsyncRequestQueueable.AsyncRequestException('Error: No AsyncRequest record was provided to CBIUSStoreSetAutomation class.');
        r = req;
        InitializeCustomMetadata();
    }
    private void InitializeCustomMetadata() {
        if (r == null) return;
        String asyncType = r.AsyncType__c;
        AsyncRequestSetting__mdt conf =  AsyncRequestQueueable.FindSettingByAsyncType(asyncType);
        if (conf != null) {
            pctUsageDMLStatements = conf.DMLStatementsThreshold__c != null ? conf.DMLStatementsThreshold__c : pctUsageDMLStatements; 
            pctUsageDMLRows = conf.DMLRowsThreshold__c != null ? conf.DMLRowsThreshold__c : pctUsageDMLRows;
            pctUsageSOQLQueries = conf.SOQLQueriesThreshold__c != null ? conf.SOQLQueriesThreshold__c : pctUsageSOQLQueries;
            pctUsageSOQLRows = conf.SOQLRowsThreshold__c != null ? conf.SOQLRowsThreshold__c : pctUsageSOQLRows;
            padDMLStatements = conf.PadDMLStatements__c != null ? conf.PadDMLStatements__c : padDMLStatements;
            padDMLRows = conf.PadDMLRows__c != null ? conf.PadDMLRows__c : padDMLRows;
            padSOQLQueries = conf.PadSOQLQueries__c != null ? conf.PadSOQLQueries__c : padSOQLQueries;
            padSOQLRows = conf.PadSOQLRows__c != null ? conf.PadSOQLRows__c : padSOQLRows;
            appEnabled = conf.AppEnabled__c != null ? conf.AppEnabled__c : appEnabled;
            maxAuthsToProcessInQueueable = conf.Max_Params_to_Process__c != null ? conf.Max_Params_to_Process__c : maxAuthsToProcessInQueueable;  
        }
    }

    /* 
    Considerations: 
    1) we can't be sure how many Auth IDs are present in Params__c
    2) we can't Try/Catch SOQL and DML Limit Exceptions, so we must be proactively checking Limits class
    3) we want to try to process as many auths in a Queueable job as possible, honoring limits and padding
    4) we don't want an Auth to be 'partially' processed, either the auth can finish fully, or not at all.
    5) we can update the AsyncRequest__c with AuthIds that did not get processed, so it will be processed in next Queueable
    6) potential optimzation: remember each Auth's StoreSetCriteria searched and the Stores found so you don't "find" them again. (to reduce SOQL queries & rows)
    */  
    public AsyncRequestQueueable.JobResult AutoManageStoresForAuthFeature() {       
        //Return object
        AsyncRequestQueueable.JobResult result = new AsyncRequestQueueable.JobResult();

        //DML Lists.
        List<Account_Auth_Feature__c> toBeInserted = new List<Account_Auth_Feature__c>();
        List<Account_Auth_Feature__c> toBeDeleted = new List<Account_Auth_Feature__c>();

        //Helpers
        String authIdParams = r.Params__c;
        List<String> authIds = authIdParams.split(',');
        Set<String> authIdsSet = new Set<String>(authIds);
        Set<String> authsNotFoundOrInactive = new Set<String>();
        Set<String> authsFinishedSuccesfully = new Set<String>();
        List<String> skipped = new List<String>();  
        Integer currentTotal = 0;

        //Validate - will throw exception if invalid
        ValidateRequest();
        
        Boolean skipTheRest = false;

        //Simply iterate each auth and process it until you run out of limits (allowing some padding)
        for (Integer i=0; i<authIds.size(); i++) {

            String authId = authIds[i];
            System.debug('Auth Id: '+ authId);          
            
            //Are we skipping the rest of IDs because Limit prevention already occurred?
            if (skipTheRest) {
                skipped.add(authId);
                System.debug('Skip the rest: '+ authId);
                continue;
            }
            //Validate don't exceed custom setting.
            if (i >= maxAuthsToProcessInQueueable) {
                System.debug('Skipped Id due to Max Params To Process setting: ' + authId);
                skipped.add(authId);
                skipTheRest = true;
                continue;
            }           
            //Validate DML Limits       
            currentTotal = toBeInserted.size() + toBeDeleted.size();
            if (!ValidateLimitsDML(currentTotal)) {
                System.debug('Skipped Id because of DML limits: ' + authId);
                skipped.add(authId);
                skipTheRest = true;     
                continue;
            }
            //Validate SOQL Limits          
            if (!ValidateLimitsSOQL())
            {
                System.debug('Skipped Id because of SOQL Limits: ' + authId);
                skipped.add(authId);
                skipTheRest = true;     
                continue;
            }
            //Validate Heap Limits
            if (!ValidateLimitsHeap())
            {
                System.debug('Skipped Id because of Heap Limits: ' + authId);
                System.debug(Limits.getHeapSize() + ' Heap Size used against Limits: ' + Limits.getLimitHeapSize());
                skipped.add(authId);
                skipTheRest = true;     
                continue;
            }               

            //Attempt SOQL
            //Query the 1 AuthFeat to get the StoreSet Criteria
            List<CBI_US_Item_Authorization_Feature__c> items = [SELECT Id, Ultimate_Parent__c,
                Ultimate_Parent__r.Name, Name, RecordType.Name, RecordType.DeveloperName, 
                Add_all_Parent_Account_stores__c, 
                Sub_Accounts__c,
                States__c,
                Report_To_Codes__c,
                Marketing_Groups__c         
                FROM CBI_US_Item_Authorization_Feature__c 
                WHERE Id = :authId AND Status__c=:STATUS_ACTIVE]; 
        
            //If not found, track it, and move on.
            if (items.size() == 0) {
                //Ignore and move on.
                System.debug('No AuthFeature ID found that matches: ' + authId); 
                authsNotFoundOrInactive.add(authId);
                continue;
            }

            CBI_US_Item_Authorization_Feature__c item = items[0];

            //Get all the Stores already associated to the AuthFeature.
            System.debug('getting junction records.');
            Map<Id,Account_Auth_Feature__c> junctions = new Map<Id,Account_Auth_Feature__c>();
            Map<Id,Id> associatedStoreIdsToJunctionIds = new Map<Id,Id>();      
            for (Account_Auth_Feature__c j : [SELECT Id, System_Managed__c, Account__c, CBI_US_Item_Authorization_Feature__c 
                    FROM Account_Auth_Feature__c where CBI_US_Item_Authorization_Feature__c = :authId]) {
                junctions.put(j.Id, j);
                associatedStoreIdsToJunctionIds.put(j.Account__c, j.Id);
            }           
            System.debug('Junctions: ' + junctions.size());         
            
            //Determine which Stores match the Auth/Feature's Store Set criteria
            //but, only Search for stores if at least one of the store set fields is populated/checked.         
            Id ultimateParentId = item.Ultimate_Parent__c;
            Map<Id, Account> matchingStoresMap = new Map<Id, Account>();            
            
            if (hasAnyStoreSetCriteria(item)) {

                System.debug('Querying for Stores');
                List<String> subs = !String.isBlank(item.Sub_Accounts__c) ? new List<String>(item.Sub_Accounts__c.split('\\|')) : new List<String>();
                List<String> mGroups = !String.isBlank(item.Marketing_Groups__c) ? new List<String>(item.Marketing_Groups__c.split('\\|')) : new List<String>();
                List<String> reportTos = !String.isBlank(item.Report_To_Codes__c) ? new List<String>(item.Report_To_Codes__c.split('\\|')) : new List<String>();
                List<String> states = !String.isBlank(item.States__c) ? new List<String>(item.States__c.split('\\|')) : new List<String>();
                
                System.debug('Searching sub accounts: ' + subs);
                System.debug('Searching marketing groups: ' + mGroups);
                System.debug('Searching report tos: ' + reportTos);
                System.debug('Searching states: ' + states);

                //Build and run query
                String qString = 'SELECT Id, ParentId, RMA__c,Marketing_Group__c, SUBACCOUNT_DSC__c, BillingState FROM Account';
                qString += ' WHERE ParentId = :ultimateParentId';
                qString += ' AND RecordType.DeveloperName = :recordTypeAccount';

                //If not all stores, then find subaccounts,mgroups,reportTos, and States
                if (item.Add_all_Parent_Account_stores__c == false) {           
                    //States
                    if (states.size() > 0) {
                        qString += ' AND BillingState IN :states';
                    }
                    if (subs.size() > 0 || mGroups.size() > 0 || reportTos.size() > 0) {
                        //We'll OR these in our SOQL, even though the front-end UI and validation
                        //rules currently only support setting 1 of the 3 fields on a single Auth/Feature.
                        Integer anyAdded = 0;
                        qString += ' AND (';
                        if (subs.size() > 0) {
                            if (anyAdded > 0) qString += ' OR ';                    
                            qString += ' SUBACCOUNT_DSC__c IN :subs' ;
                            anyAdded++; 
                        }
                        if (mGroups.size() > 0) {
                            if (anyAdded > 0) qString += ' OR ';                    
                            qString += ' Marketing_Group__c IN :mGroups' ; 
                            anyAdded++;
                        }
                        if (reportTos.size() > 0) { 
                            if (anyAdded > 0) qString += ' OR ';                
                            qString += ' RMA__c IN :reportTos' ; 
                            anyAdded++;
                        }
                        qString += ' ) '; //Close the OR group
                    }
                }   

                System.debug('Store query: ' + qString);    
                for (List<sObject> stores : Database.query(qString)) {
                    //Each loop processes 200 items because of Database.Query
                    for (sObject s : stores) {
                        matchingStoresMap.put(s.Id, (Account)s);    
                    }
                }   
                System.debug('number of stores: ' + matchingStoresMap.size());          
            } else {
                System.debug('Auth/Feature has no Stores Set Criteria, didnt search for stores.');
            }

            //Determine which ones should be deleted because they aren't applicable anymore.
            //Iterate associated, and if it doesn't exist in matchedStores (and its System-Managed = true)
            //delete it. We ignore Junctions where System Managed = false.      
            List<Account_Auth_Feature__c> TempToBeDeleted = new List<Account_Auth_Feature__c>();
            for (Id associatedStoreId : associatedStoreIdsToJunctionIds.keyset()) {
                Id jId = associatedStoreIdsToJunctionIds.get(associatedStoreId);
                Account_Auth_Feature__c f = junctions.get(jId);
                if (f.System_Managed__c != null && f.System_Managed__c == true && !matchingStoresMap.containskey(associatedStoreId)) {
                    TempToBeDeleted.add(f);
                }
            }
            //Which ones need to be inserted because they aren't already associated?
            List<Account_Auth_Feature__c> TempToBeInserted = new List<Account_Auth_Feature__c>();       
            for (Id matchedStoreId : matchingStoresMap.keyset()) {      
            
                //Dont INSERT it if its already attached.           
                if (!associatedStoreIdsToJunctionIds.containskey(matchedStoreId)) {
                    TempToBeInserted.add(
                        new Account_Auth_Feature__c(
                            Account__c = matchedStoreId, 
                            CBI_US_Item_Authorization_Feature__c = item.Id,
                            System_Managed__c = true));
                }
            }

            //Calculate DML limits for INSERT, DELETE           
            currentTotal = toBeInserted.size() + toBeDeleted.size() + TempToBeInserted.size() + TempToBeDeleted.size();
            if (!ValidateLimitsDML(currentTotal)) {
                System.debug('Skipped Id because of DML limits: ' + authId);
                skipped.add(authId);
                skipTheRest = true;     
                continue;
            }       

            //Otherwise, we think its safe to process.
            toBeDeleted.addAll(TempToBeDeleted);
            toBeInserted.addAll(TempToBeInserted);
            authsFinishedSuccesfully.add(authId);
        
        } //End For Loop.

        DebugLimitsAndActuals();
        Savepoint sp = Database.setSavepoint();
        try {
            //Insert
            System.debug('# of Account_Auth_Feature__c to be inserted: ' + toBeInserted.size());    
            if (toBeInserted.size() > 0) {
                //Database.insert(toBeInserted, false);
                insert toBeInserted;
            }
            //Delete
            System.debug('# of Account_Auth_Feature__c to be deleted: ' + toBeDeleted.size()); 
            if (toBeDeleted.size() > 0) {       
                delete toBeDeleted;
            }
        } catch (Exception e) {
            System.debug('Exception happened during DMLs: ' + e.getMessage());
            //Rollback
            Database.rollback(sp);
            //All the ids we thought we fixed, are now skipped.
            skipped.addAll(authsFinishedSuccesfully);
            throw new AsyncRequestQueueable.AsyncRequestException('Exception happened during DMLs: ' + e.getMessage(), e);
        }
        
        //Set Results to handle Async record.
        if (skipped.size() > 0) {
            result.DoUpdate = true;
            result.DoDelete = false;
            result.DoEmptyTrash = false;
            //Set the params to those that were skipped.
            r.Params__c = String.join(skipped, ',');
        }

        DebugLimitsAndActuals();

        return result;
    }
    private Boolean ValidateLimitsDML(Integer pendingDmlRows) {
        if ((Limits.getDmlRows() + pendingDmlRows + padDMLRows) / Limits.getLimitDmlRows() >= pctUsageDMLRows ||
            (Limits.getDmlStatements() + padDMLStatements) / Limits.getLimitDmlStatements() >= pctUsageDMLStatements){
            System.debug('Invalid DML Limits');
            return false;
        }
        return true;
    }
    private Boolean ValidateLimitsSOQL() {
        if ((Limits.getQueries() + padSOQLQueries) / Limits.getLimitQueries() >= pctUsageSOQLQueries ||
            (Limits.getQueryRows() + padSOQLRows) / Limits.getLimitQueryRows() >= pctUsageSOQLRows)
        {
            System.debug('Invalid SOQL Limits');
            return false;
        }
        return true;
    }
    private Boolean ValidateLimitsHeap() {
        System.debug('' + Limits.getHeapSize() + ' Heap Size used against Limits: ' + Limits.getLimitHeapSize());
        if (Limits.getHeapSize() / Limits.getLimitHeapSize() >= pctUsageHeap) {
            System.debug('Invalid Heap Limits');
            return false;
        }
        return true;
    }
    private void ValidateRequest() {
        //Must have IDs in Params__c
        if (String.isBlank(r.Params__c)) {
            throw new AsyncRequestQueueable.AsyncRequestException('Params__c was empty. It needs to contain 1 or more comma-separated AuthFeatureIds.');
        }
        //Validate AppEnabled - throw exception to mark the record an error for later processing.
        if (this.appEnabled == false) {
            throw new AsyncRequestQueueable.AsyncRequestException('Store Set Automation is disabled. Please enable and try again.');
        }
    }
    private void DebugLimitsAndActuals() {
        System.debug(Limits.getHeapSize() + ' Heap Size used against Limits: ' + Limits.getLimitHeapSize());
        System.debug(Limits.getQueries() + ' SOQL Queries used against Limits: ' +  Limits.getLimitQueries());
        System.debug(Limits.getQueryRows() + ' SOQL  Rows used aginst Limits: ' +  Limits.getLimitQueryRows());
        System.debug(Limits.getDmlStatements() + ' DML statements used against Limits: ' +  Limits.getLimitDmlStatements());
        System.debug(Limits.getDmlRows() + ' DML Rows used against limits: ' +  Limits.getLimitDmlRows());
    }

    private static Boolean hasAnyStoreSetCriteria(CBI_US_Item_Authorization_Feature__c item) {  
        if (item == null) return false;
        if (item.Add_all_Parent_Account_stores__c == true) return true;
        if (!String.isBlank(item.Sub_Accounts__c)) return true;
        if (!String.isBlank(item.Marketing_Groups__c)) return true;
        if (!String.isBlank(item.Report_To_Codes__c)) return true;
        if (!String.isBlank(item.States__c)) return true;

        return false;
    }
    //Called by Trigger Handler for AuthFeature object
    public static void CreateAsyncRequests(List<CBI_US_Item_Authorization_Feature__c> rows, Map<ID, CBI_US_Item_Authorization_Feature__c> newMap, Map<ID,CBI_US_Item_Authorization_Feature__c> oldMap, Boolean isInsert) {
        System.debug('In CreateAsyncRequests with ' + rows.size() + 'Auths/Features');
        Integer authIdsPerAsyncRequest = 1; //TODO: Make configurable in custom setting once logic can support it.  
        List<String> reqs  = new List<String>();
        for (CBI_US_Item_Authorization_Feature__c r : rows) {
            if (isInsert) {              
                //Only queue them up if they have a Store Set field.
                if (hasAnyStoreSetCriteria(r)) {
                    reqs.add(r.Id);
                }           
            } else {            
                //Only queue them up if a Store Set field changed.
                if (r.Add_all_Parent_Account_stores__c != oldMap.get(r.Id).Add_all_Parent_Account_stores__c) {
                    reqs.add(r.Id);
                } else {
                    for (String fieldName : StoreSetFields) {
                        if ((String)r.get(fieldName) != (String)oldMap.get(r.Id).get(fieldName)) {
                            reqs.add(r.Id);
                            break;
                        }
                    }
                }
            } 
        }
        //Insert AsyncRequests
        System.debug('Total AuthFeature IDs to process on AsyncRequest: ' + reqs.size());
        if (reqs.size() > 0) {          
            insert MakeAsyncRequest(String.join(reqs,','));
        }
    }
    public static void CreateAsyncRequestsForAccounts(List<Account> rows, Map<ID, Account> newMap, Map<ID,Account> oldMap, Boolean isInsert) {
        Integer authIdsPerAsyncRequest = 1; //TODO: Make configurable in custom setting once logic can support it.  
        //Get RecordType for US Account
        ID USAccount = Schema.SObjectType.Account
            .getRecordTypeInfosByName().get('US Account').getRecordTypeId();
        
        Set<ID> ultAccIds = new Set<ID>();
        for (Account r : rows) {
            //Only process US Account and where it is a child account
            if (r.RecordTypeId == USAccount && r.ParentId != null) {
                if (isInsert) {
                        //Always run AuthFeature logic if new accounts being created.               
                        ultAccIds.add(r.ParentId);      
                } else {            
                    //Only queue them up if a Store Set field changed or Account reparented.
                    //RMA__c,Marketing_Group__c, SUBACCOUNT_DSC__c, BillingState                                        
                    if ((String)r.get('RMA__c') != (String)oldMap.get(r.Id).get('RMA__c') ||
                        (String)r.get('Marketing_Group__c') != (String)oldMap.get(r.Id).get('Marketing_Group__c') ||
                        (String)r.get('SUBACCOUNT_DSC__c') != (String)oldMap.get(r.Id).get('SUBACCOUNT_DSC__c') ||
                        (String)r.get('BillingState') != (String)oldMap.get(r.Id).get('BillingState')) {
                        ultAccIds.add(r.ParentId);
                    }
                    //Handle if Account gets reparented.
                    if (r.ParentId != oldMap.get(r.Id).ParentId) {
                        ultAccIds.add(r.ParentId);
                        ultAccIds.add(oldMap.get(r.Id).ParentId);
                    }           
                } 
            }
        }                   
        //Insert AsyncRequests
        List<String> reqIds = new List<String>();
        if (ultAccIds.size() > 0) {
            for (CBI_US_Item_Authorization_Feature__c feature : FindActiveAuthsByUltAccIds(ultAccIds)) {
                reqIds.add((String)feature.Id);
            }
            if (reqIds.size() > 0) {
                insert MakeAsyncRequest(String.join(reqIds,','));
            }
        }   
    }
    private static AsyncRequest__c MakeAsyncRequest(String authFeatId) {
        return new AsyncRequest__c(
            AsyncType__c=AsyncRequestQueueable.TYPE_STORE_SET_AUTOMATION_ITEM,
            Params__c=authFeatId);
    }
    private static List<CBI_US_Item_Authorization_Feature__c> FindActiveAuthsByUltAccIds(Set<Id> ultAccIds) {
        return [SELECT Id, Ultimate_Parent__c,
                Ultimate_Parent__r.Name, Name, RecordType.Name, RecordType.DeveloperName, 
                Add_all_Parent_Account_stores__c, 
                Sub_Accounts__c,
                States__c,
                Report_To_Codes__c,
                Marketing_Groups__c         
                FROM CBI_US_Item_Authorization_Feature__c 
                WHERE Ultimate_Parent__c IN :ultAccIds AND Status__c=:STATUS_ACTIVE];
    }
}