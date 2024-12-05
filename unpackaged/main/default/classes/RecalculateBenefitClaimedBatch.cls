public with sharing class RecalculateBenefitClaimedBatch implements Database.Batchable<sObject> {
  private EventPublisher event;
  private RecalculateBenefitClaimedBatchHelper helper;

  public RecalculateBenefitClaimedBatch() {
    this.event = EventPublisher.getInstance();
    this.helper = RecalculateBenefitClaimedBatchHelper.getInstance();
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    return helper.getBenefitClaimed();
  }

  public void execute(
    Database.BatchableContext context,
    List<cve__BenefitClaimed__c> bcList
  ) {
    List<cve__BenefitClaimed__c> bcToBeUpdated = helper.updateCoverageAmount(
      bcList
    );

    TriggerHandler.bypass('BenefitClaimedTriggerHandler');
    handleUpdate(bcToBeUpdated);
    TriggerHandler.clearAllBypasses();

    if (bcToBeUpdated.size() > 0) {
      publishEvents(helper.generateEvents());
    }
  }

  public void finish(Database.BatchableContext context) {
  }

  private void handleUpdate(List<SObject> sobjectList) {
    try {
      List<Database.SaveResult> results = Database.update(
        sobjectList,
        false,
        AccessLevel.SYSTEM_MODE
      );
      handleErrors(results);
    } catch (Exception e) {
      throw new CustomException('Exception while updating :- ' + e);
    }
  }

  public void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
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

  private class CustomException extends Exception {
  }
}