public with sharing class ExplanationNoteTriggerHandler extends TriggerHandler {
  private ExplanationNoteTriggerHelper helper;
  ContextVariables contxtVars;

  public ExplanationNoteTriggerHandler() {
    this(
      ExplanationNoteTriggerHelper.getHelperInstance(),
      (List<ExplanationNoteCreatedEvent__e>) Trigger.old,
      (List<ExplanationNoteCreatedEvent__e>) Trigger.new,
      (Map<Id, ExplanationNoteCreatedEvent__e>) Trigger.newMap
    );
  }

  @TestVisible
  private ExplanationNoteTriggerHandler(
    ExplanationNoteTriggerHelper helper,
    List<ExplanationNoteCreatedEvent__e> oldList,
    List<ExplanationNoteCreatedEvent__e> newList,
    Map<Id, ExplanationNoteCreatedEvent__e> newMap
  ) {
    this.contxtVars = new ContextVariables(oldList, newList, newMap);
    if (helper != null) {
      this.helper = helper.withContextVars(contxtVars);
    }
  }

  public override void afterInsert() {
    List<cve__Claim__c> disabilityClaims = helper.getDisabilityClaims();

    if (disabilityClaims.size() > 0) {
      handleDmlUpdate(disabilityClaims);
    }
  }

  public void handleDmlUpdate(List<SObject> sobjs) {
    try {
      List<Database.SaveResult> results = Database.update(sobjs, true);
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
      throw new CustomException('Exception while updating status :- ' + e);
    }
  }

  public class CustomException extends Exception {
  }
  public class ContextVariables {
    public List<ExplanationNoteCreatedEvent__e> oldList;
    public List<ExplanationNoteCreatedEvent__e> newList;
    public Map<Id, ExplanationNoteCreatedEvent__e> newMap;

    public ContextVariables(
      List<ExplanationNoteCreatedEvent__e> oldList,
      List<ExplanationNoteCreatedEvent__e> newList,
      Map<Id, ExplanationNoteCreatedEvent__e> newMap
    ) {
      this.oldList = oldList;
      this.newList = newList;
      this.newMap = newMap;
    }
  }
}