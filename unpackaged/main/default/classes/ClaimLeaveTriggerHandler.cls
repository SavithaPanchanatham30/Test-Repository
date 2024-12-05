public with sharing class ClaimLeaveTriggerHandler extends TriggerHandler {
  private ClaimLeaveTriggerHelper helper;
  ContextVariables contxtVars;

  @TestVisible
  public ClaimLeaveTriggerHandler(
    ClaimLeaveTriggerHelper helper,
    List<cvab__ClaimLeave__c> newList,
    Map<Id, cvab__ClaimLeave__c> oldMap,
    Map<Id, cvab__ClaimLeave__c> newMap
  ) {
    this.contxtVars = new ContextVariables(newList, oldMap, newMap);
    if (helper != null) {
      this.helper = helper.withContextVars(contxtVars);
    }
  }

  public ClaimLeaveTriggerHandler() {
    this(
      ClaimLeaveTriggerHelper.getInstance(),
      (List<cvab__ClaimLeave__c>) Trigger.new,
      (Map<Id, cvab__ClaimLeave__c>) Trigger.oldMap,
      (Map<Id, cvab__ClaimLeave__c>) Trigger.newMap
    );
  }

  public override void afterUpdate() {
    List<cvab__Claim__c> cvabClaims = helper.cvabClaimTATcalculation(
      this.contxtVars.newList,
      this.contxtVars.oldMap
    );
    handleUpdate(cvabClaims);

    List<cve__PaymentSpecification__c> psList = helper.updateStatusOnPaymentSpecs(
      this.contxtVars.newList,
      this.contxtVars.oldMap
    );
    handleUpdate(psList);
  }

  public void handleUpdate(List<SObject> sobjectList) {
    try {
      if (
        sobjectList == null || (sobjectList != null && sobjectList.size() == 0)
      ) {
        return;
      }

      List<Database.SaveResult> results = Database.update(
        sobjectList,
        false,
        AccessLevel.SYSTEM_MODE
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
      throw new CustomException('Exception while updating :- ' + e);
    }
  }

  public class CustomException extends Exception {
  }

  public class ContextVariables {
    public List<cvab__ClaimLeave__c> newList;
    public Map<Id, cvab__ClaimLeave__c> oldMap;
    public Map<Id, cvab__ClaimLeave__c> newMap;

    public ContextVariables(
      List<cvab__ClaimLeave__c> newList,
      Map<Id, cvab__ClaimLeave__c> oldMap,
      Map<Id, cvab__ClaimLeave__c> newMap
    ) {
      this.newList = newList;
      this.oldMap = oldMap;
      this.newMap = newMap;
    }
  }
}