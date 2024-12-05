public with sharing class ExplanationNoteTriggerHelper {
  private static ExplanationNoteTriggerHelper instance = null;
  private ExplanationNoteTriggerHandler.ContextVariables contxtVars;

  public static ExplanationNoteTriggerHelper getHelperInstance() {
    if (instance == null) {
      instance = new ExplanationNoteTriggerHelper();
    }

    return instance;
  }

  public ExplanationNoteTriggerHelper withContextVars(
    ExplanationNoteTriggerHandler.ContextVariables contxtVars
  ) {
    this.contxtVars = contxtVars;
    return this;
  }

  public List<cve__Claim__c> getDisabilityClaims() {
    List<Id> disabilityIds = getDisabilityIds(contxtVars.newList);
    List<cve__Claim__c> clms = new List<cve__Claim__c>();
    if (disabilityIds.size() > 0) {
      clms = [
        SELECT Id, cve__Status__c
        FROM cve__Claim__c
        WHERE Id IN :disabilityIds
        WITH SECURITY_ENFORCED
      ];
      cve__ClaimIntakeOptions__c clmIntakeOptions = cve__ClaimIntakeOptions__c.getInstance();
      for (cve__Claim__c clm : clms) {
        clm.cve__Status__c = clmIntakeOptions.cve__InitialClaimStatus__c;
      }
    }
    return clms;
  }

  public List<Id> getDisabilityIds(
    List<ExplanationNoteCreatedEvent__e> newList
  ) {
    List<Id> disabilityIds = new List<Id>();
    for (ExplanationNoteCreatedEvent__e expNote : newList) {
      if (expNote.DisabilityClaimId__c != null) {
        disabilityIds.add(expNote.DisabilityClaimId__c);
      }
    }
    return disabilityIds;
  }
}