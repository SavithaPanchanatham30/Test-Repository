trigger ClaimLeaveTrigger on cvab__ClaimLeave__c(
  after insert,
  after update,
  after delete,
  after undelete,
  before insert,
  before update,
  before delete
) {
  new ClaimLeaveTriggerHandler().run();

}