trigger NoteTrigger on Note(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  // invoke the run() method of a class extending the TriggerHandler virtual
  // class
  new NoteTriggerHandler().run();

}