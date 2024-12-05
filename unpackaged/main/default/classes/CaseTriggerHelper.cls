public with sharing class CaseTriggerHelper {
  CaseTriggerHandler.ContextVariable cv;

  public static CaseTriggerHelper getInstance() {
    return new CaseTriggerHelper();
  }

  public CaseTriggerHelper setContextVariable(
    CaseTriggerHandler.ContextVariable cv
  ) {
    this.cv = cv;
    return this;
  }

  public void updateCaseFields() {
    Map<Id, Date> claimDate = getAllCreatedDates();
    for (Case c : cv.newList) {
      Case oldCase = cv.oldMap.get(c.id);
      if (
        c.InitialDecisionDate__c == null &&
        c.Status != oldCase.Status &&
        (c.Status == 'Incomplete' ||
        c.Status == 'Closed')
      ) {
        c.InitialDecisionDate__c = DateTime.now();
      }

      if (c.CvabClaim__c != null && c.IntakeDecisionTAT__c == null) {
        c.IntakeDecisionTAT__c = calculateBusinessDays(
          claimDate.get(c.CvabClaim__c),
          c.CreatedDate.date()
        );
      } else if (c.CveClaim__c != null && c.IntakeDecisionTAT__c == null) {
        c.IntakeDecisionTAT__c = calculateBusinessDays(
          claimDate.get(c.CveClaim__c),
          c.CreatedDate.date()
        );
      } else if (
        c.ClosedDate != null &&
        c.CvabClaim__c == null &&
        c.CveClaim__c == null &&
        c.ClosedDate != oldCase.ClosedDate
      ) {
        c.IntakeDecisionTAT__c = calculateBusinessDays(
          c.ClosedDate.date(),
          c.CreatedDate.date()
        );
      }
    }
  }

  private Map<Id, Date> getAllCreatedDates() {
    Set<Id> cvabIds = new Set<Id>();
    Set<Id> cveIds = new Set<Id>();
    Map<Id, Date> result = new Map<Id, Date>();

    for (Case c : cv.newList) {
      if (c.CvabClaim__c != null) {
        cvabIds.add(c.CvabClaim__c);
      }
      if (c.CveClaim__c != null) {
        cveIds.add(c.CveClaim__c);
      }
    }

    if (cvabIds.size() > 0) {
      List<cvab__Claim__c> claimList = [
        SELECT id, CreatedDate
        FROM cvab__Claim__c
        WHERE id IN :cvabIds
      ];
      for (cvab__Claim__c claim : claimList) {
        result.put(claim.id, claim.CreatedDate.date());
      }
    }

    if (cveIds.size() > 0) {
      List<cve__Claim__c> claimList = [
        SELECT id, CreatedDate
        FROM cve__Claim__c
        WHERE id IN :cveIds
      ];
      for (cve__Claim__c claim : claimList) {
        result.put(claim.id, claim.CreatedDate.date());
      }
    }

    return result;
  }

  private Decimal calculateBusinessDays(Date date1, Date date2) {
    Decimal numOfDays1 =
      (DATE.newInstance(1900, 1, 8).daysBetween(date1) + 1) / 7;
    Decimal numOfDays2 =
      (DATE.newInstance(1900, 1, 8).daysBetween(date2) + 1) / 7;
    return (5 * (numOfDays1.round(RoundingMode.DOWN)) +
      Math.MIN(
        5,
        Math.MOD(DATE.newInstance(1900, 1, 8).daysBetween(date1) + 1, 7)
      )) -
      (5 * (numOfDays2.round(RoundingMode.DOWN)) +
      Math.MIN(
        5,
        Math.MOD(DATE.newInstance(1900, 1, 8).daysBetween(date2) + 1, 7)
      ));
  }
}