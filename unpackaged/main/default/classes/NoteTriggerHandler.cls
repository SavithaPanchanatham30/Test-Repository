public class NoteTriggerHandler extends TriggerHandler {
  private NoteTriggerHelper helper;
  private EventPublisher event;
  private List<Note> newList;

  public NoteTriggerHandler() {
    this(
      NoteTriggerHelper.getHelperInstance(),
      Trigger.New,
      EventPublisher.getInstance()
    );
  }

  @TestVisible
  private NoteTriggerHandler(
    NoteTriggerHelper helper,
    List<Note> newList,
    EventPublisher event
  ) {
    this.helper = helper;
    this.newList = newList;
    this.event = event;
  }

  public override void afterInsert() {
    List<ExplanationNoteCreatedEvent__e> noteEvents = helper.getEventList(
      newList
    );
    if (noteEvents.size() > 0) {
      publishEvents(noteEvents);
    }
  }

  public void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
  }

  public void handleErrors(List<Database.SaveResult> results) {
    for (Database.SaveResult sr : results) {
      if (sr.isSuccess()) {
        System.debug('Successfully published event.');
      } else {
        for (Database.Error err : sr.getErrors()) {
          System.debug(
            'Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage()
          );
        }
      }
    }
  }
}