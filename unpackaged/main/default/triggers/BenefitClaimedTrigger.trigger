trigger BenefitClaimedTrigger on cve__BenefitClaimed__c(
  after insert,
  after update,
  after delete,
  after undelete,
  before insert,
  before update,
  before delete
) {
  new BenefitClaimedTriggerHandler().run();
}