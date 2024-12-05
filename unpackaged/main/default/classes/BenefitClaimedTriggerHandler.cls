public with sharing class BenefitClaimedTriggerHandler extends TriggerHandler {
  private BenefitClaimedTriggerHelper helper;
  private HandleOverpaymentHelper overpaymentHelper;
  private EventPublisher event;
  ContextVariables contxtVars;

  @TestVisible
  public BenefitClaimedTriggerHandler(
    BenefitClaimedTriggerHelper helper,
    List<cve__BenefitClaimed__c> oldList,
    List<cve__BenefitClaimed__c> newList,
    Map<Id, cve__BenefitClaimed__c> oldMap,
    Map<Id, cve__BenefitClaimed__c> newMap,
    EventPublisher event
  ) {
    this.contxtVars = new ContextVariables(oldList, newList, oldMap, newMap);
    if (helper != null) {
      this.helper = helper.withContextVars(contxtVars);
    }
    this.event = event;
  }

  @TestVisible
  private BenefitClaimedTriggerHandler setHandleOverpaymentHelper(
    HandleOverpaymentHelper helper
  ) {
    this.overpaymentHelper = helper;
    return this;
  }

  public BenefitClaimedTriggerHandler() {
    this(
      BenefitClaimedTriggerHelper.getInstance(),
      (List<cve__BenefitClaimed__c>) Trigger.old,
      (List<cve__BenefitClaimed__c>) Trigger.new,
      (Map<Id, cve__BenefitClaimed__c>) Trigger.oldMap,
      (Map<Id, cve__BenefitClaimed__c>) Trigger.newMap,
      EventPublisher.getInstance()
    );
  }

  public override void beforeInsert() {
    Map<Id, List<usal__MemberBenefit__c>> claimantIdMemberBenefitsMap = helper.processBenefitClaimed();
    if (
      claimantIdMemberBenefitsMap != null &&
      claimantIdMemberBenefitsMap.size() > 0
    ) {
      helper.updateBenefitClaimed(claimantIdMemberBenefitsMap);
    }
    helper.getTotalCoveragesClaimedPayableAmounts();
  }

  public override void beforeUpdate() {
    Map<Id, List<usal__MemberBenefit__c>> claimantIdMemberBenefitsMap = helper.processBenefitClaimed();
    if (
      claimantIdMemberBenefitsMap != null &&
      claimantIdMemberBenefitsMap.size() > 0
    ) {
      helper.updateBenefitClaimed(claimantIdMemberBenefitsMap);
    }
    helper.getTotalCoveragesClaimedPayableAmounts();
    helper.addValidationforRejectBenefitClaim();
    List<cve__BenefitClaimed__c> newList = this.contxtVars.newMap.values();
    List<Task> bcAssociatedTasks = helper.getTasks(newList);
    handleUpdate(bcAssociatedTasks);
  }

  public override void afterUpdate() {
    BenefitClaimedTriggerHelper.ReturnValues result = helper.deleteRecoupment(
      this.contxtVars.newList,
      this.contxtVars.oldMap
    );
    if (result.adjList != null && result.adjList.size() > 0) {
      handleDelete(result.adjList);
    }
    if (result.upayList != null && result.upayList.size() > 0) {
      handleDelete(result.upayList);
    }
    if (result.eventList != null && result.eventList.size() > 0) {
      publishEvents(result.eventList);
    }

    if (overpaymentHelper == null && !Test.isRunningTest()) {
      setHandleOverpaymentHelper(new HandleOverpaymentHelper());
    }
    if (overpaymentHelper != null) {
      Set<Id> bcIds = overpaymentHelper.filterBenefitClaimed(
        this.contxtVars.newList,
        this.contxtVars.oldMap
      );
      List<RecalculatePayments__e> eventList = overpaymentHelper.generateEvents(
        bcIds,
        true
      );
      if (eventList != null && eventList.size() > 0) {
        List<cve__Adjustment__c> adjList = overpaymentHelper.updateAdjustments(
          eventList
        );
        TriggerHandler.bypass('AdjustmentTriggerHandler');
        handleUpdate(adjList);
        TriggerHandler.clearAllBypasses();
        publishEvents(eventList);
      }
    }

    List<cve__Claim__c> cveClaims = helper.benefitClaimedTATcalculation(
      this.contxtVars.newList,
      this.contxtVars.oldMap
    );
    handleUpdate(cveClaims);
    //set status reason field
    List<cve__BenefitClaimed__c> updateBC = helper.updateBcStatusReason(
      this.contxtVars.newList,
      this.contxtVars.oldMap
    );
    if (updateBC != null && updateBC.size() > 0) {
      handleUpdate(updateBC);
    }
  }

  public void handleUpdate(List<SObject> sobjectList) {
    try {
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

  public void handleDelete(List<SObject> sobjectList) {
    try {
      List<Database.DeleteResult> results = Database.delete(
        sobjectList,
        false,
        AccessLevel.SYSTEM_MODE
      );
      for (Database.DeleteResult result : results) {
        if (!result.isSuccess()) {
          String s = '';
          for (Database.Error err : result.getErrors()) {
            s += 'Error: ' + err.getStatusCode() + ' ' + err.getMessage();
          }
          throw new CustomException(s);
        }
      }
    } catch (Exception e) {
      throw new CustomException('Exception while deleting :- ' + e);
    }
  }

  public void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
  }

  public class ContextVariables {
    public List<cve__BenefitClaimed__c> oldList;
    public List<cve__BenefitClaimed__c> newList;
    public Map<Id, cve__BenefitClaimed__c> oldMap;
    public Map<Id, cve__BenefitClaimed__c> newMap;

    public ContextVariables(
      List<cve__BenefitClaimed__c> oldList,
      List<cve__BenefitClaimed__c> newList,
      Map<Id, cve__BenefitClaimed__c> oldMap,
      Map<Id, cve__BenefitClaimed__c> newMap
    ) {
      this.oldList = oldList;
      this.newList = newList;
      this.oldMap = oldMap;
      this.newMap = newMap;
    }
  }

  public void handleErrors(List<Database.SaveResult> results) {
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

  public class CustomException extends Exception {
  }
}