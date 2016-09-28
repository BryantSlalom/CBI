@isTest
private class CBIUSCollectionsCtrlBaseTest {

	@isTest
	private static void itemAuthPageVariable() {
		CBIUSCollectionsCtrlBase cb = new CBIUSCollectionsCtrlBase();
		cb = new CBIUSCollectionsCtrlBase();
		cb.rt = 'ia';
		cb.collectionType = 'ia';
		cb.RedirectAuthFeatureId = 'ia';
		cb.RedirectEditPage();
	}
	@isTest
	private static void featurePageVariables() {
		CBIUSCollectionsCtrlBase cb = new CBIUSCollectionsCtrlBase();
		cb = new CBIUSCollectionsCtrlBase();
		cb.rt = 'F';
		cb.collectionType = 'F';
		cb.RedirectAuthFeatureId = 'F';
		cb.RedirectEditPage();


	}
}