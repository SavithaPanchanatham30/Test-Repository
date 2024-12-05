trigger PaymentSpecificationTrigger on cve__PaymentSpecification__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new PaymentSpecificationTriggerHandler().run();
}