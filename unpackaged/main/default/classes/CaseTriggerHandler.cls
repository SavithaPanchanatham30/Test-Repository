public with sharing class CaseTriggerHandler extends TriggerHandler {
  CaseTriggerHelper helper;
  ContextVariable cv;

  public CaseTriggerHandler() {
    this(
      CaseTriggerHelper.getInstance(),
      new ContextVariable(
        (List<Case>) Trigger.New,
        (List<Case>) Trigger.Old,
        (Map<Id, Case>) Trigger.newMap,
        (Map<Id, Case>) Trigger.OldMap
      )
    );
  }

  @testVisible
  private CaseTriggerHandler(CaseTriggerHelper helper, ContextVariable cv) {
    this.helper = helper;
    this.cv = cv;
    this.helper = helper.setContextVariable(this.cv);
  }

  public override void beforeUpdate() {
    helper.updateCaseFields();
  }

  public class ContextVariable {
    public List<Case> newList;
    public List<Case> oldList;
    public Map<Id, Case> newMap;
    public Map<Id, Case> oldMap;

    public ContextVariable(
      List<Case> newList,
      List<Case> oldList,
      Map<Id, Case> newMap,
      Map<Id, Case> oldMap
    ) {
      this.newList = newList;
      this.oldList = oldList;
      this.newMap = newMap;
      this.oldMap = oldMap;
    }
  }
}