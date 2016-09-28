public class CBBDAccountTriggerHandler {
 
	public static void HandleAfterInsert(List<Account> rows, Map<ID, Account> newMap) {	
		CBIUSStoreSetAutomation.CreateAsyncRequestsForAccounts(rows, newMap, null, true);
	}
	public static void HandleAfterUpdate(List<Account> rows, Map<ID, Account> newMap, Map<ID,Account> oldMap) {
		CBIUSStoreSetAutomation.CreateAsyncRequestsForAccounts(rows, newMap, oldMap, false);
	} 

 }