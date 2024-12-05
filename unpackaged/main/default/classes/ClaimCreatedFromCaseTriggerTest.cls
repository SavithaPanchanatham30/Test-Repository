@isTest
public class ClaimCreatedFromCaseTriggerTest {
  @testSetup
  static void dataSetUp() {
    cve__Claim__c cveClaim = new cve__Claim__c();
    insert cveClaim;

    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;

    List<Case> caseList = new List<Case>();
    Case cs = new Case();
    cs.CveClaim__c = cveClaim.Id;
    cs.CvabClaim__c = cvabClaim.Id;
    caseList.add(cs);

    Case cs2 = new Case();
    cs2.CveClaim__c = cveClaim.Id;
    cs2.CvabClaim__c = cvabClaim.Id;
    caseList.add(cs2);

    insert caseList;

    List<EmailMessage> emList = new List<EmailMessage>();
    EmailMessage em1 = new EmailMessage();
    em1.ParentId = cs.Id;
    emList.add(em1);

    EmailMessage em2 = new EmailMessage();
    em2.ParentId = cs2.Id;
    emList.add(em2);

    insert emList;

    List<ContentVersion> cvList = new List<ContentVersion>();
    ContentVersion cv1 = new ContentVersion();
    cv1.Title = 'Test Document 1';
    cv1.PathOnClient = 'testDocument1.txt';
    cv1.VersionData = Blob.valueOf('Test Content 1');
    cvList.add(cv1);

    ContentVersion cv2 = new ContentVersion();
    cv2.Title = 'Test Document 2';
    cv2.PathOnClient = 'testDocument2.txt';
    cv2.VersionData = Blob.valueOf('Test Content 2');
    cvList.add(cv2);

    ContentVersion cv3 = new ContentVersion();
    cv3.Title = 'Test Document 3';
    cv3.PathOnClient = 'testDocument3.txt';
    cv3.VersionData = Blob.valueOf('Test Content 3');
    cvList.add(cv3);

    ContentVersion cv4 = new ContentVersion();
    cv4.Title = 'Test Document 4';
    cv4.PathOnClient = 'testDocument4.txt';
    cv4.VersionData = Blob.valueOf('Test Content 4');
    cvList.add(cv4);

    insert cvList;

    List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
    ContentDocumentLink cdl1 = new ContentDocumentLink();
    cdl1.ContentDocumentId = [
      SELECT Id
      FROM ContentDocument
      WHERE Title = 'Test Document 1'
      LIMIT 1
    ]
    .Id;
    cdl1.LinkedEntityId = caseList[0].Id;
    cdl1.ShareType = 'V';
    cdlList.add(cdl1);

    ContentDocumentLink cdl2 = new ContentDocumentLink();
    cdl2.ContentDocumentId = [
      SELECT Id
      FROM ContentDocument
      WHERE Title = 'Test Document 2'
      LIMIT 1
    ]
    .Id;
    cdl2.LinkedEntityId = caseList[0].Id;
    cdl2.ShareType = 'V';
    cdlList.add(cdl2);

    ContentDocumentLink cdl3 = new ContentDocumentLink();
    cdl3.ContentDocumentId = [
      SELECT Id
      FROM ContentDocument
      WHERE Title = 'Test Document 3'
      LIMIT 1
    ]
    .Id;
    cdl3.LinkedEntityId = em1.Id;
    cdl3.ShareType = 'V';
    cdlList.add(cdl3);

    ContentDocumentLink cdl4 = new ContentDocumentLink();
    cdl4.ContentDocumentId = [
      SELECT Id
      FROM ContentDocument
      WHERE Title = 'Test Document 4'
      LIMIT 1
    ]
    .Id;
    cdl4.LinkedEntityId = em2.Id;
    cdl4.ShareType = 'V';
    cdlList.add(cdl4);

    insert cdlList;
  }

