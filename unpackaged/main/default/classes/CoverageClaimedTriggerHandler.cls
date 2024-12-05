public class CoverageClaimedTriggerHandler extends TriggerHandler {
  CoverageClaimedTriggerHelper helper;
  ContextVariable cv;
  EventPublisher event;

  public CoverageClaimedTriggerHandler() {
    this(
      CoverageClaimedTriggerHelper.getInstance(),
      new ContextVariable(
        (List<cve__CoverageClaimed__c>) Trigger.Old,
        (List<cve__CoverageClaimed__c>) Trigger.New,
        (Map<Id, cve__CoverageClaimed__c>) Trigger.OldMap,
        (Map<Id, cve__CoverageClaimed__c>) Trigger.NewMap
      ),
      EventPublisher.getInstance()
    );
  }

  @testVisible
  private CoverageClaimedTriggerHandler(
    CoverageClaimedTriggerHelper helper,
    ContextVariable cv,
    EventPublisher event
  ) {
    this.helper = helper;
    this.cv = cv;
    this.helper.setContextVariable(this.cv);
    this.event = event;
  }

  public override void afterUpdate() {
    List<UpdateCoverageClaimed__e> eventList = helper.createEvents();
    publishEvents(eventList);
  }

  public void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
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

  public class ContextVariable {
    public List<cve__CoverageClaimed__c> oldList;
    public List<cve__CoverageClaimed__c> newList;
    public Map<Id, cve__CoverageClaimed__c> oldMap;
    public Map<Id, cve__CoverageClaimed__c> newMap;

    public ContextVariable(
      List<cve__CoverageClaimed__c> oldList,
      List<cve__CoverageClaimed__c> newList,
      Map<Id, cve__CoverageClaimed__c> oldMap,
      Map<Id, cve__CoverageClaimed__c> newMap
    ) {
      this.oldList = oldList;
      this.newList = newList;
      this.oldMap = oldMap;
      this.newMap = newMap;
    }
  }
}