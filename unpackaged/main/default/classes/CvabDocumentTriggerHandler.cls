public with sharing class CvabDocumentTriggerHandler extends TriggerHandler {
  private CvabDocumentTriggerHelper helper;
  ContextVariables contxtVars;

  @TestVisible
  private CvabDocumentTriggerHandler(
    CvabDocumentTriggerHelper helper,
    ContextVariables contxtVariables
  ) {
    this.contxtVars = contxtVariables;
    if (helper != null) {
      this.helper = helper.withContextVars(contxtVars);
    }
  }

  public CvabDocumentTriggerHandler() {
    this(
      CvabDocumentTriggerHelper.getInstance(),
      new ContextVariables(
        (List<cvab__Document__c>) Trigger.old,
        (List<cvab__Document__c>) Trigger.new,
        (Map<Id, cvab__Document__c>) Trigger.oldMap,
        (Map<Id, cvab__Document__c>) Trigger.newMap
      )
    );
  }

  public override void beforeUpdate() {
    helper.updateDocumentUrl();
  }

  public class ContextVariables {
    public List<cvab__Document__c> oldList;
    public List<cvab__Document__c> newList;
    public Map<Id, cvab__Document__c> oldMap;
    public Map<Id, cvab__Document__c> newMap;

    public ContextVariables(
      List<cvab__Document__c> oldList,
      List<cvab__Document__c> newList,
      Map<Id, cvab__Document__c> oldMap,
      Map<Id, cvab__Document__c> newMap
    ) {
      this.oldList = oldList;
      this.newList = newList;
      this.oldMap = oldMap;
      this.newMap = newMap;
    }
  }
}