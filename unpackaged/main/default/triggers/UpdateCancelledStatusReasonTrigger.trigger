trigger UpdateCancelledStatusReasonTrigger on UpdateCancelledStatusReason__e(
  after insert
) {
  new UpdateCancelledStatusReasonHandler().run();
}