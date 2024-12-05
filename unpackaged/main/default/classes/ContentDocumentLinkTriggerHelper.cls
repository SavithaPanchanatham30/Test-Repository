public with sharing class ContentDocumentLinkTriggerHelper {
  private ContentDocumentLinkTriggerHandler.ContextVariables contxtVars;
  private static ContentDocumentLinkTriggerHelper instance = null;

  public static ContentDocumentLinkTriggerHelper getInstance() {
    if (instance == null) {
      instance = new ContentDocumentLinkTriggerHelper();
    }

    return instance;
  }

  public ContentDocumentLinkTriggerHelper withContextVars(
    ContentDocumentLinkTriggerHandler.ContextVariables contxtVars
  ) {
    this.contxtVars = contxtVars;
    return this;
  }

  public List<ClaimCreatedFromCase__e> getEventList() {
    Set<Id> caseIds = getCaseIds();
    List<Case> caseList = getCasesHavingClaims(caseIds);
    List<ClaimCreatedFromCase__e> eventList = getEvents(caseList);
    return eventList;
  }

  public List<ClaimCreatedFromCase__e> getEvents(List<Case> caseList) {
    List<ClaimCreatedFromCase__e> eventList = new List<ClaimCreatedFromCase__e>();
    for (Case cs : caseList) {
      ClaimCreatedFromCase__e clmCrtedFrmCs = new ClaimCreatedFromCase__e();
      clmCrtedFrmCs.CvabClaimId__c = cs.CvabClaim__c;
      clmCrtedFrmCs.CveClaimId__c = cs.CveClaim__c;
      clmCrtedFrmCs.IntakeCaseId__c = cs.Id;
      eventList.add(clmCrtedFrmCs);
    }
    return eventList;
  }

  public Set<Id> getCaseIds() {
    Set<Id> caseIds = new Set<Id>();
    for (ContentDocumentLink cdl : contxtVars.newList) {
      String sObjName = cdl.LinkedEntityId.getSObjectType()
        .getDescribe()
        .getName();
      if (sObjName == 'Case') {
        caseIds.add(cdl.LinkedEntityId);
      }
    }
    return caseIds;
  }

  public List<Case> getCasesHavingClaims(Set<Id> caseIds) {
    List<Case> caseList = [
      SELECT Id, CvabClaim__c, CveClaim__c
      FROM case
      WHERE Id IN :caseIds AND (CvabClaim__c != NULL OR CveClaim__c != NULL)
    ];
    return caseList;
  }
}