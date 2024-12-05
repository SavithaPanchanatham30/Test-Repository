trigger CoverageClaimedTrigger on cve__CoverageClaimed__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CoverageClaimedTriggerHandler().run();
}