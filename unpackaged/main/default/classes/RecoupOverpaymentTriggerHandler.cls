public with sharing class RecoupOverpaymentTriggerHandler extends TriggerHandler {
  RecoupOverpaymentTriggerHelper helper;
  List<RecoupOverpayment__e> newList;
  EventPublisher event;

  @TestVisible
  private RecoupOverpaymentTriggerHandler(
    RecoupOverpaymentTriggerHelper helper,
    List<RecoupOverpayment__e> newList,
    EventPublisher event
  ) {
    this.helper = helper;
    this.newList = newList;
    this.event = event;
  }

  public RecoupOverpaymentTriggerHandler() {
    this(
      RecoupOverpaymentTriggerHelper.getInstance(),
      Trigger.New,
      EventPublisher.getInstance()
    );
  }

  public override void afterInsert() {
    Savepoint sp = Database.setsavepoint();
    RecoupOverpaymentTriggerHelper.ReturnValues result = helper.handleOverpayment(
      newList
    );
    if (result != null) {
      TriggerHandler.bypass('AdjustmentTriggerHandler');
      List<cve__Adjustment__c> adjList = helper.getAdjToBeDeleted();
      List<cve__UnallocatedPayment__c> upList = helper.getUpayToBeDeleted(
        adjList
      );
      handleUpdate(upList, sp);
      handleUpdate(helper.updateAdjToBeDeleted(adjList), sp);

      handleInsert(result.upMap.values(), sp);
      List<cve__Adjustment__c> newAdjList = helper.updateNewAdjustments(result);
      handleInsert(newAdjList, sp);
      handleUpdate(helper.updateRecoupedAdjustments(result), sp);

      List<cve__Payment__c> payList = helper.createPayments(
        result.upMap.values()
      );
      handleInsert(payList, sp);
      handleInsert(helper.createEob(payList), sp);
      if (newAdjList != null && newAdjList.size() > 0) {
        publishEvents(helper.createEvents(newAdjList));
      } else if (adjList != null && adjList.size() > 0) {
        publishEvents(helper.createEvents(adjList));
      }
      TriggerHandler.clearAllBypasses();
    }
  }

  public void handleInsert(List<SObject> sobjectList, Savepoint sp) {
    try {
      List<Database.SaveResult> results = Database.insert(sobjectList);
      handleErrors(results);
    } catch (Exception e) {
      Database.rollback(sp);
      throw new CustomException('Exception while inserting :- ' + e);
    }
  }

  public void handleUpdate(List<SObject> sobjectList, Savepoint sp) {
    try {
      List<Database.SaveResult> results = Database.update(sobjectList);
      handleErrors(results);
    } catch (Exception e) {
      Database.rollback(sp);
      throw new CustomException('Exception while updating :- ' + e);
    }
  }

  public void publishEvents(List<SObject> sobjectList) {
    try {
      List<Database.SaveResult> results = event.publish(sobjectList);
      handleErrors(results);
    } catch (Exception e) {
      throw new CustomException('Exception while publishing :- ' + e);
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