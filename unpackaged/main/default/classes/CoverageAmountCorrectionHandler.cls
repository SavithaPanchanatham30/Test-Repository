public with sharing class CoverageAmountCorrectionHandler extends TriggerHandler {
  public override void afterInsert() {
    try {
      RecalculateBenefitClaimedBatch job = new RecalculateBenefitClaimedBatch();
      Database.executeBatch(job);
    } catch (Exception e) {
      throw new CustomException(e);
    }
  }

  private class CustomException extends Exception {
  }
}