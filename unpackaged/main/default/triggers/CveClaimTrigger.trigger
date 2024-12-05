trigger CveClaimTrigger on cve__Claim__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CveClaimTriggerHandler().run();

}