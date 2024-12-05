trigger AppliedAdjustmentTrigger on cve__AppliedAdjustment__c(
  after insert,
  after update,
  before insert,
  before update,
  before delete,
  after delete,
  after undelete
) {
  AppliedAdjustmentTriggerHandler handler = new AppliedAdjustmentTriggerHandler();
  handler.run();
}