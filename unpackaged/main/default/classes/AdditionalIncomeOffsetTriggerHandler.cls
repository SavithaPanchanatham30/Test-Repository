public class AdditionalIncomeOffsetTriggerHandler extends TriggerHandler {
  AdditionalIncomeOffsetTriggerHelper helper;
  List<AdditionalIncomeOffset__e> eventList;
  private EventPublisher event;

  public AdditionalIncomeOffsetTriggerHandler() {
    this(
      AdditionalIncomeOffsetTriggerHelper.getInstance(),
      Trigger.New,
      EventPublisher.getInstance()
    );
  }

  @testVisible
  private AdditionalIncomeOffsetTriggerHandler(
    AdditionalIncomeOffsetTriggerHelper helper,
    List<AdditionalIncomeOffset__e> eventList,
    EventPublisher publisher
  ) {
    this.helper = helper;
    this.eventList = eventList;
    this.event = publisher;
  }

  public override void afterInsert() {
    SavePoint sp = Database.setSavepoint();

    List<OffsetEvent> eventPayload = helper.deserializePayload(eventList);
    List<cve__Adjustment__c> adjustmentsToDelete = helper.selectPreExistingAdjustments(
      eventPayload
    );

    if (adjustmentsToDelete.size() > 0) {
      handleDelete(adjustmentsToDelete);
    }

    Map<Id, List<cve__Adjustment__c>> adjustmentWithPaymentSpec = helper.generateNewAdjustments(
      eventPayload
    );

    List<cve__Adjustment__c> adjustmentList = new List<cve__Adjustment__c>();
    for (
      List<cve__Adjustment__c> adjList : adjustmentWithPaymentSpec.values()
    ) {
      adjustmentList.addAll(adjList);
    }

    try {
      handleInsert(adjustmentList, true);
    } catch (Exception e) {
      Database.rollback(sp);
      throw e;
    }

    List<RecalculatePayments__e> paymentSpecsToRecalculate = helper.generateEvents(
      adjustmentWithPaymentSpec.keySet()
    );
    publishEvents(paymentSpecsToRecalculate);
  }

  private void handleInsert(List<SObject> adjustmentList) {
    handleInsert(adjustmentList, false);
    List<Database.SaveResult> srs = Database.insert(adjustmentList, false);
    handleErrors(srs);
  }

  private void handleInsert(
    List<SObject> adjustmentList,
    Boolean allOrNothing
  ) {
    List<Database.SaveResult> srs = Database.insert(
      adjustmentList,
      allOrNothing
    );
    handleErrors(srs);
  }

  private void handleDelete(List<SObject> adjustmentList) {
    List<Database.DeleteResult> drs = Database.delete(adjustmentList, false);
    handleErrors(drs);
  }

  private void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
  }

  private void handleErrors(List<Database.SaveResult> result) {
    for (Database.SaveResult sr : result) {
      if (sr.isSuccess()) {
        system.debug('Save successful');
      } else {
        for (Database.Error err : sr.getErrors()) {
          system.debug(
            'Error returned : ' + err.getStatusCode() + ' - ' + err.getMessage()
          );
        }
      }
    }
  }

  private void handleErrors(List<Database.DeleteResult> result) {
    for (Database.DeleteResult dr : result) {
      if (dr.isSuccess()) {
        system.debug('Delete successful');
      } else {
        for (Database.Error err : dr.getErrors()) {
          system.debug(
            'Error returned : ' + err.getStatusCode() + ' - ' + err.getMessage()
          );
        }
      }
    }
  }
}