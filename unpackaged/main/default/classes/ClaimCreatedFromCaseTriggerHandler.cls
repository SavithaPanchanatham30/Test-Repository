public with sharing class ClaimCreatedFromCaseTriggerHandler extends TriggerHandler {
  ClaimCreatedFromCaseTriggerHelper helper;
  ContextVariables contxtVars;
  List<ClaimCreatedFromCase__e> cveClaimList;
  public ClaimCreatedFromCaseTriggerHandler() {
    this(
      ClaimCreatedFromCaseTriggerHelper.getInstance(),
      (List<ClaimCreatedFromCase__e>) Trigger.New,
      (Map<Id, ClaimCreatedFromCase__e>) Trigger.NewMap
    );
  }

  @TestVisible
  private ClaimCreatedFromCaseTriggerHandler(
    ClaimCreatedFromCaseTriggerHelper helper,
    List<ClaimCreatedFromCase__e> newList,
    Map<Id, ClaimCreatedFromCase__e> newMap
  ) {
    this.contxtVars = new ContextVariables(newList, newMap);
    if (helper != null) {
      this.helper = helper.withContextVars(contxtVars);
    }
  }

  public override void afterInsert() {
    Map<Id, Id> caseIdCveClaimIdMap = new Map<Id, Id>();
    Map<Id, Id> caseIdCvabClaimIdMap = new Map<Id, Id>();
    if (helper != null && contxtVars.newList != null) {
      for (ClaimCreatedFromCase__e pe : contxtVars.newList) {
        if (pe.IntakeCaseId__c != null && pe.CveClaimId__c != null) {
          caseIdCveClaimIdMap.put(pe.IntakeCaseId__c, pe.CveClaimId__c);
        }
        if (pe.IntakeCaseId__c != null && pe.CvabClaimId__c != null) {
          caseIdCvabClaimIdMap.put(pe.IntakeCaseId__c, pe.CvabClaimId__c);
        }
      }
    }
    if (!caseIdCveClaimIdMap.isEmpty()) {
      List<cve__Document__c> cveDocuments = helper.cveDocumentsCreation(
        caseIdCveClaimIdMap
      );
      handleInsert(cveDocuments);
    }
    if (!caseIdCvabClaimIdMap.isEmpty()) {
      List<cvab__Document__c> cvabDocuments = helper.cvabDocumentsCreation(
        caseIdCvabClaimIdMap
      );
      handleInsert(cvabDocuments);
    }
    if (!caseIdCveClaimIdMap.isEmpty()) {
      List<List<Sobject>> claimCaseUpdateList = helper.subscribeClaimEvent(
        contxtVars.newList
      );
      handleUpdate(claimCaseUpdateList[0]);
      handleUpdate(claimCaseUpdateList[1]);
    }
    if (!caseIdCvabClaimIdMap.isEmpty()) {
      List<List<Sobject>> abClaimCaseUpdateList = helper.subscribeAbClaimEvent(
        contxtVars.newList
      );
      handleUpdate(abClaimCaseUpdateList[0]);
      handleUpdate(abClaimCaseUpdateList[1]);
    }
  }

  public void handleInsert(List<SObject> sobjectList) {
    List<Database.SaveResult> results = Database.insert(
      sobjectList,
      false //,
      //AccessLevel.USER_MODE
    );
    for (Database.SaveResult result : results) {
      if (!result.isSuccess()) {
        String s = '';
        for (Database.Error err : result.getErrors()) {
          s += 'Error: ' + err.getStatusCode() + ' ' + err.getMessage();
        }
        throw new CustomException(s);
      }
    }
  }
  public void handleUpdate(List<SObject> sobjectList) {
    try {
      map<id, sobject> sobjectMap = new Map<id, sobject>();
      sobjectMap.putall(sobjectList);
      List<Database.SaveResult> results = Database.update(
        sobjectMap.values(),
        false //,
        //AccessLevel.USER_MODE
      );
      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          String s = '';
          for (Database.Error err : result.getErrors()) {
            s += 'Error: ' + err.getStatusCode() + ' ' + err.getMessage();
          }
          throw new CustomException(s);
        }
      }
    } catch (Exception e) {
      throw new CustomException(
        'Exception while updating cve Contacts :- ' + e
      );
    }
  }

  public class ContextVariables {
    public List<ClaimCreatedFromCase__e> newList;
    public Map<Id, ClaimCreatedFromCase__e> newMap;

    public ContextVariables(
      List<ClaimCreatedFromCase__e> newList,
      Map<Id, ClaimCreatedFromCase__e> newMap
    ) {
      this.newList = newList;
      this.newMap = newMap;
    }
  }

  public class CustomException extends Exception {
  }
}