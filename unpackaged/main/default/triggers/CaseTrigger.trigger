trigger CaseTrigger on Case(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after undelete
) {
  new CaseTriggerHandler().run();
}