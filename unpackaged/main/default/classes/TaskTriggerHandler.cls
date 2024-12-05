public class TaskTriggerHandler extends TriggerHandler {
  private TaskTriggerHelper helper;
  private List<Task> newList;

  public TaskTriggerHandler() {
    this(TaskTriggerHelper.getHelperInstance(), Trigger.New);
  }

  @TestVisible
  private TaskTriggerHandler(TaskTriggerHelper helper, List<Task> newList) {
    this.newList = newList;
    this.helper = helper;
  }
  public override void beforeInsert() {
    helper.validateComment(newList);
  }
}