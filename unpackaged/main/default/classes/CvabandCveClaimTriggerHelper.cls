public with sharing class CvabandCveClaimTriggerHelper {
  Set<id> abClaimEmpIds = new Set<id>();
  Map<id, id> mapclaimIdWithEmpId = new Map<id, id>();
  public static CvabandCveClaimTriggerHelper getInstance() {
    return new CvabandCveClaimTriggerHelper();
  }

  public List<cvab__Claim__c> verifyIfCvabClaimShouldUpdate(
    List<cvab__Claim__c> newList,
    List<cvab__Claim__c> oldList
  ) {
    List<cvab__Claim__c> result = new List<cvab__Claim__c>();
    Map<Id, cvab__Claim__c> oldMap = new Map<Id, cvab__Claim__c>(oldList);
    for (cvab__Claim__c cvabClaim : newList) {
      cvab__Claim__c oldClaim = oldMap.get(cvabClaim.id);
      if (oldClaim.TotalOverpayments__c != cvabClaim.TotalOverpayments__c) {
        result.add(cvabClaim);
      }
    }
    return result;
  }

  public List<cve__Claim__c> verifyIfCveClaimShouldUpdate(
    List<cve__Claim__c> newList,
    List<cve__Claim__c> oldList
  ) {
    List<cve__Claim__c> result = new List<cve__Claim__c>();
    Map<Id, cve__Claim__c> oldMap = new Map<Id, cve__Claim__c>(oldList);
    for (cve__Claim__c cveClaim : newList) {
      cve__Claim__c oldClaim = oldMap.get(cveClaim.id);
      if (oldClaim.cve__OverpaymentNet__c != cveClaim.cve__OverpaymentNet__c) {
        result.add(cveClaim);
      }
    }
    return result;
  }

  public List<Contact> rollupOverpayments(List<SObject> claimList) {
    List<Contact> result = new List<Contact>();
    Set<Id> contactIds = new Set<Id>();
    if (claimList == null && claimList.size() == 0) {
      return result;
    }

    for (SObject claim : claimList) {
      if (claim instanceof cvab__Claim__c) {
        cvab__Claim__c cvabClaim = (cvab__Claim__c) claim;
        contactIds.add(cvabClaim.cvab__Employee__c);
      } else if (claim instanceof cve__Claim__c) {
        cve__Claim__c cveClaim = (cve__Claim__c) claim;
        contactIds.add(cveClaim.cve__ClaimantInsured__c);
      } else {
        return null;
      }
    }

    List<Contact> contactList = [
      SELECT
        id,
        (
          SELECT id
          FROM cvab__EmployeeClaim__r
          WHERE TotalOverpayments__c > 0
        ),
        (
          SELECT id
          FROM cve__Claims__r
          WHERE cve__OverpaymentNet__c > 0 OR cve__OverpaymentBeforeTax__c > 0
        )
      FROM Contact
      WHERE Id IN :contactIds
    ];

    for (Contact c : contactList) {
      Contact con = new Contact(Id = c.Id);
      Boolean flag = false;
      if (
        c.cvab__EmployeeClaim__r != null &&
        c.cvab__EmployeeClaim__r.size() > 0
      ) {
        con.HasCvabOverpayment__c = true;
        flag = true;
      } else {
        con.HasCvabOverpayment__c = false;
        flag = false;
      }
      if (c.cve__Claims__r != null && c.cve__Claims__r.size() > 0) {
        con.HasCveOverpayment__c = true;
        flag = true;
      } else {
        con.HasCveOverpayment__c = false;
        flag = flag ? true : false;
      }
      con.HasOverPayment__c = flag;
      result.add(con);
    }

    return result;
  }

  public void setCvabClaimStatus(
    List<cvab__Claim__c> newList,
    Map<Id, cvab__Claim__c> oldMap
  ) {
    for (cvab__Claim__c cvabClaim : newList) {
      cvab__Claim__c oldClaim = oldMap != null &&
        oldMap.containsKey(cvabClaim.id)
        ? oldMap.get(cvabClaim.id)
        : null;
      if (
        oldClaim != null &&
        cvabClaim.UsableCvabStatus__c != oldClaim.UsableCvabStatus__c &&
        cvabClaim.UsableCvabStatus__c != 'Closed'
      ) {
        cvabClaim.cvab__Status__c = 'Open';
      }
      if (
        oldClaim != null &&
        cvabClaim.UsableCvabStatus__c != oldClaim.UsableCvabStatus__c &&
        cvabClaim.UsableCvabStatus__c == 'Closed'
      ) {
        cvabClaim.cvab__Status__c = 'Closed';
      }
    }
  }

  public List<UpdateCancelledStatusReason__e> updateStatusReasonOfDateRange(
    List<cvab__Claim__c> newClaimList,
    List<cvab__Claim__c> oldClaimList
  ) {
    List<UpdateCancelledStatusReason__e> result = new List<UpdateCancelledStatusReason__e>();
    Map<Id, cvab__Claim__c> oldClaimMap = new Map<Id, cvab__Claim__c>(
      oldClaimList
    );
    for (cvab__Claim__c cvabClaim : newClaimList) {
      cvab__Claim__c oldClaim = oldClaimMap.get(cvabClaim.id);
      if (
        cvabClaim.cvab__ReturnToWork__c != null &&
        (oldClaim.cvab__ReturnToWork__c == null ||
        cvabClaim.cvab__ReturnToWork__c != oldClaim.cvab__ReturnToWork__c)
      ) {
        result.add(
          new UpdateCancelledStatusReason__e(
            ClaimId__c = cvabClaim.id,
            ReturnToWork__c = cvabClaim.cvab__ReturnToWork__c
          )
        );
      }
    }
    return result;
  }

  public void updateStatusReason(
    List<cvab__Claim__c> newClaimList,
    Map<Id, cvab__Claim__c> oldClaimMap
  ) {
    set<Id> filteredClaimIds = new Set<Id>();
    map<Id, String> claimStatusById = new Map<Id, String>();
    for (cvab__Claim__c claim : newClaimList) {
      if (
        claim.cvab__AbsenceStatus__c !=
        oldClaimMap.get(claim.Id).cvab__AbsenceStatus__c
      ) {
        filteredClaimIds.add(claim.Id);
        claimStatusById.put(claim.Id, claim.cvab__AbsenceStatus__c);
      }
    }
    Map<Id, String> statusReasonByClaimId = getStatusReasonByClaimId(
      filteredClaimIds,
      claimStatusById
    );

    if (statusReasonByClaimId.size() > 0) {
      for (cvab__Claim__c absclaim : newClaimList) {
        if (statusReasonByClaimId.containsKey(absclaim.id)) {
          absclaim.AbsenceStatusReason__c = statusReasonByClaimId.get(
            absclaim.Id
          );
        }
      }
    }
  }

  private Map<Id, String> getStatusReasonByClaimId(
    Set<Id> filteredClaimIds,
    map<Id, String> claimStatusById
  ) {
    Map<Id, String> statusReasonByClaimId = new Map<Id, String>();
    for (cvab__ClaimLeave__c claimLeave : [
      SELECT
        Id,
        cvab__Claim__c,
        (
          SELECT Id, cvab__Status__c, cvab__StatusReason__c
          FROM cvab__Dates__r
          ORDER BY createdDate ASC
        )
      FROM cvab__ClaimLeave__c
      WHERE
        cvab__Claim__c IN :filteredClaimIds
        AND Name = 'Massachusetts Paid Family and Medical Leave'
      WITH SECURITY_ENFORCED
    ]) {
      if (claimLeave.cvab__Dates__r.size() > 0) {
        for (cvab__DateRange__c dateRange : claimLeave.cvab__Dates__r) {
          if (
            claimStatusById.get(claimLeave.cvab__Claim__c) ==
            dateRange.cvab__Status__c
          ) {
            statusReasonByClaimId.put(
              claimLeave.cvab__Claim__c,
              dateRange.cvab__StatusReason__c
            );
          }
        }
      }
    }
    return statusReasonByClaimId;
  }
  public List<ClaimCreatedFromCase__e> publishAbClaimEvent(
    List<cvab__Claim__c> abNewClaimRecords,
    List<cvab__Claim__c> abOldclaimRecords
  ) {
    initCollections(abNewClaimRecords, abOldclaimRecords);
    return processCases();
  }
  public boolean checkClaimWithAssociatedCase(Id claimId, case cs) {
    return mapclaimIdWithEmpId?.get(claimId) == cs.ContactId;
  }

  private void initCollections(
    List<cvab__Claim__c> newClaimRecords,
    List<cvab__Claim__c> oldclaimRecords
  ) {
    for (cvab__Claim__c newAbClm : newClaimRecords) {
      for (cvab__Claim__c oldAbClm : oldclaimRecords) {
        if (
          oldAbClm.cvab__Employee__c != null &&
          newAbClm.cvab__Employee__c != null
        ) {
          abClaimEmpIds.add(newAbClm.cvab__Employee__c);
          mapclaimIdWithEmpId.put(newAbClm.id, newAbClm.cvab__Employee__c);
        }
      }
    }
  }

  private List<ClaimCreatedFromCase__e> processCases() {
    List<ClaimCreatedFromCase__e> lstPltEvt = new List<ClaimCreatedFromCase__e>();
    if (abClaimEmpIds != null) {
      List<case> csList = [
        SELECT
          Id,
          Employee_Statement__c,
          Employee_Statement_Received__c,
          Employer_Statement__c,
          Employer_Statement_Received__c,
          Insured_Statement__c,
          Insured_Statement_Received__c,
          Itemized_Bill_Statement__c,
          Itemized_Bill_Statement_Received__c,
          Physician_Statement__c,
          Physician_Statement_Received__c,
          Birth_Certificate__c,
          Birth_Certificate_Received__c,
          ClaimIntakeLastRunByUser__c,
          ContactId
        FROM case
        WHERE
          ClaimIntakeLastRunByUser__c = :UserInfo.getUserId()
          AND ContactId IN :abClaimEmpIds
      ];

      for (Id abClaimId : mapclaimIdWithEmpId.keySet()) {
        for (case cs : csList) {
          if (checkClaimWithAssociatedCase(abClaimId, cs)) {
            ClaimCreatedFromCase__e pe = new ClaimCreatedFromCase__e();
            pe.IntakeCaseId__c = cs.id;
            pe.CvabClaimId__c = abClaimId;
            lstPltEvt.add(pe);
          }
        }
      }
    }
    return lstPltEvt;
  }
  public void claimTATCalculation(
    List<cvab__Claim__c> newClaims,
    Map<Id, cvab__Claim__c> oldClaimMap
  ) {
    try {
      Map<Id, date> claimCaseCreatedDateMap = new Map<Id, date>();
      for (cvab__Claim__c claim : [
        SELECT
          Id,
          (
            SELECT Id, Createddate
            FROM CvabClaim__r
            ORDER BY CreatedDate
            LIMIT 1
          )
        FROM cvab__Claim__c
        WHERE Id IN :newClaims
      ]) {
        if (claim.CvabClaim__r != null && claim.CvabClaim__r.size() > 0) {
          DateTime dT = claim.CvabClaim__r[0].Createddate;
          Date caseCreatedDate = Date.newInstance(
            dT.year(),
            dT.month(),
            dT.day()
          );
          claimCaseCreatedDateMap.put(claim.Id, caseCreatedDate);
        }
      }
      claimUpdate(claimCaseCreatedDateMap, newClaims, oldClaimMap);
    } catch (Exception e) {
      throw new CustomException(
        'Exception caught at :: ' + e.getLineNumber() + ' :: ' + e.getMessage()
      );
    }
  }

  public void claimUpdate(
    Map<Id, date> claimCaseCreatedDateMap,
    List<cvab__Claim__c> newClaims,
    Map<Id, cvab__Claim__c> oldClaimsMap
  ) {
    for (cvab__Claim__c newClaim : newClaims) {
      newClaim.CaseCreatedDate__c = claimCaseCreatedDateMap.get(newClaim.Id);
      if (
        oldClaimsMap.get(newClaim.Id).UsableCvabStatus__c !=
        newClaim.UsableCvabStatus__c &&
        newClaim.InitialDecisionDate__c == null &&
        newClaim.FinalDecisionDate__c == null
      ) {
        newClaim.StatusChangedDate__c = (newClaim.UsableCvabStatus__c ==
          'Pending' ||
          newClaim.UsableCvabStatus__c == 'Closed')
          ? system.today()
          : newClaim.StatusChangedDate__c;
        newClaim.FinalStatusChangedDate__c = (newClaim.UsableCvabStatus__c ==
          'Closed')
          ? system.today()
          : newClaim.FinalStatusChangedDate__c;
      }
    }
  }

  public List<cvab__Claim__c> filterCvabClaims(
    List<cvab__Claim__c> newClaims,
    List<cvab__Claim__c> oldClaims
  ) {
    List<cvab__Claim__c> result = new List<cvab__Claim__c>();
    Map<Id, cvab__Claim__c> oldMap = new Map<Id, cvab__Claim__c>(oldClaims);
    for (cvab__Claim__c cvab : newClaims) {
      cvab__Claim__c oldClaim = oldMap.get(cvab.id);
      if (
        oldClaim.cvint__DisabilityClaim__c != cvab.cvint__DisabilityClaim__c &&
        cvab.cvint__DisabilityClaim__c != null
      ) {
        result.add(cvab);
      }
    }
    return result;
  }

  public List<ClaimCreatedFromCase__e> createEvents(
    List<cvab__Claim__c> cvabClaims
  ) {
    List<ClaimCreatedFromCase__e> eventList = new List<ClaimCreatedFromCase__e>();
    Map<Id, cvab__Claim__c> cvabMap = new Map<Id, cvab__Claim__c>(cvabClaims);
    Map<Id, Case> caseMap = getClaimRelatedToClaim(cvabClaims);
    for (Id cvabId : caseMap.keySet()) {
      cvab__Claim__c cvab = cvabMap.get(cvabId);
      eventList.add(
        new ClaimCreatedFromCase__e(
          CvabClaimId__c = cvab.id,
          CveClaimId__c = cvab.cvint__DisabilityClaim__c,
          IntakeCaseId__c = caseMap.get(cvabId).id
        )
      );
    }
    return eventList;
  }

  public List<Case> linkClaimToCase(List<cvab__Claim__c> cvabList) {
    Set<Id> empIds = new Set<Id>();
    for (cvab__Claim__c cvab : cvabList) {
      if (cvab.cvab__Employee__c != null) {
        empIds.add(cvab.cvab__Employee__c);
      }
    }

    List<Case> caseList = [
      SELECT id, ContactId
      FROM Case
      WHERE
        ClaimIntakeLastRunByUser__c = :UserInfo.getUserId()
        AND ContactId IN :empIds
    ];

    for (Case cs : caseList) {
      cvab__Claim__c cvab = getClaimForCase(cs.ContactId, cvabList);
      cs.CvabClaim__c = cvab.id;
    }

    return caseList;
  }

  private cvab__Claim__c getClaimForCase(
    Id empId,
    List<cvab__Claim__c> cvabList
  ) {
    for (cvab__Claim__c cvab : cvabList) {
      if (cvab.cvab__Employee__c == empId) {
        return cvab;
      }
    }
    return null;
  }

  private Map<Id, Case> getClaimRelatedToClaim(List<cvab__Claim__c> cvabList) {
    Set<Id> cvabIds = new Map<Id, cvab__Claim__c>(cvabList).keySet();
    List<case> csList = [
      SELECT Id, CvabClaim__c
      FROM case
      WHERE CvabClaim__c IN :cvabIds
    ];

    Map<Id, Case> caseMap = new Map<Id, Case>();
    for (Case cs : csList) {
      caseMap.put(cs.CvabClaim__c, cs);
    }

    return caseMap;
  }

  public class CustomException extends Exception {
  }
}