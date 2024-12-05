trigger AdditionalIncomeTrigger on AdditionalIncome__c(
  after insert,
  after update,
  after delete,
  after undelete,
  before insert,
  before update,
  before delete
) {
  new AdditionalIncomeTriggerHandler().run();
}