trigger RecoupOverpaymentTrigger on RecoupOverpayment__e(after insert) {
  new RecoupOverpaymentTriggerHandler().run();
}