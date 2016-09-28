@isTest
private class CBIUSItemFeatTriggerHandlerTest {

	static testmethod void testInValidProductCodes() {


		/* This code runs as the system user*/
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(Alias = 'standt', Email = 'standarduser@testorg.com',
		                  EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
		                  LocaleSidKey = 'en_US', ProfileId = p.Id,
		                  TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduser@testorg.cbi');

		//Create the test products to compare
		//TestUtil.createBulkProducts('228', '228-552-101','80014016','033544950104','101');

		System.runAs(u) {
			Test.startTest();
			try
			{    //Inserts features with invalid Master Package Codes.
				TestUtil.createInvalidPkgCode();
			}
			catch(Exception e)
			{
				Boolean expectedExceptionThrown = e.getMessage().contains(label.Invalid_Master_Package_Code) ? true : false;
				System.AssertEquals(expectedExceptionThrown, true);
			}
			try
			{   //Inserts features with invalid Master SKU Codes.
				TestUtil.createInvalidSkuCode();
			}
			catch(Exception e)
			{
				Boolean expectedExceptionThrown = e.getMessage().contains(label.Invalid_Master_SKU_Code) ? true : false;
				System.AssertEquals(expectedExceptionThrown, true);
			}
			try
			{   //Inserts features with invalid Brand Codes.
				TestUtil.createInvalidBrandCode();
			}
			catch(Exception e)
			{
				Boolean expectedExceptionThrown = e.getMessage().contains(label.Invalid_Brand_Code) ? true : false;
				System.AssertEquals(expectedExceptionThrown, true);
			}
			try
			{   //Inserts features with invalid Retailer Codes.
				TestUtil.createInvalidGtinCode();
			}
			catch(Exception e)
			{
				Boolean expectedExceptionThrown = e.getMessage().contains(label.Invalid_Retailer_UPC) ? true : false;
				System.AssertEquals(expectedExceptionThrown, true);
			}

			Test.stopTest();
		}
	}
	
}