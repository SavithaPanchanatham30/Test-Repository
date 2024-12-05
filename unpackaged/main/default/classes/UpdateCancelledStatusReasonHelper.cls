public with sharing class UpdateCancelledStatusReasonHelper {
  public static UpdateCancelledStatusReasonHelper getInstance() {
    return new UpdateCancelledStatusReasonHelper();
  }

  public List<cvab__DateRange__c> updateStatusReasonOfDateRange(
    List<UpdateCancelledStatusReason__e> eventList
  ) {
    List<cvab__DateRange__c> result = new List<cvab__DateRange__c>();
    set<Id> cvabClaimIds = new Set<Id>();
    Map<Id, Date> dateMap = new Map<Id, Date>();
    for (UpdateCancelledStatusReason__e event : eventList) {
      cvabClaimIds.add(event.ClaimId__c);
      dateMap.put(event.ClaimId__c, event.ReturnToWork__c);
    }

    List<cvab__ClaimLeave__c> claimLeaveList = [
      SELECT
        id,
        cvab__Claim__c,
        (
          SELECT id, cvab__StatusReason__c, cvab__StartDate__c, cvab__EndDate__c
          FROM cvab__Dates__r
          WHERE
            cvab__Status__c = 'Cancelled'
            AND cvab__StatusReason__c != 'Return to Work'
        )
      FROM cvab__ClaimLeave__c
      WHERE cvab__Claim__c IN :cvabClaimIds
    ];

    for (cvab__ClaimLeave__c cl : claimLeaveList) {
      result.addAll(
        updateDateRanges(cl.cvab__Dates__r, dateMap.get(cl.cvab__Claim__c))
      );
    }
    return result;
  }

  private List<cvab__DateRange__c> updateDateRanges(
    List<cvab__DateRange__c> dateList,
    Date returnToWork
  ) {
    List<cvab__DateRange__c> result = new List<cvab__DateRange__c>();
    for (cvab__DateRange__c dr : dateList) {
      if (
        dr.cvab__StartDate__c <= returnToWork &&
        dr.cvab__EndDate__c >= returnToWork
      ) {
        dr.cvab__StatusReason__c = 'Return to Work';
        result.add(dr);
      }
    }
    return result;
  }
}