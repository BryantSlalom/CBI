@isTest
private class CBIUSCollectionsDelRecsSchedulableTest {

	// CRON expression: midnight on March 15.
	// Because this is a test, job executes
	// immediately after Test.stopTest().
	public static String CRON_EXP = '0 0 0 15 3 ? 2022';

	static testmethod void testCBIUSItemAuthDelRecsSchdl() {

		//TestUtil.createBulkProducts();
		TestUtil.createBulkValidItemAuthFlag2Del();
		Test.startTest();
		// Schedule the test job

		String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new CBIUSCollectionsDelRecsSchedulable());
		// Get the information from the CronTrigger API object

		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		// Verify the expressions are the same

		System.assertEquals(CRON_EXP, ct.CronExpression);

		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);

		// Verify the next time the job will run
		System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));

		// Verify the scheduled job hasn't run yet.
		CBI_US_Item_Authorization_Feature__c[] c = [SELECT Id FROM CBI_US_Item_Authorization_Feature__c
		                                    WHERE Name = 'Scheduled Job Item'];
		System.assertEquals(c.size(), 0);

		Test.stopTest();

		// Now that the scheduled job has executed after Test.stopTest(),
		// Make sure the records were deleted
		c = [SELECT Id FROM CBI_US_Item_Authorization_Feature__c
		     WHERE Name = 'Scheduled Job Item'];
		System.assertEquals(c.size(), 0);

	}
	static testmethod void testCBIUSAccountAuthDelRecsSchdl() {

		//TestUtil.createBulkProducts();
		Account parent = new Account(Name='Parent Account',Est_un_compte_parent__c = true);		
		insert parent;
		Account child = new Account(name = 'Child Account',parentid = parent.id,Store_Code__c = '123');
		insert child;	

		CBI_US_Item_Authorization_Feature__c ia = TestUtil.createItemAuthOrFeature(parent.id, 'Feature');

		delete child;
		Test.startTest();
		// Schedule the test job

		String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new CBIUSCollectionDelAccountAuthFeat());
		// Get the information from the CronTrigger API object

		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		// Verify the expressions are the same

		System.assertEquals(CRON_EXP, ct.CronExpression);

		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);

		// Verify the next time the job will run
		System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));

		// Verify the scheduled job hasn't run yet.
		Account_Auth_Feature__c[] c = [SELECT Id FROM Account_Auth_Feature__c
		                                    WHERE Name = 'Scheduled Job Item'];
		System.assertEquals(c.size(), 0);

		Test.stopTest();

		// Now that the scheduled job has executed after Test.stopTest(),
		// Make sure the records were deleted
		c = [SELECT Id FROM Account_Auth_Feature__c
		     WHERE Name = 'Scheduled Job Item'];
		System.assertEquals(c.size(), 0);

	}
}