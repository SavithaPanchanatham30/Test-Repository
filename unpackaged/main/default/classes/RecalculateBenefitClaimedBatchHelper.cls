public with sharing class RecalculateBenefitClaimedBatchHelper {
  public static RecalculateBenefitClaimedBatchHelper getInstance() {
    return new RecalculateBenefitClaimedBatchHelper();
  }

  public Database.QueryLocator getBenefitClaimed() {
    String stage = 'Complete';
    return Database.getQueryLocator(
      'SELECT id,cve__CoverageAmount__c,(Select id,cve__PayableAmount__c from cve__CoveragesClaimed__r) from cve__BenefitClaimed__c where ClaimBrainIntegrationStatus__c = :stage'
    );
  }

  public List<cve__BenefitClaimed__c> updateCoverageAmount(
    List<cve__BenefitClaimed__c> bcList
  ) {
    List<cve__BenefitClaimed__c> bcToBeUpdated = new List<cve__BenefitClaimed__c>();

    for (cve__BenefitClaimed__c bc : bcList) {
      Decimal totalCoverageAmount = getTotalCoverageAmount(
        bc.cve__CoveragesClaimed__r
      );
      if (bc.cve__CoverageAmount__c != totalCoverageAmount) {
        bc.cve__CoverageAmount__c = totalCoverageAmount;
        bcToBeUpdated.add(bc);
      }
    }
    return bcToBeUpdated;
  }

  private Decimal getTotalCoverageAmount(List<cve__CoverageClaimed__c> ccList) {
    Decimal total = 0;
    for (cve__CoverageClaimed__c cc : ccList) {
      total += cc.cve__PayableAmount__c;
    }
    return total;
  }

  public List<CoverageAmountCorrection__e> generateEvents() {
    List<CoverageAmountCorrection__e> result = new List<CoverageAmountCorrection__e>();
    result.add(new CoverageAmountCorrection__e());
    return result;
  }
}