  @isTest
  static void cveDocumentsCreation() {
    Id cveClaimId = [SELECT Id FROM cve__Claim__c].Id;
    Id caseId = [SELECT Id FROM Case LIMIT 1].Id;

    List<ClaimCreatedFromCase__e> pEventList = new List<ClaimCreatedFromCase__e>();
    ClaimCreatedFromCase__e pEvent = new ClaimCreatedFromCase__e();
    pEvent.CveClaimId__c = cveClaimId;
    pEvent.IntakeCaseId__c = caseId;
    pEventList.add(pEvent);

    ClaimCreatedFromCaseTriggerHandler handler = new ClaimCreatedFromCaseTriggerHandler(
      ClaimCreatedFromCaseTriggerHelper.getInstance(),
      pEventList,
      null
    );

    test.StartTest();
    handler.afterInsert();
    test.StopTest();

    // Verify if the cve documents were inserted successfully for cve Claims
    List<cve__Document__c> cveDocument = [
      SELECT Id
      FROM cve__Document__c
      WHERE cve__Claim__c = :cveClaimId
    ];

    Assert.areNotEqual(
      null,
      cveDocument,
      'cve documents are not created successfully.'
    );
    Assert.areEqual(
      3,
      cveDocument.size(),
      'Expected 3 cve documents to be created.'
    );
  }

  @isTest
  static void cvabDocumentsCreation() {
    Id cvabClaimId = [SELECT Id FROM cvab__Claim__c].Id;
    Id caseId = [SELECT Id FROM Case LIMIT 1].Id;

    List<ClaimCreatedFromCase__e> pEventList = new List<ClaimCreatedFromCase__e>();
    ClaimCreatedFromCase__e pEvent = new ClaimCreatedFromCase__e();
    pEvent.CvabClaimId__c = cvabClaimId;
    pEvent.IntakeCaseId__c = caseId;
    pEventList.add(pEvent);

    ClaimCreatedFromCaseTriggerHandler handler = new ClaimCreatedFromCaseTriggerHandler(
      ClaimCreatedFromCaseTriggerHelper.getInstance(),
      pEventList,
      null
    );

    test.StartTest();
    handler.afterInsert();
    test.StopTest();

    // Verify if the cvab documents were inserted successfully for cvab Claims
    List<cvab__Document__c> cvabDocument = [
      SELECT Id
      FROM cvab__Document__c
      WHERE cvab__Claim__c = :cvabClaimId
    ];

    Assert.areNotEqual(
      null,
      cvabDocument,
      'cvab documents are not created successfully.'
    );
    Assert.areEqual(
      3,
      cvabDocument.size(),
      'Expected 3 cvab documents to be created.'
    );
  }

  @isTest
  static void triggerTest() {
    Boolean errorOccurred = false;
    Id cvabClaimId = [SELECT Id FROM cvab__Claim__c].Id;
    Id cveClaimId = [SELECT Id FROM cve__Claim__c].Id;
    Id caseId = [SELECT Id FROM Case LIMIT 1].Id;

    List<ClaimCreatedFromCase__e> pEventList = new List<ClaimCreatedFromCase__e>();
    ClaimCreatedFromCase__e pEvent = new ClaimCreatedFromCase__e();
    pEvent.CvabClaimId__c = cvabClaimId;
    pEvent.CveClaimId__c = cveClaimId;
    pEvent.IntakeCaseId__c = caseId;
    pEventList.add(pEvent);

    List<Database.SaveResult> results;

    Test.startTest();
    try {
      EventPublisher eventp = EventPublisher.getInstance();
      results = eventp.publish(pEventList);
    } catch (Exception e) {
      errorOccurred = true;
    }
    Test.stopTest();

    // Verify if the cvab documents were inserted successfully for cvab Claims
    List<cvab__Document__c> cvabDocument = [
      SELECT Id
      FROM cvab__Document__c
      WHERE cvab__Claim__c = :cvabClaimId
    ];

    Assert.areNotEqual(
      null,
      cvabDocument,
      'cvab documents are not created successfully.'
    );
    Assert.areEqual(
      3,
      cvabDocument.size(),
      'Expected 3 cvab documents to be created.'
    );

    // Verify if the cve documents were inserted successfully for cve Claims
    List<cve__Document__c> cveDocument = [
      SELECT Id
      FROM cve__Document__c
      WHERE cve__Claim__c = :cveClaimId
    ];

    Assert.areNotEqual(
      null,
      cveDocument,
      'cve documents are not created successfully.'
    );
    Assert.areEqual(
      3,
      cveDocument.size(),
      'Expected 3 cve documents to be created.'
    );
  }

