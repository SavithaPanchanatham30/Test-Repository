@isTest
public class DownloadDocumentsZipTest {
  @testSetup
  public static void makeData() {
    cvab__Claim__c absence = new cvab__Claim__c();
    insert absence;

    cvab__Document__c document1 = new cvab__Document__c();
    document1.Name = 'test document1';
    document1.cvab__Claim__c = absence.id;
    document1.cvab__Body2__c = 'test';
    insert document1;

    cvab__Document__c document = new cvab__Document__c();
    document.Name = 'test document';
    document.cvab__Claim__c = absence.id;
    document.cvab__Body2__c = 'test';
    insert document;

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
      LIMIT 1
    ];

    ContentDocumentLink contentDocLink = new ContentDocumentLink();
    contentDocLink.LinkedEntityId = document.id;
    contentDocLink.contentdocumentid = contentVersion2.contentdocumentid;
    contentDocLink.ShareType = 'V';
    insert contentDocLink;

    ContentVersion contentVersionnew = new ContentVersion(
      Title = 'SampleTitlenew',
      PathOnClient = 'SampleTitle.jpg',
      VersionData = bodyBlob,
      origin = 'H'
    );
    insert contentVersionnew;
    ContentVersion getcontentVersionnew = [
      SELECT Id, Title, ContentDocumentId
      FROM ContentVersion
      WHERE Title = 'SampleTitlenew'
      LIMIT 1
    ];

    ContentDocumentLink contentDocLinknew = new ContentDocumentLink();
    contentDocLinknew.LinkedEntityId = document1.id;
    contentDocLinknew.contentdocumentid = getcontentVersionnew.contentdocumentid;
    contentDocLinknew.ShareType = 'V';
    insert contentDocLinknew;

    cve__Claim__c clm = new cve__Claim__c();
    insert clm;

    cve__Document__c cvedocument = new cve__Document__c();
    cvedocument.Name = 'test document';
    cvedocument.cve__Claim__c = clm.id;
    insert cvedocument;

    ContentVersion contentVersion3 = new ContentVersion(
      Title = 'SampleTitle1',
      PathOnClient = 'SampleTitle1.jpg',
      VersionData = bodyBlob,
      origin = 'H'
    );
    insert contentVersion3;
    ContentVersion contentVersion4 = [
      SELECT Id, Title, ContentDocumentId
      FROM ContentVersion
      WHERE Title = 'SampleTitle1'
      LIMIT 1
    ];

    ContentDocumentLink contentDocLink1 = new ContentDocumentLink();
    contentDocLink1.LinkedEntityId = cvedocument.id;
    contentDocLink1.contentdocumentid = contentVersion4.contentdocumentid;
    contentDocLink1.ShareType = 'V';
    insert contentDocLink1;
  }

  @isTest
  public static void cvabGetAttachments() {
    cvab__Claim__c clm = [SELECT Id FROM cvab__Claim__c LIMIT 1];
    List<Id> ids = DownloadDocumentsZip.getAttachement(
      clm.Id,
      'cvab__Claim__c'
    );
    Assert.areEqual(2, ids.size(), 'Not getting correct size for cvab claim');
  }

  @isTest
  public static void cveGetAttachments() {
    cve__Claim__c clm = [SELECT Id FROM cve__Claim__c LIMIT 1];
    List<Id> ids = DownloadDocumentsZip.getAttachement(clm.Id, 'cve__Claim__c');
    Assert.areEqual(1, ids.size(), 'Not getting correct size for cve claim');
  }

  @isTest
  public static void testWithoutApiName() {
    cve__Claim__c clm = [SELECT Id FROM cve__Claim__c LIMIT 1];
    List<Id> ids = DownloadDocumentsZip.getAttachement(clm.Id, '');
    Assert.areEqual(null, ids, 'Not getting null without api name');
  }

  @isTest
  public static void testWithoutRecordId() {
    List<Id> ids = DownloadDocumentsZip.getAttachement('', 'cvab__Claim__c');
    Assert.areEqual(null, ids, 'Not getting null without record id');
  }
}