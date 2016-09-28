public virtual class CBIUSCollectionsCtrlBase { 
	
	public String CollectionTypeAuth {get;private set;}
	public String CollectionTypeFeature {get;private set;}
	private String rtPrivate;
	public String rt {
		get {
			return rtPrivate;
		}
		set {
			rtPrivate = value;
			PageReference tmpCreateLink;
			//if (item.CBI_US_Item_Authorization_Feature__r.RecordType.DeveloperName == CBIUSCollectionsUtility.Auth_RecordType) {
			if (value == 'IA') {
				tmpCreateLink = Page.CBIUSItemAuthorizationCreate;
			} else {
				tmpCreateLink = Page.CBIUSFeatureCreate;
			}			
			RedirectNewPage = tmpCreateLink.getUrl();
		}
	}
	public String RedirectNewPage {get;set;}

	public String CollectionType;
	public void setCollectionType (String s) {
		CollectionType = s.toUpperCase();
	}
	public String getCollectionType() {
		return CollectionType;
	}
	public String RecordType_Account_USAccount {get;private set;}
	public String GoogleAnalyticsCode {get;private set;}
	public List<SelectOption> States {get;private set;}


	public String RedirectAuthFeatureId {get;set;}

	//Constructor
	public CBIUSCollectionsCtrlBase() {
		Initialize();
	}
	private void Initialize() {
		CollectionTypeAuth = 'IA';
		CollectionTypeFeature = 'F';
		RecordType_Account_USAccount = (String)Schema.SObjectType.Account
			.getRecordTypeInfosByName().get('US Account').getRecordTypeId();

		States = CBIUSCollectionsUtility.LoadStatesForUSA();

		//TODO: Pull from custom setting GA_Code__c
		GoogleAnalyticsCode = Label.Google_Analytics_Code;
	}

	public PageReference RedirectEditPage() {
		System.debug('Inside RedirectEditPage: ' + RedirectAuthFeatureId);
		if (String.isEmpty(RedirectAuthFeatureId)) {
			return null;
		}
		PageReference pr;
		System.debug('CType: ' + CollectionType);
		if (CollectionType == CollectionTypeAuth) {
			pr = Page.CBIUSItemAuthorizationEdit;
		} else {
			pr = Page.CBIUSFeatureEdit;
		}
		//Add ID to url parameters
		pr.getParameters().put('cid',RedirectAuthFeatureId);
		return pr;
	}
	
}