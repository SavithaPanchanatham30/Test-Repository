trigger DeleteZeroAdjustmentsTrigger on DeleteZeroAdjustments__e(after insert) {
  new DeleteZeroAdjustmentsTriggerHandler().run();
}