public with sharing class CveClaimTriggerHelper {
  private static CveClaimTriggerHelper instance = null;
  public Map<Id, cve__Claim__c> oldClaims;
  public Map<Id, cve__Claim__c> newClaims;
  Set<id> claimIds = new Set<id>();
  Set<id> claimEmpIds = new Set<id>();
  Map<id, id> mapclaimIdWithEmpId = new Map<id, id>();

  Map<id, id> mapDisWithAbsence = new Map<id, id>();
  List<case> csList = new List<case>();
  List<cve__claim__c> newClaimList = new List<cve__claim__c>();
  List<cve__claim__c> lstToUpdate = new List<cve__claim__c>();

  public static CveClaimTriggerHelper getHelperInstance() {
    if (instance == null) {
      instance = new CveClaimTriggerHelper();
    }

    return instance;
  }
  public CveClaimTriggerHelper withOldMap(Map<Id, cve__Claim__c> oldClaims) {
    this.oldClaims = oldClaims;
    return this;
  }

  public CveClaimTriggerHelper withNewMap(Map<Id, cve__Claim__c> newClaims) {
    this.newClaims = newClaims;
    return this;
  }
  public List<cve__PaymentSpecification__c> setRunApprovalAs(
    List<cve__Claim__c> claimIds
  ) {
    List<cve__PaymentSpecification__c> paymentSpecificationList = [
      SELECT Id, RunApprovalAs__c
      FROM cve__PaymentSpecification__c
      WHERE cve__Claim__c IN :claimIds
    ];

    User currentUser = [
      SELECT id, Username, UserType
      FROM User
      WHERE id = :UserInfo.getUserId()
    ];

    CVCustomSwitches__c cs = CVCustomSwitches__c.getOrgDefaults();
    for (cve__PaymentSpecification__c ps : paymentSpecificationList) {
      if (
        cs.ClaimBrainIntegrationUser__c == null ||
        (cs.ClaimBrainIntegrationUser__c != null &&
        currentUser.id != cs.ClaimBrainIntegrationUser__c)
      ) {
        ps.RunApprovalAs__c = currentUser.Username;
      } else {
        ps.RunApprovalAs__c = 'ClaimBrain Integration User';
      }
    }

    return paymentSpecificationList;
  }
  public List<RecalculatePayments__e> getEventList(
    List<cve__Claim__c> autoPayTrueClaims
  ) {
    List<cve__PaymentSpecification__c> paymentSpecificationList = [
      SELECT Id
      FROM cve__PaymentSpecification__c
      WHERE cve__Claim__c IN :autoPayTrueClaims
      WITH SECURITY_ENFORCED
    ];
    List<RecalculatePayments__e> recalculatePaymentEvents = new List<RecalculatePayments__e>();
    for (cve__PaymentSpecification__c ps : paymentSpecificationList) {
      RecalculatePayments__e rp = new RecalculatePayments__e();
      rp.PaymentSpecificationId__c = ps.Id;
      recalculatePaymentEvents.add(rp);
    }
    return recalculatePaymentEvents;
  }

  public List<cve__Claim__c> getClaims() {
    List<cve__Claim__c> autoPayTrueClaims = new List<cve__Claim__c>();
    for (cve__Claim__c newClaim : newClaims.values()) {
      cve__Claim__c oldClaim = oldClaims.get(newClaim.Id);

      if (
        (oldClaim.Autopay__c != newClaim.Autopay__c) &&
        (newClaim.Autopay__c == true)
      ) {
        autoPayTrueClaims.add(newClaim);
      }
    }
    return autoPayTrueClaims;
  }

  public List<ClaimCreatedFromCase__e> publishClaimEvent(
    List<cve__Claim__c> claimRecords,
    List<cve__claim__c> oldclaimRecords
  ) {
    initCollections(claimRecords, oldclaimRecords);

    return processCases();
  }

  public boolean checkClaimWithAssociatedCase(Id claimId, case cs) {
    return mapclaimIdWithEmpId?.get(claimId) == cs.ContactId;
  }

  private void initCollections(
    List<cve__Claim__c> newClmRecords,
    List<cve__claim__c> oldClmRecords
  ) {
    for (cve__Claim__c newClm : newClmRecords) {
      for (cve__Claim__c oldClm : oldClmRecords) {
        if (
          oldClm.cve__ClaimantInsured__c == null &&
          newClm.cve__ClaimantInsured__c != null
        ) {
          claimEmpIds.add(newClm.cve__ClaimantInsured__c);

          mapclaimIdWithEmpId.put(newClm.id, newClm.cve__ClaimantInsured__c);
        }
      }
    }
  }

  private List<ClaimCreatedFromCase__e> processCases() {
    List<ClaimCreatedFromCase__e> lstPltEvt = new List<ClaimCreatedFromCase__e>();
    if (claimEmpIds != null) {
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
          ContactId,
          Claims_Comments__c
        FROM case
        WHERE
          ClaimIntakeLastRunByUser__c = :UserInfo.getUserId()
          AND ContactId IN :claimEmpIds
      ];

      for (Id claimId : mapclaimIdWithEmpId.keySet()) {
        for (case cs : csList) {
          if (checkClaimWithAssociatedCase(claimId, cs)) {
            ClaimCreatedFromCase__e pe = new ClaimCreatedFromCase__e();
            pe.IntakeCaseId__c = cs.id;
            pe.CveClaimId__c = claimId;
            lstPltEvt.add(pe);
          }
        }
      }
    }
    return lstPltEvt;
  }

  public Map<Id, Id> concurrentClaim(
    List<cve__Claim__c> claimRecords,
    List<cve__claim__c> oldclaimRecords
  ) {
    Map<id, id> mapCollection = initMapCollections(
      claimRecords,
      oldclaimRecords
    );

    return mapCollection;
  }

  private Map<id, Id> initMapCollections(
    List<cve__Claim__c> newClmRecords,
    List<cve__claim__c> oldClmRecords
  ) {
    for (cve__Claim__c newClm : newClmRecords) {
      for (cve__Claim__c oldClm : oldClmRecords) {
        if (newClm.cvint__AbsenceClaim__c != null) {
          newClaimList = newClmRecords;
          mapDisWithAbsence.put(newClm.id, newClm.cvint__AbsenceClaim__c);
        }
      }
    }

    return mapDisWithAbsence;
  }

  public List<List<SObject>> processCases(Map<Id, Id> mapDisWithAbsences) {
    List<cve__claim__c> lstToUpdate = new List<cve__claim__c>();
    List<Case> lstCaseToUpdate = new List<Case>();

    Set<Id> idsofclaimcontact = new Set<Id>();

    for (cve__claim__c clm : newClaimList) {
      if (clm.cve__ClaimantInsured__c != null && clm.IntakeCase__c == null) {
        idsofclaimcontact.add(clm.cve__ClaimantInsured__c);
      }
    }

    List<case> relatedCases = [
      SELECT
        id,
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
        Case_Comments__c,
        ContactId,
        Claims_Comments__c
      FROM case
      WHERE
        ContactId IN :idsofclaimcontact
        AND ClaimIntakeLastRunByUser__c = :UserInfo.getUserId()
    ];

    Map<Id, case> caseMap = new Map<Id, case>();
    for (case cs : relatedCases) {
      caseMap.put(cs.ContactId, cs);
    }

    for (cve__claim__c clm : newClaimList) {
      if (clm.cve__ClaimantInsured__c != null && clm.IntakeCase__c == null) {
        case cs = caseMap.get(clm.cve__ClaimantInsured__c);
        if (cs != null) {
          case updateCase = new case();
          cve__claim__c clmToUpdate = new cve__claim__c(
            Id = clm.Id,
            IntakeCase__c = cs.Id,
            IntakeComments__c = cs.Claims_Comments__c,
            EmployeeStatement__c = cs.Employee_Statement__c,
            EmployeeStatementReceived__c = getReceivedDate(
              cs.Employee_Statement__c,
              cs.Employee_Statement_Received__c
            ),
            EmployerStatement__c = cs.Employer_Statement__c,
            EmployerStatementReceived__c = getReceivedDate(
              cs.Employer_Statement__c,
              cs.Employer_Statement_Received__c
            ),
            InsuredStatement__c = cs.Insured_Statement__c,
            InsuredStatementReceived__c = getReceivedDate(
              cs.Insured_Statement__c,
              cs.Insured_Statement_Received__c
            ),
            ItemizedBillStatement__c = cs.Itemized_Bill_Statement__c,
            ItemizedBillStatementReceived__c = getReceivedDate(
              cs.Itemized_Bill_Statement__c,
              cs.Itemized_Bill_Statement_Received__c
            ),
            PhysicianStatement__c = cs.Physician_Statement__c,
            PhysicianStatementReceived__c = getReceivedDate(
              cs.Physician_Statement__c,
              cs.Physician_Statement_Received__c
            ),
            BirthCertificate__c = cs.Birth_Certificate__c,
            BirthCertificateReceived__c = getReceivedDate(
              cs.Birth_Certificate__c,
              cs.Birth_Certificate_Received__c
            )
          );
          updateCase.id = cs.Id;
          updateCase.CveClaim__c = clm.Id;
          lstToUpdate.add(clmToUpdate);
          lstCaseToUpdate.add(updateCase);
        }
      }
    }
    List<List<SObject>> returnCveclmCaseLists = new List<List<Sobject>>();
    returnCveclmCaseLists.add(lstToUpdate);
    returnCveclmCaseLists.add(lstCaseToUpdate);
    return returnCveclmCaseLists;
  }
  public date getReceivedDate(boolean flagRececivedDoc, date receivedDocDate) {
    date docDate;
    if (flagRececivedDoc) {
      docDate = receivedDocDate;
    }
    return docDate;
  }
  public void claimTATCalculation() {
    try {
      Map<Id, date> claimCaseCreatedDateMap = new Map<Id, date>();
      for (cve__Claim__c claim : [
        SELECT
          Id,
          (SELECT Id, Createddate FROM CveClaim__r ORDER BY CreatedDate LIMIT 1)
        FROM cve__Claim__c
        WHERE Id IN :newClaims.keyset()
      ]) {
        if (claim.CveClaim__r != null && claim.CveClaim__r.size() > 0) {
          DateTime dT = claim.CveClaim__r[0].Createddate;
          Date caseCreatedDate = Date.newInstance(
            dT.year(),
            dT.month(),
            dT.day()
          );
          claimCaseCreatedDateMap.put(claim.Id, caseCreatedDate);
        }
      }
      claimUpdate(claimCaseCreatedDateMap);
    } catch (Exception e) {
      throw new CustomException(
        'Exception caught at :: ' + e.getLineNumber() + ' :: ' + e.getMessage()
      );
    }
  }

  public void claimUpdate(Map<Id, date> claimCaseCreatedDateMap) {
    for (cve__Claim__c newClaim : newClaims.values()) {
      newClaim.CaseCreatedDate__c = claimCaseCreatedDateMap.get(newClaim.Id);
      if (
        oldClaims.get(newClaim.Id).cve__Status__c != newClaim.cve__Status__c &&
        newClaim.BCInitialDecisionDate__c == null &&
        newClaim.BCFinalDecisionDate__c == null
      ) {
        newClaim.StatusChangedDate__c = (newClaim.cve__Status__c == 'Pending' ||
          newClaim.cve__Status__c == 'Closed')
          ? system.today()
          : newClaim.StatusChangedDate__c;
        newClaim.FinalStatusChangedDate__c = (newClaim.cve__Status__c ==
          'Closed')
          ? system.today()
          : newClaim.FinalStatusChangedDate__c;
      }
    }
  }
  public class CustomException extends Exception {
  }
}