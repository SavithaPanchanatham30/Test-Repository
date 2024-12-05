public class UpdateCoverageClaimedHandler extends TriggerHandler {
  UpdateCoverageClaimedHelper helper;
  List<UpdateCoverageClaimed__e> newList;
  EventPublisher event;

  public UpdateCoverageClaimedHandler() {
    this(
      UpdateCoverageClaimedHelper.getInstance(),
      Trigger.New,
      EventPublisher.getInstance()
    );
  }

  @TestVisible
  private UpdateCoverageClaimedHandler(
    UpdateCoverageClaimedHelper helper,
    List<UpdateCoverageClaimed__e> newList,
    EventPublisher event
  ) {
    this.helper = helper;
    this.newList = newList;
    this.event = event;
  }

  public override void afterInsert() {
    List<cve__CoverageClaimed__c> ccList = helper.processEvents(this.newList);
    TriggerHandler.bypass('CoverageClaimedTriggerHandler');
    handleUpdate(ccList);
    TriggerHandler.clearAllBypasses();
    List<cve__BenefitClaimed__c> bcc = helper.getBenefitClaimed(ccList);
    handleUpdate(bcc);
    if (event != null) {
      List<RecalculatePaymentSpec__e> eventList = helper.generateEvents(ccList);
      publishEvents(eventList);
    }
  }

  public void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
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
      throw new CustomException('Exception while  :- ' + e);
    }
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