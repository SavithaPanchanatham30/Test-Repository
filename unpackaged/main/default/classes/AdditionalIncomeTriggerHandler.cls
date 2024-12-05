public class AdditionalIncomeTriggerHandler extends TriggerHandler {
  private AdditionalIncomeTriggerHelper helper;
  private List<AdditionalIncome__c> oldList;
  private List<AdditionalIncome__c> newList;
  private EventPublisher event;

  public AdditionalIncomeTriggerHandler() {
    this(
      AdditionalIncomeTriggerHelper.getHelperInstance(),
      Trigger.Old,
      Trigger.New,
      EventPublisher.getInstance()
    );
  }

  @TestVisible
  private AdditionalIncomeTriggerHandler(
    AdditionalIncomeTriggerHelper helper,
    List<AdditionalIncome__c> oldList,
    List<AdditionalIncome__c> newList,
    EventPublisher event
  ) {
    this.helper = helper;
    this.oldList = oldList;
    this.newList = newList;
    this.event = event;
  }

  public override void afterInsert() {
    List<AdditionalIncomeOffset__e> eventList = helper.generatePlatformEvents(
      newList
    );
    publishEvents(eventList);
  }

  public override void afterUpdate() {
    List<AdditionalIncomeOffset__e> eventList = helper.generatePlatformEvents(
      newList
    );
    publishEvents(eventList);
  }

  public void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
  }

  public void handleErrors(List<Database.SaveResult> result) {
    for (Database.SaveResult sr : result) {
      if (sr.isSuccess()) {
        system.debug('Successfully Published the Event');
      } else {
        for (Database.Error err : sr.getErrors()) {
          system.debug(
            'Error returned : ' + err.getStatusCode() + ' - ' + err.getMessage()
          );
        }
      }
    }
  }
}