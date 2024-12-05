public with sharing class CoverageClaimedTriggerHelper {
  private static CoverageClaimedTriggerHelper instance;
  private CoverageClaimedTriggerHandler.ContextVariable cv;

  public static CoverageClaimedTriggerHelper getInstance() {
    if (instance == null) {
      instance = new CoverageClaimedTriggerHelper();
    }
    return instance;
  }

  public void setContextVariable(
    CoverageClaimedTriggerHandler.ContextVariable cv
  ) {
    this.cv = cv;
  }

  public List<UpdateCoverageClaimed__e> createEvents() {
    List<UpdateCoverageClaimed__e> result = new List<UpdateCoverageClaimed__e>();
    for (cve__CoverageClaimed__c cc : cv.newList) {
      result.add(new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id));
    }
    return result;
  }
}