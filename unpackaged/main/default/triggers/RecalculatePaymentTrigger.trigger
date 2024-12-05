trigger RecalculatePaymentTrigger on RecalculatePayments__e(after insert) {
  new RecalculatePaymentTriggerHandler().run();

}