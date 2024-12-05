trigger PaymentTrigger on cve__Payment__c(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  new PaymentTriggerHandler().run();
}