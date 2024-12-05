@isTest
public class SubflowCreateDocumentTest {
  @TestSetup
  public static void createData() {
    cvab__Claim__c absence = new cvab__Claim__c();
    insert absence;

    Blob bodyBlob = Blob.valueOf(
      'Unit Test ContentVersion Body to be insert in test class for testing'
    );

    ContentVersion contentVersion1 = new ContentVersion(
      Title = 'SampleTitle',
      PathOnClient = 'SampleTitle.jpg',
      VersionData = bodyBlob,
      origin = 'H'
    );
    insert contentVersion1;

    ContentVersion contentVersion2 = [
      SELECT Id, Title, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :contentVersion1.Id
      LIMIT 1
    ];

    ContentDocumentLink contentlink = new ContentDocumentLink();
    contentlink.LinkedEntityId = absence.id;
    contentlink.contentdocumentid = contentVersion2.contentdocumentid;
    contentlink.ShareType = 'V';
    insert contentlink;

    ContentVersion contentVersionnew = new ContentVersion(
      Title = 'SampleTitle1',
      PathOnClient = 'SampleTitle1.jpg',
      VersionData = Blob.valueOf('Test Content'),
      origin = 'H'
    );
    insert contentVersionnew;

    ContentVersion contentv = [
      SELECT Id, Title, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :contentVersionnew.Id
      LIMIT 1
    ];

    ContentDocumentLink contentlink1 = new ContentDocumentLink();
    contentlink1.LinkedEntityId = absence.id;
    contentlink1.contentdocumentid = contentv.contentdocumentid;
    contentlink1.ShareType = 'V';
    insert contentlink1;

    ContentVersion contentVersionnew1 = new ContentVersion(
      Title = 'SampleTitle2',
      PathOnClient = 'SampleTitle2.jpg',
      VersionData = Blob.valueOf('Test Content in test class'),
      origin = 'H'
    );
    insert contentVersionnew1;

    ContentVersion contentv1 = [
      SELECT Id, Title, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :contentVersionnew1.Id
      LIMIT 1
    ];

    ContentDocumentLink contentlink2 = new ContentDocumentLink();
    contentlink2.LinkedEntityId = absence.id;
    contentlink2.contentdocumentid = contentv1.contentdocumentid;
    contentlink2.ShareType = 'V';
    insert contentlink2;

    cve__Claim__c disability = new cve__Claim__c();
    insert disability;

    Blob cvebodyBlob = Blob.valueOf(
      'Unit Test ContentVersion Body to be insert in test class for testing'
    );

    ContentVersion cvecontentVersion1 = new ContentVersion(
      Title = 'SampleTitle',
      PathOnClient = 'SampleTitle.jpg',
      VersionData = cvebodyBlob,
      origin = 'H'
    );
    insert cvecontentVersion1;

    ContentVersion cvecontentVersion2 = [
      SELECT Id, Title, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cvecontentVersion1.Id
      LIMIT 1
    ];

    ContentDocumentLink cvecontentlink = new ContentDocumentLink();
    cvecontentlink.LinkedEntityId = disability.id;
    cvecontentlink.contentdocumentid = cvecontentVersion2.contentdocumentid;
    cvecontentlink.ShareType = 'V';
    insert cvecontentlink;

    ContentVersion cvecontentVersionnew = new ContentVersion(
      Title = 'SampleTitle1',
      PathOnClient = 'SampleTitle1.jpg',
      VersionData = Blob.valueOf('Test Content'),
      origin = 'H'
    );
    insert cvecontentVersionnew;

    ContentVersion cvecontentv = [
      SELECT Id, Title, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cvecontentVersionnew.Id
      LIMIT 1
    ];

    ContentDocumentLink cvecontentlink1 = new ContentDocumentLink();
    cvecontentlink1.LinkedEntityId = disability.Id;
    cvecontentlink1.contentdocumentid = cvecontentv.contentdocumentid;
    cvecontentlink1.ShareType = 'V';
    insert cvecontentlink1;

    ContentVersion cvecontentVersionnew1 = new ContentVersion(
      Title = 'SampleTitle2',
      PathOnClient = 'SampleTitle2.jpg',
      VersionData = Blob.valueOf('Test Content in test class'),
      origin = 'H'
    );
    insert cvecontentVersionnew1;

    ContentVersion cvecontentv1 = [
      SELECT Id, Title, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cvecontentVersionnew1.Id
      LIMIT 1
    ];

    ContentDocumentLink cvecontentlink2 = new ContentDocumentLink();
    cvecontentlink2.LinkedEntityId = disability.Id;
    cvecontentlink2.contentdocumentid = cvecontentv1.contentdocumentid;
    cvecontentlink2.ShareType = 'V';
    insert cvecontentlink2;
  }
  @isTest
  public static void createcvabDocument() {
    cvab__Claim__c clm = [SELECT Id FROM cvab__Claim__c];
    ContentDocumentLink cd = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :clm.Id
      LIMIT 1
    ];
    Test.StartTest();
    Flow.Interview testFlow = Flow.Interview.createInterview(
      'Subflow_CreateDocument',
      new Map<String, Object>{
        'recordId' => clm.Id,
        'ContentDocumentIds' => cd.ContentDocumentId
      }
    );
    testFlow.start();
    Test.StopTest();