  @isTest
  static void populateAbsenceClaimTest() {
    cvab__Claim__c absenceClm = [
      SELECT Id, IntakeCase__c, EmployeeStatement__c
      FROM cvab__Claim__c
      LIMIT 1
    ];
    Case cs = [SELECT Id, Employee_Statement__c FROM Case LIMIT 1];
    cs.Employee_Statement__c = true;
    update cs;
    List<ClaimCreatedFromCase__e> pEventList = new List<ClaimCreatedFromCase__e>();
    ClaimCreatedFromCase__e pEvent = new ClaimCreatedFromCase__e();
    pEvent.CvabClaimId__c = absenceClm.Id;
    pEvent.IntakeCaseId__c = cs.Id;
    pEventList.add(pEvent);

    ClaimCreatedFromCaseTriggerHandler handler = new ClaimCreatedFromCaseTriggerHandler(
      ClaimCreatedFromCaseTriggerHelper.getInstance(),
      pEventList,
      null
    );
    Id withoutPopulateIntakeCase = absenceClm.IntakeCase__c;

    test.StartTest();
    handler.afterInsert();
    test.StopTest();
    cvab__claim__c abclm = [
      SELECT id, IntakeCase__c, EmployeeStatement__c
      FROM cvab__claim__c
    ];
    system.assertNotEquals(
      withoutPopulateIntakeCase,
      abclm.IntakeCase__c,
      'Case id value not copied on Absence claim from case.'
    );
    system.assertEquals(
      true,
      abclm.EmployeeStatement__c,
      'EmployeeStatement value not copied on Absence claim from case.'
    );
  }

  @isTest
  static void populateDisabilityClaimTest() {
    cve__Claim__c disabiltyClm = [
      SELECT Id, IntakeCase__c, EmployeeStatement__c
      FROM cve__Claim__c
      LIMIT 1
    ];
    Case cs = [SELECT Id, Employee_Statement__c FROM Case LIMIT 1];
    cs.Employee_Statement__c = true;
    update cs;
    List<ClaimCreatedFromCase__e> pEventList = new List<ClaimCreatedFromCase__e>();
    ClaimCreatedFromCase__e pEvent = new ClaimCreatedFromCase__e();
    pEvent.CveClaimId__c = disabiltyClm.Id;
    pEvent.IntakeCaseId__c = cs.Id;
    pEventList.add(pEvent);

    ClaimCreatedFromCaseTriggerHandler handler = new ClaimCreatedFromCaseTriggerHandler(
      ClaimCreatedFromCaseTriggerHelper.getInstance(),
      pEventList,
      null
    );
    Id withoutPopulateIntakeCase = disabiltyClm.IntakeCase__c;

    test.StartTest();
    handler.afterInsert();
    test.StopTest();
    cve__claim__c clm = [
      SELECT id, IntakeCase__c, EmployeeStatement__c
      FROM cve__claim__c
    ];
    system.assertNotEquals(
      withoutPopulateIntakeCase,
      clm.IntakeCase__c,
      'Case id value not copied on claim from case.'
    );
    system.assertEquals(
      true,
      clm.EmployeeStatement__c,
      'EmployeeStatement value not copied on claim from case.'
    );
  }
}