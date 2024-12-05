trigger CvabDocumentTrigger on cvab__Document__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CvabDocumentTriggerHandler().run();

}