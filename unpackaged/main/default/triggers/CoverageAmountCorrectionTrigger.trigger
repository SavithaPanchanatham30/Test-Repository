trigger CoverageAmountCorrectionTrigger on CoverageAmountCorrection__e(
  after insert
) {
  new CoverageAmountCorrectionHandler().run();
}