public class CvabDocumentTriggerHelper {
  private cvabDocumentTriggerHandler.ContextVariables contxtVars;
  private static CvabDocumentTriggerHelper instance = null;

  public static CvabDocumentTriggerHelper getInstance() {
    if (instance == null) {
      instance = new CvabDocumentTriggerHelper();
    }

    return instance;
  }

  public CvabDocumentTriggerHelper withContextVars(
    cvabDocumentTriggerHandler.ContextVariables contxtVars
  ) {
    this.contxtVars = contxtVars;
    return this;
  }

  public void updateDocumentUrl() {
    Map<Id, String> documentbyUrl = getDocumentbyUrls();
    putDocumentbyUrls(documentbyUrl);
  }

  public void putDocumentbyUrls(Map<Id, String> documentbyUrl) {
    for (cvab__Document__c document : contxtVars.newList) {
      document.cvab__Url__c = documentbyUrl.get(document.Id);
    }
  }

  public Map<Id, String> getDocumentbyUrls() {
    Map<Id, String> documentbyUrl = new Map<Id, String>();
    for (cvab__Document__c document : contxtVars.oldList) {
      documentbyUrl.put(document.Id, document.cvab__Url__c);
    }
    return documentbyUrl;
  }
}