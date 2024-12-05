public without sharing class AdjustmentTriggerHandler extends TriggerHandler {
  AdjustmentTriggerHelper helper;
  private HandleOverpaymentHelper overpaymentHelper;
  ContextVariables contxt;
  EventPublisher event;

  private enum DMLOperationType {
    INSERT_OP,
    UPDATE_OP,
    UPSERT_OP,
    DELETE_OP,
    UNDELETE_OP
  }

  public AdjustmentTriggerHandler() {
    this(
      AdjustmentTriggerHelper.getInstance(),
      new ContextVariables()
        .withOldList((List<cve__Adjustment__c>) Trigger.Old)
        .withNewList((List<cve__Adjustment__c>) Trigger.New)
        .withOldMap((Map<Id, cve__Adjustment__c>) Trigger.OldMap)
        .withNewMap((Map<Id, cve__Adjustment__c>) Trigger.NewMap),
      EventPublisher.getInstance()
    );
  }

  @TestVisible
  private AdjustmentTriggerHandler(
    AdjustmentTriggerHelper helper,
    ContextVariables contxt
  ) {
    this(helper, contxt, EventPublisher.getInstance());
  }

  @TestVisible
  private AdjustmentTriggerHandler(
    AdjustmentTriggerHelper helper,
    ContextVariables contxt,
    EventPublisher event
  ) {
    this.contxt = contxt;
    if (helper != null) {
      this.helper = helper.withContextVariables(contxt);
    }
    this.event = event;
  }

  @TestVisible
  private AdjustmentTriggerHandler setHandleOverpaymentHelper(
    HandleOverpaymentHelper helper
  ) {
    this.overpaymentHelper = helper;
    return this;
  }

  public override void beforeInsert() {
    helper.updateTaxabilityOverride();
  }

  public override void afterInsert() {
    if (overpaymentHelper == null && !Test.isRunningTest()) {
      setHandleOverpaymentHelper(new HandleOverpaymentHelper());
    }
    if (overpaymentHelper != null) {
      Set<Id> psIds = overpaymentHelper.filterAdjustments(this.contxt.newList);
      List<RecalculatePayments__e> eventList = overpaymentHelper.generateEvents(
        psIds,
        false
      );
      if (eventList != null && eventList.size() > 0) {
        List<cve__Adjustment__c> adjList = overpaymentHelper.updateAdjustments(
          eventList
        );
        TriggerHandler.bypass('AdjustmentTriggerHandler');
        handleUpdate(new Map<Id, cve__Adjustment__c>(adjList));
        TriggerHandler.clearAllBypasses();
        publishEvents(eventList);
      }
    }
  }

  public void handleDelete(List<SObject> sobjectList) {
    try {
      List<Database.DeleteResult> results = Database.delete(sobjectList);
      handleErrors(results);
    } catch (Exception e) {
      throw new CustomException('Exception while deleting :- ' + e);
    }
  }

  public override void beforeUpdate() {
    helper.updateTaxabilityOverride();
  }

  public override void afterUpdate() {
    if (overpaymentHelper == null && !Test.isRunningTest()) {
      setHandleOverpaymentHelper(new HandleOverpaymentHelper());
    }
    if (overpaymentHelper != null) {
      Set<Id> psIds = overpaymentHelper.filterAdjustments(this.contxt.newList);
      List<RecalculatePayments__e> eventList = overpaymentHelper.generateEvents(
        psIds,
        false
      );
      if (eventList != null && eventList.size() > 0) {
        List<cve__Adjustment__c> adjList = overpaymentHelper.updateAdjustments(
          eventList
        );
        TriggerHandler.bypass('AdjustmentTriggerHandler');
        handleUpdate(new Map<Id, cve__Adjustment__c>(adjList));
        TriggerHandler.clearAllBypasses();
        publishEvents(eventList);
      }
    }
  }

  public void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
  }

  private Map<Id, SObject> compareDmlLists(
    Map<Id, SObject> masterList,
    Map<Id, SObject> possibleNewAdditions,
    List<String> overwriteFieldNames
  ) {
    for (Id sObjectId : possibleNewAdditions.keySet()) {
      if (masterList?.get(sObjectId) == null) {
        masterList.put(sObjectId, possibleNewAdditions.get(sObjectId));
      } else {
        SObject sobj = masterList.get(sObjectId);
        for (String fieldName : overwriteFieldNames) {
          sobj.put(
            fieldName,
            possibleNewAdditions.get(sObjectId).get(fieldName)
          );
        }
      }
    }
    return masterList;
  }

  private void handleInsert(Map<Id, SObject> sObjectList) {
    handleInsertOrUpdate(sObjectList, DMLOperationType.INSERT_OP, false);
  }

  private void handleUpdate(Map<Id, SObject> sObjectList) {
    handleInsertOrUpdate(sObjectList, DMLOperationType.UPDATE_OP, false);
  }

  private void handleInsertOrUpdate(
    Map<Id, SObject> sObjectList,
    DMLOperationType operationType,
    Boolean allOrNothing
  ) {
    List<Database.SaveResult> srs;
    switch on operationType {
      when INSERT_OP {
        srs = Database.insert(sObjectList.values(), allOrNothing);
        handleErrors(srs);
      }
      when UPDATE_OP {
        srs = Database.update(sObjectList.values(), allOrNothing);
        handleErrors(srs);
      }
    }
  }

  public void handleErrors(List<Database.SaveResult> result) {
    for (Database.SaveResult sr : result) {
      if (!sr.isSuccess()) {
        String s = '';
        for (Database.Error err : sr.getErrors()) {
          s += 'Error: ' + err.getStatusCode() + ' ' + err.getMessage();
        }
        throw new CustomException(s);
      }
    }
  }

  public void handleErrors(List<Database.DeleteResult> result) {
    for (Database.DeleteResult sr : result) {
      if (!sr.isSuccess()) {
        String s = '';
        for (Database.Error err : sr.getErrors()) {
          s += 'Error: ' + err.getStatusCode() + ' ' + err.getMessage();
        }
        throw new CustomException(s);
      }
    }
  }

  public class ContextVariables {
    public List<cve__Adjustment__c> oldList;
    public List<cve__Adjustment__c> newList;
    public Map<Id, cve__Adjustment__c> oldMap;
    public Map<Id, cve__Adjustment__c> newMap;

    public ContextVariables() {
    }

    public ContextVariables withOldList(List<cve__Adjustment__c> adjustments) {
      this.oldList = adjustments;
      return this;
    }

    public ContextVariables withNewList(List<cve__Adjustment__c> adjustments) {
      this.newList = adjustments;
      return this;
    }

    public ContextVariables withOldMap(
      Map<Id, cve__Adjustment__c> adjustments
    ) {
      this.oldMap = adjustments;
      return this;
    }

    public ContextVariables withNewMap(
      Map<Id, cve__Adjustment__c> adjustments
    ) {
      this.newMap = adjustments;
      return this;
    }
  }

  public class CustomException extends Exception {
  }
}