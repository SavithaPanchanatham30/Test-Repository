public class EventPublisher {
  private static EventPublisher instance;

  public static EventPublisher getInstance() {
    if (instance == null) {
      instance = new EventPublisher();
    }

    return instance;
  }

  public List<Database.SaveResult> publish(List<SObject> events) {
    return EventBus.publish(events);
  }
}