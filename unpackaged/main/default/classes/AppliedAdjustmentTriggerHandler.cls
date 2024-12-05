public with sharing class AppliedAdjustmentTriggerHandler extends TriggerHandler {
  private AppliedAdjustmentTriggerHelper helper;

  private EventPublisher event;
  ContextVariables contxtVars;

  public AppliedAdjustmentTriggerHandler() {
    this(
      AppliedAdjustmentTriggerHelper.getInstance(),
      EventPublisher.getInstance(),
      new ContextVariables(
        (List<cve__AppliedAdjustment__c>) Trigger.old,
        (List<cve__AppliedAdjustment__c>) Trigger.new,
        (Map<Id, cve__AppliedAdjustment__c>) Trigger.oldMap,
        (Map<Id, cve__AppliedAdjustment__c>) Trigger.newMap
      )
    );
  }

  @TestVisible
  private AppliedAdjustmentTriggerHandler(
    AppliedAdjustmentTriggerHelper helper,
    EventPublisher publisher,
    ContextVariables cv
  ) {
    this.event = publisher;
    this.contxtVars = cv;
    if (helper != null) {
      this.helper = helper.withContextVars(contxtVars);
    }
  }

  public class ContextVariables {
    public List<cve__AppliedAdjustment__c> oldList;
    public List<cve__AppliedAdjustment__c> newList;
    public Map<Id, cve__AppliedAdjustment__c> oldMap;
    public Map<Id, cve__AppliedAdjustment__c> newMap;

    public ContextVariables(
      List<cve__AppliedAdjustment__c> oldList,
      List<cve__AppliedAdjustment__c> newList,
      Map<Id, cve__AppliedAdjustment__c> oldMap,
      Map<Id, cve__AppliedAdjustment__c> newMap
    ) {
      this.oldList = oldList;
      this.newList = newList;
      this.oldMap = oldMap;
      this.newMap = newMap;
    }
  }

  public override void afterInsert() {
    List<cve__Adjustment__c> result = helper.processAppliedAdjustments();
    handleInsert(result);

    List<Id> paySpecIds = helper.getpaymentIds();
    List<RecalculatePayments__e> calcPayments = new List<RecalculatePayments__e>();
    for (Id pay : paySpecIds) {
      calcPayments.add(
        new RecalculatePayments__e(PaymentSpecificationId__c = pay)
      );
    }

    if (calcPayments.size() > 0) {
      List<Database.SaveResult> results = event.publish(calcPayments);
      handleErrors(results);
    }
  }

  private void handleErrors(List<Database.SaveResult> result) {
    for (Database.SaveResult sr : result) {
      if (!sr.isSuccess()) {
        for (Database.Error err : sr.getErrors()) {
          throw new CustomException(
            'Exception while Insering Adjustments of type Additional Income Offset :- ' +
            err
          );
        }
      }
    }
  }

  public void handleInsert(List<SObject> objList) {
    if (Schema.sObjectType.cve__Adjustment__c.isCreateable()) {
      List<Database.SaveResult> results = Database.insert(objList, true);
      handleErrors(results);
    }
    List<cve__Adjustment__c> tobeDeleted = helper.deleteAdjustmentsOnPaymentSpec();
    handleDelete(tobeDeleted);
  }

  public void handleDelete(List<SObject> objList) {
    try {
      if (Schema.sObjectType.cve__Adjustment__c.isdeletable()) {
        List<Database.deleteResult> result = Database.delete(objList, true);
        for (Database.deleteResult sr : result) {
          if (!sr.isSuccess()) {
            for (Database.Error err : sr.getErrors()) {
              throw new CustomException(
                'Exception while deleting Adjustments of type Additional Income :- ' +
                err
              );
            }
          }
        }
      }
    } catch (Exception e) {
      throw new CustomException(
        'Exception while deleting Adjustments of type Additional Income :- ' + e
      );
    }
  }

  public class CustomException extends Exception {
  }
}