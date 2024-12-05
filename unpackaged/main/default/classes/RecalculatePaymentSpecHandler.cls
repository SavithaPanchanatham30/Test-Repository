public class RecalculatePaymentSpecHandler extends TriggerHandler {
  RecalculatePaymentSpecHelper helper;
  private List<RecalculatePaymentSpec__e> newList;
  private EventPublisher event;

  public RecalculatePaymentSpecHandler() {
    this(
      RecalculatePaymentSpecHelper.getInstance(),
      Trigger.New,
      EventPublisher.getInstance()
    );
  }

  @testVisible
  private RecalculatePaymentSpecHandler(
    RecalculatePaymentSpecHelper helper,
    List<RecalculatePaymentSpec__e> newList,
    EventPublisher event
  ) {
    this.helper = helper;
    this.newList = newList;
    this.event = event;
  }

  public override void afterInsert() {
    List<RecalculatePayments__e> eventList = helper.recalculatePaymentSpecs(
      newList
    );
    publishEvents(eventList);
  }

  public void publishEvents(List<SObject> events) {
    if (events.size() == 0) {
      return;
    }
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
  }

  public void handleErrors(List<Database.SaveResult> result) {
    for (Database.SaveResult sr : result) {
      if (!sr.isSuccess()) {
        String s = '';
        for (Database.Error err : sr.getErrors()) {
          s +=
            'Error returned : ' +
            err.getStatusCode() +
            ' - ' +
            err.getMessage();
        }
        throw new CustomException(s);
      }
    }
  }
  public class CustomException extends Exception {
  }
}