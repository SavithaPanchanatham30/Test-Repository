@isTest
public class CvabDocumentTriggerTest {
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

    cvab__Document__c document = new cvab__Document__c();
    document.Name = 'test document';
    document.cvab__Claim__c = absence.id;
    document.cvab__Body2__c = 'test';
    document.cvab__Url__c = getcontentDocumentId();
    insert document;
  }
  @isTest
  public static void documentUpdate() {
    List<cvab__Document__c> docs = [
      SELECT id, cvab__Url__c
      FROM cvab__Document__c
    ];
    Test.startTest();
    CvabDocumentTriggerHandler.ContextVariables cv = new CvabDocumentTriggerHandler.ContextVariables(
      docs,
      docs,
      new Map<Id, cvab__Document__c>(docs),
      new Map<Id, cvab__Document__c>(docs)
    );

    CvabDocumentTriggerHandler handler = new CvabDocumentTriggerHandler(
      CvabDocumentTriggerHelper.getInstance(),
      cv
    );
    handler.beforeUpdate();

    Test.stopTest();

    Assert.areEqual(
      getcontentDocumentId(),
      docs[0].cvab__Url__c,
      'Document url not equal to content document url'
    );
  }

  @IsTest
  static void triggerTest() {
    cvab__Document__c doc = [SELECT Id, cvab__Url__c FROM cvab__Document__c][0];

    Test.startTest();
    doc.Name = 'test document edit';

    Boolean errorsEncountered = false;

    try {
      update doc;
    } catch (Exception e) {
      errorsEncountered = true;
    }

    Assert.isFalse(
      errorsEncountered,
      'Error encountered during Trigger operation'
    );

    cvab__Document__c doc1 = [
      SELECT Id, cvab__Url__c
      FROM cvab__Document__c
    ][0];

    Assert.areEqual(
      doc.cvab__Url__c,
      doc1.cvab__Url__c,
      'Document url not equal to content document url'
    );
  }

  public static Id getcontentDocumentId() {
    return [SELECT Id, Title, ContentDocumentId FROM ContentVersion][0]
    .ContentDocumentId;
  }
}