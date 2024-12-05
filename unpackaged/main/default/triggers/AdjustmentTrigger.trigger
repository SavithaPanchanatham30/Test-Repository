trigger AdjustmentTrigger on cve__Adjustment__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new AdjustmentTriggerHandler().run();
}