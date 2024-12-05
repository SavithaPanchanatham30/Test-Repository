public class ContentDocumentLinkTriggerHandler extends TriggerHandler {
  private ContentDocumentLinkTriggerHelper helper;
  private EventPublisher event;
  ContextVariables contxtVars;

  @TestVisible
  List<ClaimCreatedFromCase__e> eventList;

  @TestVisible
  private ContentDocumentLinkTriggerHandler(
    ContentDocumentLinkTriggerHelper helper,
    ContextVariables contxtVariables,
    EventPublisher event
  ) {
    this.contxtVars = contxtVariables;
    this.event = event;
    if (helper != null) {
      this.helper = helper.withContextVars(contxtVars);
    }
  }

  public ContentDocumentLinkTriggerHandler() {
    this(
      ContentDocumentLinkTriggerHelper.getInstance(),
      new ContextVariables(
        (List<ContentDocumentLink>) Trigger.old,
        (List<ContentDocumentLink>) Trigger.new,
        (Map<Id, ContentDocumentLink>) Trigger.oldMap,
        (Map<Id, ContentDocumentLink>) Trigger.newMap
      ),
      EventPublisher.getInstance()
    );
  }

  public override void afterInsert() {
    eventList = helper.getEventList();
    if (eventList.size() > 0 && eventList != null) {
      publishEvents(eventList);
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

  public class ContextVariables {
    public List<ContentDocumentLink> oldList;
    public List<ContentDocumentLink> newList;
    public Map<Id, ContentDocumentLink> oldMap;
    public Map<Id, ContentDocumentLink> newMap;

    public ContextVariables(
      List<ContentDocumentLink> oldList,
      List<ContentDocumentLink> newList,
      Map<Id, ContentDocumentLink> oldMap,
      Map<Id, ContentDocumentLink> newMap
    ) {
      this.oldList = oldList;
      this.newList = newList;
      this.oldMap = oldMap;
      this.newMap = newMap;
    }
  }
}