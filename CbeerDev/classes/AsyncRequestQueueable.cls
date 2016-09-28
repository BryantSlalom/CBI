//class AsyncRequestQueueable 
//Acts as a reusable engine for any resource-intensive or limit-hitting
//processes that are allowed to run Asynchronously using Queueable. This engine uses Chaining
//to continuously engueue more AsyncRequest jobs.
//Dependency: inner classes JobResult, AsyncRequestException
//Dependency: custom object AsyncRequest__c
//Dependency: custom metadata AsyncRequestSetting__mdt
//Dependency: your Business Logic that will return a JobResult instance
//
//LOGIC
//1) Query for 1 available AysncRequest__c waiting to be processed, or exit
//2) Process the request: 
//   a) do any Business Logic based on AsyncType__c picklist and data in Params__c long textarea
//   b) On completion, DELETE the AsyncRequest__c record and optionally Empty Trash Can.
//   c) On partial completion, use UDPATE to change Params__c with the remainder of params to process.
//   d) On failure, throw AsyncRequestException to UPDATE the AysncRequest__c with error flag and message
//3) Try Enqueue the next AsyncRequest record, if any.

public without sharing class AsyncRequestQueueable implements Queueable { 

    //Must match AsyncType__c picklist values
    public static final String TYPE_STORE_SET_AUTOMATION_ITEM = 'Store Set Automation For Item';    
    private QueueableContext context;
    private JobResult result;

    //Static approach to starting a new Async job, preventing if its already in the queue.
    public static void EnqueueAsyncJob(ID currentJobId) {
        System.debug(System.LoggingLevel.INFO, 'In AsyncRequestQueueable.EnqueueAsyncJob. JobId: ' + currentJobId);
        List<AsyncApexJob> jobs =
            [SELECT Id, Status, ExtendedStatus
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND
            (Status='Queued' OR Status='Holding') AND
            ApexClass.Name='AsyncRequestQueueable' AND
            ID != :currentJobId LIMIT 1];
        if (jobs.size() == 1) return; //Already have one queued, dont queue another

        System.enqueueJob(new AsyncRequestQueueable());             
    }

    //Implement Queueable Interface
    public void Execute(QueueableContext c) {
        context = c;
        System.debug('In AsyncRequestQueueable Execute. JobId: ' + context.getJobId());
        
        //On-Off Switch in the 'Default' metadata record.
        if (!IsAppEnabled()) return;

        //Retrieve 1 request record, or exit normally.
        AsyncRequest__c req = GetNextRequest();
        if (req == null) return;    

        //Process request
        try {
            //Business Logic
            result = DoBusinessLogic(req);
            //Handle cleanup by deleting request, or update to process again.
            CleanUp(req, result);
        }
        catch (Exception ex) {
            //DML and SOQL exceptions cannot be caught. You must be proactive in Business Logic
            req.Error__c = true;
            req.Error_Message__c = ex.getMessage();
            update req;
        }
        //Queue next request... if any. (chaining)
        QueueNextJobIfAny();        
    }

    private AsyncRequest__c GetNextRequest() {
        AsyncRequest__c request;
        try {
            //Use FOR UPDATE to help prevent against concurrency.
            request = [SELECT Id, AsyncType__c, Params__c, Error__c, Error_Message__c 
                        FROM AsyncRequest__c
                        WHERE Error__c = false
                        LIMIT 1 FOR UPDATE];
        }
        catch(Exception ex) { return null; }
        return request;
    }

    private void QueueNextJobIfAny() {

        List<AsyncRequest__c> moreRequests = 
            [SELECT Id, AsyncType__c, Params__c, Error__c, Error_Message__c
            FROM AsyncRequest__c
            WHERE Error__c = false
            LIMIT 1]; 

        if (moreRequests.size() == 0) return; //None left, all done.

        //Enqueue the next job. Retry in a Future if can't start now.
        //Chaining is not allowed in Unit Tests. Hard-prevent chaining if in test.
        if (!Test.isRunningTest()) {
            try {
                System.debug('Found more AsyncRequests to process... calling EnqueueAsyncJob with JobId: ' + context.getJobId());
                EnqueueAsyncJob(context.getJobId());
            }
            catch (Exception ex) {
                //Last ditch effort, try to Queue it via a Future call.
                EnqueueAsyncJobFuture(null);
            }
        }   
    }

    //This acts as a back-up approach to enqueue an AsyncRequestQueueable job from anywhere a Future can be called.
    @future
    public static void EnqueueAsyncJobFuture(ID currentJobId) {
        //TODO: On-Off switch
        if (!IsAppEnabled()) return;

        try {
            if (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
                EnqueueAsyncJob(currentJobId);
            }
        }
        catch (Exception e) {
            //Ignore for now.. wait for someone else to make a request...
        }
    }

    private void CleanUp(AsyncRequest__c req, JobResult result) {
        //Use UPDATE to make changes to the AsyncRequest__c if you want it to be processed again.
        //Eg., too many IDs were in the Params__c and limits were hit trying to process all IDs.
        if (result != null && result.DoUpdate) {
            update req;
        }
        //Use DELETE in normal processing, to keep system clean.
        else if (result != null && result.DoDelete) {
            delete req;
            if (result.DoEmptyTrash) {
                Database.emptyRecycleBin(new List<ID> { req.Id });
            }
        }
    }

    //Consideration: create an Interface/baseclass that business logic classes can Implement and override.
    private JobResult DoBusinessLogic(AsyncRequest__c req) {
        JobResult result;
        if (req.AsyncType__c == TYPE_STORE_SET_AUTOMATION_ITEM) {
            //Store Set Automation: Auth/Feature-driven
            result = new CBIUSStoreSetAutomation(req).AutoManageStoresForAuthFeature();
        } 
        else {
            //...future features that need asynchronous batch-like jobs 
            //that can be chained and recovered...
            //For now, blow up.
            throw new AsyncRequestException('The AsyncType__c is invalid. AsyncRequest not processed.');
        }
        if (result == null) {
            throw new AsyncRequestException('Please contact your administrator. Error: Unexpected error in AsyncRequestQueueable class. Business Logic did not return a JobResult instance.');      
        }
        return result;
    }

    public static Boolean IsAppEnabled() {
        Boolean appEnabled = true;
        AsyncRequestSetting__mdt setting = FindSettingByAsyncType('Default');
        if (setting != null && setting.AppEnabled__c != null) {
            appEnabled = setting.AppEnabled__c;
        }
        return appEnabled;
    }

    public static AsyncRequestSetting__mdt FindSettingByAsyncType(String asyncType) {
        AsyncRequestSetting__mdt setting; 
        
        if (!String.isBlank(asyncType)) {
            List<AsyncRequestSetting__mdt> settings = 
                [select AsyncType__c, AppEnabled__c, Max_Params_to_Process__c, DMLRowsThreshold__c, DMLStatementsThreshold__c,  
                SOQLQueriesThreshold__c, SOQLRowsThreshold__c, PadDMLRows__c, PadDMLStatements__c, PadSOQLQueries__c, PadSOQLRows__c
                FROM AsyncRequestSetting__mdt 
                WHERE AsyncType__c = :asyncType];

            if (settings.size() > 0) {
                System.debug('Found metadata record for AsyncType: ' + asyncType);
                //Should only be one, take the first one you find.
                setting =  settings[0];
            }
        }
        return setting;
    }

    public class AsyncRequestException extends Exception {}
    
    public class JobResult {
        public Boolean DoUpdate {get;set;}
        public Boolean DoDelete {get;set;}
        public Boolean DoEmptyTrash {get;set;}
        public JobResult() {
            DoUpdate = false;
            DoDelete = true;
            DoEmptyTrash = true;
        } 
    }
}