    List<cvab__Document__c> documentList = [
      SELECT Id
      FROM cvab__Document__c
      WHERE cvab__Claim__c = :clm.Id
    ];
    Assert.areEqual(1, documentList.size(), 'Document not created');
  }

  @isTest
  public static void createMultiplecvabDocument() {
    cvab__Claim__c clm = [SELECT Id FROM cvab__Claim__c];
    List<ContentDocumentLink> cdList = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :clm.Id
    ];
    List<Id> cdIds = new List<Id>();
    for (ContentDocumentLink cdl : cdList) {
      cdIds.add(cdl.ContentDocumentId);
    }

    Test.StartTest();
    Flow.Interview testFlow = Flow.Interview.createInterview(
      'Subflow_CreateDocument',
      new Map<String, Object>{
        'recordId' => clm.Id,
        'ContentDocumentIds' => cdIds
      }
    );
    testFlow.start();
    Test.StopTest();

    List<cvab__Document__c> documentList = [
      SELECT Id
      FROM cvab__Document__c
      WHERE cvab__Claim__c = :clm.Id
    ];

    Assert.areEqual(3, documentList.size(), 'Document not created');
  }

  @isTest
  public static void createcveDocument() {
    cve__Claim__c clm = [SELECT Id FROM cve__Claim__c];
    ContentDocumentLink cd = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :clm.Id
      LIMIT 1
    ];
    Test.StartTest();
    Flow.Interview testFlow = Flow.Interview.createInterview(
      'Subflow_CreateDocument',
      new Map<String, Object>{
        'recordId' => clm.Id,
        'ContentDocumentIds' => cd.ContentDocumentId
      }
    );
    testFlow.start();
    Test.StopTest();

    List<cve__Document__c> documentList = [
      SELECT Id
      FROM cve__Document__c
      WHERE cve__Claim__c = :clm.Id
    ];
    Assert.areEqual(1, documentList.size(), 'Document not created');
  }

  @isTest
  public static void createMultiplecveDocument() {
    cve__Claim__c clm = [SELECT Id FROM cve__Claim__c];
    List<ContentDocumentLink> cdList = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :clm.Id
    ];
    List<Id> cdIds = new List<Id>();
    for (ContentDocumentLink cdl : cdList) {
      cdIds.add(cdl.ContentDocumentId);
    }

    Test.StartTest();
    Flow.Interview testFlow = Flow.Interview.createInterview(
      'Subflow_CreateDocument',
      new Map<String, Object>{
        'recordId' => clm.Id,
        'ContentDocumentIds' => cdIds
      }
    );
    testFlow.start();
    Test.StopTest();

    List<cve__Document__c> documentList = [
      SELECT Id
      FROM cve__Document__c
      WHERE cve__Claim__c = :clm.Id
    ];

    Assert.areEqual(3, documentList.size(), 'Document not created');
  }
}