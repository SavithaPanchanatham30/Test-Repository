public with sharing class HandleCvabOverpaymentAssistant {
  List<cve__PaymentSpecification__c> paymentSpecs;

  public HandleCvabOverpaymentAssistant(
    List<cve__PaymentSpecification__c> psList
  ) {
    this.paymentSpecs = psList;
  }

  public Map<Id, List<cve__PaymentSpecification__c>> getPriorPaymentSpecs() {
    Map<Id, List<cve__PaymentSpecification__c>> result = new Map<Id, List<cve__PaymentSpecification__c>>();
    if (paymentSpecs == null || paymentSpecs.size() == 0) {
      return result;
    }
    Map<Id, CurrentClaimData> claimsMap = getCurrentClaims();
    Set<Id> absenceType = new Set<Id>();
    Set<Id> claimIds = new Set<Id>();
    for (CurrentClaimData data : claimsMap.values()) {
      absenceType.addAll(data.absenceTypes);
      claimIds.add(data.claim.id);
    }
    Map<Id, PastClaimData> pastClaims = getPastClaims(absenceType, claimIds);
    for (cve__PaymentSpecification__c ps : paymentSpecs) {
      CurrentClaimData claim = claimsMap.get(ps.cvint__AbsenceClaim__c);
      List<cve__PaymentSpecification__c> pastPsList = findPaymentSpecs(
        claim,
        pastClaims
      );
      result.put(ps.id, pastPsList);
    }
    return result;
  }

  public List<cve__PaymentSpecification__c> findPaymentSpecs(
    CurrentClaimData claimData,
    Map<Id, PastClaimData> pastClaims
  ) {
    List<cve__PaymentSpecification__c> paymentSpecList = new List<cve__PaymentSpecification__c>();
    for (Id typeId : claimData.absenceTypes) {
      if (pastClaims.containsKey(typeId)) {
        paymentSpecList.addAll(pastClaims.get(typeId).paymentSpecs);
      }
    }
    return paymentSpecList;
  }

  public Map<Id, PastClaimData> getPastClaims(
    Set<Id> absenceType,
    Set<Id> claimIds
  ) {
    Map<Id, PastClaimData> result = new Map<Id, PastClaimData>();
    Map<Id, cvab__ClaimLeave__c> absenceMap = new Map<Id, cvab__ClaimLeave__c>(
      [
        SELECT id, cvab__EmployeeLeave__c, cvab__Claim__c
        FROM cvab__ClaimLeave__c
        WHERE cvab__EmployeeLeave__c IN :absenceType
        WITH SECURITY_ENFORCED
      ]
    );
    Set<id> pastClaimIds = new Set<Id>();
    for (cvab__ClaimLeave__c leave : absenceMap.values()) {
      pastClaimIds.add(leave.cvab__Claim__c);
    }
    Map<Id, cvab__Claim__c> claimMap = new Map<Id, cvab__Claim__c>(
      [
        SELECT
          id,
          (
            SELECT
              id,
              cve__OverpaymentBeforeTax__c,
              cve__Period__c,
              cvint__AbsenceClaim__c,
              cvint__AbsenceClaim__r.cvab__Employee__c
            FROM cvint__PaymentSpecifications__r
            WHERE cve__OverpaymentBeforeTax__c > 0
          )
        FROM cvab__Claim__c
        WHERE id IN :pastClaimIds
        WITH SECURITY_ENFORCED
      ]
    );
    for (cvab__ClaimLeave__c leave : absenceMap.values()) {
      cvab__Claim__c claim = claimMap.get(leave.cvab__Claim__c);
      if (result.containsKey(leave.cvab__EmployeeLeave__c)) {
        PastClaimData pastData = result.get(leave.cvab__EmployeeLeave__c);
        pastData.paymentSpecs.addAll(claim.cvint__PaymentSpecifications__r);
        result.put(leave.cvab__EmployeeLeave__c, pastData);
      } else {
        result.put(
          leave.cvab__EmployeeLeave__c,
          new PastClaimData(
            leave.cvab__EmployeeLeave__c,
            claim.cvint__PaymentSpecifications__r
          )
        );
      }
    }

    return result;
  }

  public Map<Id, CurrentClaimData> getCurrentClaims() {
    Set<Id> claimIds = new Set<Id>();
    Map<Id, CurrentClaimData> result = new Map<Id, CurrentClaimData>();
    for (cve__PaymentSpecification__c ps : this.paymentSpecs) {
      claimIds.add(ps.cvint__AbsenceClaim__c);
    }
    Id paidLeaveID = Schema.getGlobalDescribe()
      .get('cvab__ClaimLeave__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Paid Leave')
      .getRecordTypeId();
    List<cvab__Claim__c> claimList = [
      SELECT
        id,
        cvab__StartDate__c,
        cvab__EndDate__c,
        (SELECT id FROM cvab__Leaves__r WHERE recordTypeId = :paidLeaveId)
      FROM cvab__Claim__c
      WHERE id IN :claimIds
      WITH SECURITY_ENFORCED
    ];
    Map<Id, cvab__ClaimLeave__c> absenceMap = new Map<Id, cvab__ClaimLeave__c>(
      [
        SELECT id, cvab__EmployeeLeave__c
        FROM cvab__ClaimLeave__c
        WHERE recordTypeId = :paidLeaveID AND cvab__Claim__c IN :claimIds
        WITH SECURITY_ENFORCED
      ]
    );
    for (cvab__Claim__c claim : claimList) {
      result.put(claim.id, getCurrentClaimData(claim, absenceMap));
    }
    return result;
  }

  public CurrentClaimData getCurrentClaimData(
    cvab__Claim__c claim,
    Map<Id, cvab__ClaimLeave__c> absenceMap
  ) {
    Set<Id> absenceType = new Set<Id>();
    for (cvab__ClaimLeave__c leave : claim.cvab__Leaves__r) {
      cvab__ClaimLeave__c data = absenceMap.get(leave.id);
      absenceType.add(data.cvab__EmployeeLeave__c);
    }
    return new CurrentClaimData(claim, absenceType);
  }

  public class CurrentClaimData {
    public cvab__Claim__c claim;
    public Set<Id> absenceTypes;

    public CurrentClaimData(cvab__Claim__c claim, Set<Id> absenceTypes) {
      this.claim = claim;
      this.absenceTypes = absenceTypes;
    }
  }

  public class PastClaimData {
    Id absenceType;
    List<cve__PaymentSpecification__c> paymentSpecs;
    public PastClaimData(
      Id absenceType,
      List<cve__PaymentSpecification__c> paymentSpecs
    ) {
      this.absenceType = absenceType;
      this.paymentSpecs = paymentSpecs;
    }
  }
}