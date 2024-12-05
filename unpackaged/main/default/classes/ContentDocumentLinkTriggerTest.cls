@isTest
public class ContentDocumentLinkTriggerTest {
  @TestSetup
  public static void makeData() {
    cvab__Claim__c absence = new cvab__Claim__c();
    insert absence;

    cve__Claim__c disabilityClaim = new cve__Claim__c();
    insert disabilityClaim;

    Case cs = new Case();
    cs.CvabClaim__c = absence.Id;
    cs.cveClaim__c = disabilityClaim.Id;
    insert cs;

    Case cs1 = new Case();
    insert cs1;
  }

  @IsTest
  static void eventPublishingWithAbsenceClaim() {
    Case cs = [SELECT Id, CvabClaim__c, CveClaim__c FROM Case][0];

    Blob bodyBlob = Blob.valueOf(
      'Unit Test ContentVersion Body to be insert in test class for testing'
    );
    TriggerHandler.bypass('ContentDocumentLinkTriggerHandler');
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
      LIMIT 1
    ];

    ContentDocumentLink contentDocLink = new ContentDocumentLink();
    contentDocLink.LinkedEntityId = cs.id;
    contentDocLink.contentdocumentid = contentVersion2.contentdocumentid;
    contentDocLink.ShareType = 'V';
    List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>{
      contentDocLink
    };
    TriggerHandler.clearAllBypasses();

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();
    ContentDocumentLinkTriggerHandler.ContextVariables cv = new ContentDocumentLinkTriggerHandler.ContextVariables(
      null,
      cdlList,
      null,
      null
    );

    ContentDocumentLinkTriggerHandler testHandler = new ContentDocumentLinkTriggerHandler(
      ContentDocumentLinkTriggerHelper.getInstance(),
      cv,
      eventPublisherDouble
    );
    testHandler.afterInsert();
    Test.stopTest();
    ClaimCreatedFromCase__e expectedOutcome = new ClaimCreatedFromCase__e();
    expectedOutcome.CvabClaimId__c = cs.CvabClaim__c;
    expectedOutcome.CveClaimId__c = cs.CveClaim__c;
    expectedOutcome.IntakeCaseId__c = cs.Id;

    List<ClaimCreatedFromCase__e> actualOutcome = (List<ClaimCreatedFromCase__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      new List<ClaimCreatedFromCase__e>{ expectedOutcome },
      actualOutcome,
      'Published event does not match the expected ClaimCreatedFromCase__e'
    );
  }

  @isTest
  static void testCasesWithNoClaims() {
    Case cs = [
      SELECT Id, CvabClaim__c, CveClaim__c
      FROM Case
      WHERE CvabClaim__c = NULL AND CveClaim__c = NULL
    ][0];

    Blob bodyBlob = Blob.valueOf(
      'Unit Test ContentVersion Body to be insert in test class for testing'
    );
    TriggerHandler.bypass('ContentDocumentLinkTriggerHandler');
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
      LIMIT 1
    ];

    ContentDocumentLink contentDocLink = new ContentDocumentLink();
    contentDocLink.LinkedEntityId = cs.id;
    contentDocLink.contentdocumentid = contentVersion2.contentdocumentid;
    contentDocLink.ShareType = 'V';
    List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>{
      contentDocLink
    };
    TriggerHandler.clearAllBypasses();

    Test.startTest();
    ContentDocumentLinkTriggerHandler.ContextVariables cv = new ContentDocumentLinkTriggerHandler.ContextVariables(
      null,
      cdlList,
      null,
      null
    );

    ContentDocumentLinkTriggerHandler testHandler = new ContentDocumentLinkTriggerHandler(
      ContentDocumentLinkTriggerHelper.getInstance(),
      cv,
      EventPublisher.getInstance()
    );
    testHandler.afterInsert();
    Test.stopTest();
    List<ClaimCreatedFromCase__e> eventList = testHandler.eventList;

    Assert.areEqual(
      0,
      eventList.size(),
      'Getting size of event list greater than zero'
    );
  }
}