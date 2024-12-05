public with sharing class ClaimCreatedFromCaseTriggerHelper {
  private ClaimCreatedFromCaseTriggerHandler.ContextVariables contxtVars;
  List<cve__Claim__c> lstClm = new List<cve__Claim__c>();
  List<cvab__Claim__c> lstAbClm = new List<cvab__Claim__c>();
  List<case> lstCase = new List<case>();
  Set<id> claimIds = new Set<id>();
  Set<id> abClaimIds = new Set<id>();
  List<cve__Claim__c> clmList;
  List<cvab__Claim__c> abClmList;

  Set<id> userIds = new Set<id>();
  Set<id> clempIds = new Set<id>();
  Set<id> caseIds = new Set<id>();
  Map<id, id> mapClaimWithCase = new Map<id, id>();
  List<List<SObject>> abclaimAndCaseList = new List<List<SObject>>();
  List<List<SObject>> claimAndCaseList = new List<List<SObject>>();

  public static ClaimCreatedFromCaseTriggerHelper getInstance() {
    return new ClaimCreatedFromCaseTriggerHelper();
  }

  public ClaimCreatedFromCaseTriggerHelper withContextVars(
    ClaimCreatedFromCaseTriggerHandler.ContextVariables contxtVars
  ) {
    this.contxtVars = contxtVars;
    return this;
  }

  public List<cve__Document__c> cveDocumentsCreation(
    Map<Id, Id> caseIdCveClaimIdMap
  ) {
    List<cve__Document__c> cveDocuments = new List<cve__Document__c>();
    if (!caseIdCveClaimIdMap.keySet().isEmpty()) {
      Map<Id, List<ContentDocumentLink>> caseWithFiles = getContentDocumentLinkData(
        caseIdCveClaimIdMap.keySet()
      );
      for (Id caseId : caseWithFiles.keySet()) {
        cveDocuments = getCveDocuments(
          caseId,
          caseWithFiles,
          caseIdCveClaimIdMap
        );
      }
      return cveDocuments;
    }
    return cveDocuments;
  }

  public List<cvab__Document__c> cvabDocumentsCreation(
    Map<Id, Id> caseIdCvabClaimIdMap
  ) {
    List<cvab__Document__c> cvabDocuments = new List<cvab__Document__c>();
    if (!caseIdCvabClaimIdMap.keySet().isEmpty()) {
      Map<Id, List<ContentDocumentLink>> caseWithFiles = getContentDocumentLinkData(
        caseIdCvabClaimIdMap.keySet()
      );
      for (Id caseId : caseWithFiles.keySet()) {
        cvabDocuments = getCvabDocuments(
          caseId,
          caseWithFiles,
          caseIdCvabClaimIdMap
        );
      }
      return cvabDocuments;
    }
    return cvabDocuments;
  }

  public Map<string, string> getcveClaimExistingDocuments() {
    List<Id> cveIds = new List<Id>();
    Map<string, string> cveDocumentNamebyUrl = new Map<string, string>();
    for (ClaimCreatedFromCase__e cc : contxtVars.newList) {
      cveIds.add(cc.CveClaimId__c);
    }
    List<cve__Document__c> docList = [
      SELECT Id, Name, cve__AttachmentId__c
      FROM cve__Document__c
      WHERE cve__Claim__c IN :cveIds
    ];
    for (cve__Document__c doc : docList) {
      cveDocumentNamebyUrl.put(doc.Name, doc.cve__AttachmentId__c);
    }
    return cveDocumentNamebyUrl;
  }

  public List<cve__Document__c> getCveDocuments(
    Id caseId,
    Map<Id, List<ContentDocumentLink>> caseWithFiles,
    Map<Id, Id> caseIdCveClaimIdMap
  ) {
    Map<String, cve__Document__c> cveDocumentsMap = new Map<String, cve__Document__c>();
    Map<string, string> cveDocumentNamebyUrl = getcveClaimExistingDocuments();
    for (ContentDocumentLink attachment : caseWithFiles.get(caseId)) {
      String url = cveDocumentNamebyUrl.get(attachment.ContentDocument.Title);
      if (url != attachment.ContentDocumentId) {
        if (caseIdCveClaimIdMap.containsKey(caseId)) {
          cve__Document__c cveDocument = new cve__Document__c();
          cveDocument.cve__Claim__c = caseIdCveClaimIdMap.get(caseId);
          cveDocument.Name = attachment.ContentDocument.Title;
          cveDocument.cve__AttachmentIsFile__c = true;
          cveDocument.cve__AttachmentId__c = attachment.ContentDocumentId;
          cveDocumentsMap.put(cveDocument.Name, cveDocument);
        }
      }
    }
    return cveDocumentsMap.values();
  }

  public Map<string, string> getcvabClaimExistingDocuments() {
    List<Id> cvabIds = new List<Id>();
    Map<string, string> cvabDocumentNamebyUrl = new Map<string, string>();
    for (ClaimCreatedFromCase__e cc : contxtVars.newList) {
      cvabIds.add(cc.CvabClaimId__c);
    }
    List<cvab__Document__c> docList = [
      SELECT Id, Name, cvab__Url__c
      FROM cvab__Document__c
      WHERE cvab__Claim__c IN :cvabIds
    ];
    for (cvab__Document__c doc : docList) {
      cvabDocumentNamebyUrl.put(doc.Name, doc.cvab__Url__c);
    }
    return cvabDocumentNamebyUrl;
  }

  public List<cvab__Document__c> getCvabDocuments(
    Id caseId,
    Map<Id, List<ContentDocumentLink>> caseWithFiles,
    Map<Id, Id> caseIdCvabClaimIdMap
  ) {
    Map<String, cvab__Document__c> cvabDocumentsMap = new Map<String, cvab__Document__c>();
    Map<string, string> cvabDocumentNamebyUrl = getcvabClaimExistingDocuments();
    for (ContentDocumentLink attachment : caseWithFiles.get(caseId)) {
      String url = cvabDocumentNamebyUrl.get(attachment.ContentDocument.Title);
      if (url != '/' + attachment.ContentDocumentId) {
        if (caseIdCvabClaimIdMap.containsKey(caseId)) {
          cvab__Document__c cvabDocument = new cvab__Document__c();
          cvabDocument.cvab__Claim__c = caseIdCvabClaimIdMap.get(caseId);
          cvabDocument.Name = attachment.ContentDocument.Title;
          cvabDocument.cvab__Url__c = '/' + attachment.ContentDocumentId;
          cvabDocument.cvab__Body2__c = attachment.ContentDocument.Title;
          cvabDocumentsMap.put(cvabDocument.Name, cvabDocument);
        }
      }
    }
    return cvabDocumentsMap.values();
  }

  public Map<Id, List<ContentDocumentLink>> getContentDocumentLinkData(
    Set<Id> caseIds
  ) {
    Map<Id, List<ContentDocumentLink>> caseWithFiles = new Map<Id, List<ContentDocumentLink>>();
    List<EmailMessage> emails = [
      SELECT Id, Parentid
      FROM EmailMessage
      WHERE ParentId IN :caseIds
    ];
    Set<Id> emailIds = new Set<Id>();
    List<Id> caseIdsForEmail = new List<Id>();
    for (EmailMessage email : emails) {
      emailIds.add(email.Id);
      caseIdsForEmail.add(email.ParentId);
    }
    if (caseIds.size() > 0) {
      for (ContentDocumentLink file : [
        SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN :caseIds
        WITH SECURITY_ENFORCED
      ]) {
        if (caseWithFiles.ContainsKey(file.LinkedEntityId)) {
          caseWithFiles.get(file.LinkedEntityId).add(file);
        } else {
          caseWithFiles.put(
            file.LinkedEntityId,
            new List<ContentDocumentLink>{ file }
          );
        }
      }
    }
    if (emailIds.size() <= 0) {
      return caseWithFiles;
    }
    for (ContentDocumentLink file : [
      SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN :emailIds
      WITH SECURITY_ENFORCED
    ]) {
      if (caseWithFiles.ContainsKey(caseIdsForEmail[0])) {
        caseWithFiles.get(caseIdsForEmail[0]).add(file);
      } else {
        caseWithFiles.put(
          caseIdsForEmail[0],
          new List<ContentDocumentLink>{ file }
        );
      }
    }
    return caseWithFiles;
  }

  public List<List<SObject>> subscribeClaimEvent(
    List<ClaimCreatedFromCase__e> claimRecords
  ) {
    for (ClaimCreatedFromCase__e pe : claimRecords) {
      if (pe.CveClaimId__c != null) {
        claimIds.add(pe.CveClaimId__c);
        mapClaimWithCase.put(pe.CveClaimId__c, pe.IntakeCaseId__c);
      }
      caseIds.add(pe.IntakeCaseId__c);
    }

    List<cve__Claim__c> clmList = getInsuranceClaim(claimIds);
    List<case> csList = getCase(caseIds);
    if (
      (csList != null && csList.size() > 0) &&
      (clmList != null &&
      clmList.size() > 0)
    ) {
      claimAndCaseList = populateInsurnaceClaim(clmList, csList);
    }
    return claimAndCaseList;
  }

  public List<List<SObject>> subscribeAbClaimEvent(
    List<ClaimCreatedFromCase__e> claimRecords
  ) {
    for (ClaimCreatedFromCase__e pe : claimRecords) {
      if (pe.CvabClaimId__c != null) {
        abClaimIds.add(pe.CvabClaimId__c);
        mapClaimWithCase.put(pe.CvabClaimId__c, pe.IntakeCaseId__c);
      }
      caseIds.add(pe.IntakeCaseId__c);
    }

    List<cvab__Claim__c> abClmList = getAbsenceClaim(abClaimIds);
    List<case> csList = getCase(caseIds);
    if (
      (csList != null && csList.size() > 0) &&
      (abClmList != null &&
      abClmList.size() > 0)
    ) {
      abclaimAndCaseList = populateAbsenceClaim(abClmList, csList);
    }
    return abclaimAndCaseList;
  }

  public List<cve__Claim__c> getInsuranceClaim(Set<Id> claimIds) {
    return [
      SELECT
        id,
        EmployeeStatement__c,
        EmployeeStatementReceived__c,
        EmployerStatement__c,
        EmployerStatementReceived__c,
        InsuredStatement__c,
        InsuredStatementReceived__c,
        ItemizedBillStatement__c,
        ItemizedBillStatementReceived__c,
        PhysicianStatement__c,
        PhysicianStatementReceived__c,
        BirthCertificate__c,
        BirthCertificateReceived__c,
        cve__ClaimantInsured__c,
        IntakeCase__c
      FROM cve__Claim__c
      WHERE Id IN :claimIds
    ];
  }

  public List<cvab__Claim__c> getAbsenceClaim(Set<Id> claimIds) {
    return [
      SELECT
        id,
        EmployeeStatement__c,
        EmployeeStatementReceived__c,
        EmployerStatement__c,
        EmployerStatementReceived__c,
        InsuredStatement__c,
        InsuredStatementReceived__c,
        ItemizedBillStatement__c,
        ItemizedBillStatementReceived__c,
        Physician_Statement__c,
        PhysicianStatementReceived__c,
        BirthCertificate__c,
        BirthCertificateReceived__c,
        cvab__Employee__c
      FROM cvab__Claim__c
      WHERE Id IN :claimIds
    ];
  }
  public List<case> getCase(Set<id> caseIds) {
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
        Case_Comments__c,
        Claims_Comments__c
      FROM case
      WHERE id IN :caseIds
    ];
    return csList;
  }

  public List<List<SObject>> populateAbsenceClaim(
    List<cvab__Claim__c> abClmList,
    List<Case> csList
  ) {
    for (cvab__Claim__c clm : abClmList) {
      for (case cs : csList) {
        if (mapClaimWithCase.get(clm.id) == cs.id) {
          clm.EmployeeStatement__c = cs.Employee_Statement__c;
          clm.EmployeeStatementReceived__c = getReceivedDate(
            cs.Employee_Statement__c,
            cs.Employee_Statement_Received__c
          );

          clm.EmployerStatement__c = cs.Employer_Statement__c;
          clm.EmployerStatementReceived__c = getReceivedDate(
            cs.Employer_Statement__c,
            cs.Employer_Statement_Received__c
          );

          clm.InsuredStatement__c = cs.Insured_Statement__c;
          clm.InsuredStatementReceived__c = getReceivedDate(
            cs.Insured_Statement__c,
            cs.Insured_Statement_Received__c
          );

          clm.ItemizedBillStatement__c = cs.Itemized_Bill_Statement__c;
          clm.ItemizedBillStatementReceived__c = getReceivedDate(
            cs.Itemized_Bill_Statement__c,
            cs.Itemized_Bill_Statement_Received__c
          );

          clm.Physician_Statement__c = cs.Physician_Statement__c;
          clm.PhysicianStatementReceived__c = getReceivedDate(
            cs.Physician_Statement__c,
            cs.Physician_Statement_Received__c
          );

          clm.BirthCertificate__c = cs.Birth_Certificate__c;
          clm.BirthCertificateReceived__c = getReceivedDate(
            cs.Birth_Certificate__c,
            cs.Birth_Certificate_Received__c
          );

          clm.IntakeCase__c = cs.id;
          clm.IntakeComments__c = cs.Claims_Comments__c;

          lstAbClm.add(clm);
          cs.ClaimIntakeLastRunByUser__c = null;
          cs.CvabClaim__c = clm.Id;
          lstCase.add(cs);
        }
      }
    }
    List<List<SObject>> retrunAbclmCaseLists = new List<List<Sobject>>();
    retrunAbclmCaseLists.add(lstAbClm);
    retrunAbclmCaseLists.add(lstCase);
    return retrunAbclmCaseLists;
  }

  public List<List<SObject>> populateInsurnaceClaim(
    List<cve__Claim__c> clmList,
    List<case> csList
  ) {
    for (cve__Claim__c clm : clmList) {
      for (case cs : csList) {
        if (mapClaimWithCase.get(clm.id) == cs.id) {
          clm.EmployeeStatement__c = cs.Employee_Statement__c;
          clm.EmployeeStatementReceived__c = getReceivedDate(
            cs.Employee_Statement__c,
            cs.Employee_Statement_Received__c
          );

          clm.EmployerStatement__c = cs.Employer_Statement__c;
          clm.EmployerStatementReceived__c = getReceivedDate(
            cs.Employer_Statement__c,
            cs.Employer_Statement_Received__c
          );

          clm.InsuredStatement__c = cs.Insured_Statement__c;
          clm.InsuredStatementReceived__c = getReceivedDate(
            cs.Insured_Statement__c,
            cs.Insured_Statement_Received__c
          );

          clm.ItemizedBillStatement__c = cs.Itemized_Bill_Statement__c;
          clm.ItemizedBillStatementReceived__c = getReceivedDate(
            cs.Itemized_Bill_Statement__c,
            cs.Itemized_Bill_Statement_Received__c
          );

          clm.PhysicianStatement__c = cs.Physician_Statement__c;
          clm.PhysicianStatementReceived__c = getReceivedDate(
            cs.Physician_Statement__c,
            cs.Physician_Statement_Received__c
          );

          clm.BirthCertificate__c = cs.Birth_Certificate__c;
          clm.BirthCertificateReceived__c = getReceivedDate(
            cs.Birth_Certificate__c,
            cs.Birth_Certificate_Received__c
          );

          clm.IntakeCase__c = cs.id;
          clm.IntakeComments__c = cs.Claims_Comments__c;
          lstClm.add(clm);
          cs.ClaimIntakeLastRunByUser__c = null;
          cs.CveClaim__c = clm.Id;
          lstCase.add(cs);
        }
      }
    }
    claimAndCaseList.add(lstClm);
    claimAndCaseList.add(lstCase);
    return claimAndCaseList;
  }
  public void updateInsuranceClaimAndCase(
    List<cve__Claim__c> lstClm,
    List<case> lstCase
  ) {
    if (
      Schema.sObjectType.cve__Claim__c.isUpdateable() &&
      Schema.sObjectType.cve__Claim__c.isQueryable()
    ) {
      database.update(lstClm);
    }

    if (
      Schema.sObjectType.case.isUpdateable() &&
      Schema.sObjectType.case.isQueryable()
    ) {
      database.update(lstCase);
    }
  }

  public date getReceivedDate(boolean flagRececivedDoc, date receivedDocDate) {
    date docDate;
    if (flagRececivedDoc) {
      docDate = receivedDocDate;
    }
    return docDate;
  }
}