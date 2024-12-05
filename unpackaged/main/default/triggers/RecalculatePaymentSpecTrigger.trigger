trigger RecalculatePaymentSpecTrigger on RecalculatePaymentSpec__e(
  after insert
) {
  new RecalculatePaymentSpecHandler().run();
}