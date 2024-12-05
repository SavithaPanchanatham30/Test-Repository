trigger ClaimCreatedFromCaseTrigger on ClaimCreatedFromCase__e(after insert) {
  new ClaimCreatedFromCaseTriggerHandler().run();
}