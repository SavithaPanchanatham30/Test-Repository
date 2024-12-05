trigger AdditionalIncomeOffsetTrigger on AdditionalIncomeOffset__e(
  after insert
) {
  new AdditionalIncomeOffsetTriggerHandler().run();

}