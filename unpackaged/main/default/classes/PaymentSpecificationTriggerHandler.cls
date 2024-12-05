public with sharing class PaymentSpecificationTriggerHandler extends TriggerHandler {
  PaymentSpecificationTriggerHelper helper;
  private HandleOverpaymentHelper overpaymentHelper;
  ContextVariables contxtVars;
  private EventPublisher event;

  public PaymentSpecificationTriggerHandler() {
    this(
      PaymentSpecificationTriggerHelper.getInstance(),
      (List<cve__PaymentSpecification__c>) Trigger.old,
      (List<cve__PaymentSpecification__c>) Trigger.new,
      (Map<Id, cve__PaymentSpecification__c>) Trigger.oldMap,
      (Map<Id, cve__PaymentSpecification__c>) Trigger.newMap,
      EventPublisher.getInstance()
    );
  }

  @TestVisible
  private PaymentSpecificationTriggerHandler(
    PaymentSpecificationTriggerHelper helper,
    List<cve__PaymentSpecification__c> oldList,
    List<cve__PaymentSpecification__c> newList,
    Map<Id, cve__PaymentSpecification__c> oldMap,
    Map<Id, cve__PaymentSpecification__c> newMap,
    EventPublisher event
  ) {
    this.contxtVars = new ContextVariables(oldList, newList, oldMap, newMap);
    if (helper != null) {
      this.helper = helper.withContextVars(contxtVars);
    }
    this.event = event;
  }

  @TestVisible
  private PaymentSpecificationTriggerHandler setHandleOverpaymentHelper(
    HandleOverpaymentHelper helper
  ) {
    this.overpaymentHelper = helper;
    return this;
  }

  public override void beforeInsert() {
    if (helper != null) {
      helper.populateClaimants();
      helper.disableFicaAdjustments();
    }
  }

  public override void afterUpdate() {
    if (helper != null) {
      List<cvab__Claim__c> cvabClaim = helper.aggregateCvabOverpaymentAmount();
      handleUpdate(cvabClaim);
      List<cve__PaymentSpecification__c> paymentsToBeUpdated = helper.checkIfPaymentsShouldBeApproved();
      if (paymentsToBeUpdated.size() > 0) {
        List<cve__Payment__c> payments = helper.updateTheStatus(
          paymentsToBeUpdated
        );
        handleUpdate(payments);
      }
      List<id> paymentSpecIds = helper.checkIfConsolidationIsNeeded(
        paymentsToBeUpdated
      );
      if (paymentSpecIds.size() > 0) {
        consolidatePayments cp = new consolidatePayments();
        cp.consolidatePaymentsByPaymentSpecIds(paymentSpecIds);
      }

      PaymentSpecificationTriggerHelper.ReturnValues result = helper.deleteRecoupment(
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
    }
    if (overpaymentHelper == null && !Test.isRunningTest()) {
      setHandleOverpaymentHelper(new HandleOverpaymentHelper());
    }
    if (overpaymentHelper != null) {
      Set<Id> psIds = overpaymentHelper.filterPaymentSpec(
        this.contxtVars.newList,
        this.contxtVars.oldMap
      );
      List<RecalculatePayments__e> eventList = overpaymentHelper.generateEvents(
        psIds,
        false
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
  }

  public override void afterUndelete() {
    if (helper != null) {
      List<cvab__Claim__c> cvabClaim = helper.aggregateCvabOverpaymentAmount();
      handleUpdate(cvabClaim);
    }
  }

  public override void afterDelete() {
    if (helper != null) {
      List<cvab__Claim__c> cvabClaim = helper.aggregateCvabOverpaymentAmount();
      handleUpdate(cvabClaim);
    }
  }

  public void handleUpdate(List<SObject> sobjectList) {
    try {
      List<Database.SaveResult> results = Database.update(sobjectList, false);
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

  public void handleDelete(List<SObject> sobjectList) {
    try {
      List<Database.DeleteResult> results = Database.delete(sobjectList, false);
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
      throw new CustomException(
        'Exception while updating cve Contacts :- ' + e
      );
    }
  }

  public void handleInsert(List<SObject> sobjectList) {
    try {
      List<Database.SaveResult> results = Database.insert(
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

  public class ContextVariables {
    public List<cve__PaymentSpecification__c> oldList;
    public List<cve__PaymentSpecification__c> newList;
    public Map<Id, cve__PaymentSpecification__c> oldMap;
    public Map<Id, cve__PaymentSpecification__c> newMap;

    public ContextVariables(
      List<cve__PaymentSpecification__c> oldList,
      List<cve__PaymentSpecification__c> newList,
      Map<Id, cve__PaymentSpecification__c> oldMap,
      Map<Id, cve__PaymentSpecification__c> newMap
    ) {
      this.oldList = oldList;
      this.newList = newList;
      this.oldMap = oldMap;
      this.newMap = newMap;
    }
  }

  public void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
  }

  public void handleErrors(List<Database.SaveResult> result) {
    for (Database.SaveResult sr : result) {
      if (!sr.isSuccess()) {
        String s = '';
        for (Database.Error err : sr.getErrors()) {
          s += ('Error returned : ' +
          err.getStatusCode() +
          ' - ' +
          err.getMessage());
        }
        throw new CustomException(s);
      }
    }
  }

  public class CustomException extends Exception {
  }
}