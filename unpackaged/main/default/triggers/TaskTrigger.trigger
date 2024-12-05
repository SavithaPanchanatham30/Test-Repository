trigger TaskTrigger on Task(
  after insert,
  after update,
  after delete,
  after undelete,
  before insert,
  before update,
  before delete
) {
  new TaskTriggerHandler().run();
}