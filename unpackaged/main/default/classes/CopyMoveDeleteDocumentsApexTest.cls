@isTest
public class CopyMoveDeleteDocumentsApexTest {
  @testSetup
  static void dataSetup() {
    List<ContentVersion> contentVersionList = new List<contentVersion>();
    for (integer i = 1; i < 4; i++) {
      ContentVersion contentVersion = new ContentVersion(
        Title = 'Test Document ' + i,
        PathOnClient = 'TestDocument.pdf',
        VersionData = Blob.valueOf('Test Content ' + i)
      );
      contentVersionList.add(contentVersion);
    }
    insert contentVersionList;

    cve__Claim__c cveClaim = new cve__Claim__c(
      cve__OriginalName__c = 'claim 1'
    );
    insert cveClaim;
    cve__Claim__c cveClaim2 = new cve__Claim__c(
      cve__OriginalName__c = 'claim 2'
    );
    insert cveClaim2;

    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;

    List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
    List<cve__document__c> cveDocumentList = new List<cve__document__c>();
    cve__document__c cveDocument = new cve__document__c();
    cveDocument.cve__Claim__c = cveClaim.Id;
    cveDocument.Name = 'Sample Cve Document';
    cveDocument.cve__AttachmentIsFile__c = true;
    cveDocumentList.add(cveDocument);
    insert cveDocumentList;

    for (ContentVersion cv : [
      SELECT Id, Title, ContentDocumentId
      FROM contentVersion
    ]) {
      ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
        ContentDocumentId = cv.ContentDocumentId,
        LinkedEntityId = cveDocumentList[0].Id,
        ShareType = 'I',
        Visibility = 'AllUsers'
      );
      contentDocumentLinkList.add(contentDocumentLink);
    }
    insert contentDocumentLinkList;
  }

  @isTest
  static void copyDocuments() {
    cve__Claim__c cveClaim1 = [
      SELECT Id, Name
      FROM cve__Claim__c
      WHERE cve__OriginalName__c = 'claim 1'
    ];
    List<cve__document__c> cveDocument = [
      SELECT Id, Name, cve__Claim__c, cve__AttachmentId__c
      FROM cve__document__c
      WHERE cve__Claim__c = :cveClaim1.Id
      LIMIT 1
    ];
    cve__Claim__c cveClaim2 = [
      SELECT Id, Name
      FROM cve__Claim__c
      WHERE cve__OriginalName__c = 'claim 2'
    ];

    String jsonString = JSON.serialize(
      new DocumentsWrapper('cve__Claim__c', 'copy')
    );
    test.startTest();
    CopyMoveDeleteDocumentsApex.fetchLookupData(
      cveClaim2.Name,
      'cve__Claim__c'
    );
    CopyMoveDeleteDocumentsApex.handleDocumentRecords(
      cveDocument,
      cveClaim2,
      null,
      jsonString
    );
    test.stopTest();

    cve__document__c cveDocumentCopied = [
      SELECT Id
      FROM cve__document__c
      WHERE cve__Claim__c = :cveClaim2.Id
    ];
    List<contentDocumentLink> cdLinkCopied = [
      SELECT Id
      FROM contentDocumentLink
      WHERE LinkedEntityId = :cveDocumentCopied.Id
    ];
    Assert.isNotNull(cveDocumentCopied, 'Document is not copied');
    Assert.isNotNull(cdLinkCopied, 'File is not copied');
  }

  @isTest
  static void moveDocuments() {
    cve__Claim__c cveClaim1 = [
      SELECT Id, Name
      FROM cve__Claim__c
      WHERE cve__OriginalName__c = 'claim 1'
    ];
    List<cve__document__c> cveDocument = [
      SELECT Id, Name, cve__Claim__c, cve__AttachmentId__c
      FROM cve__document__c
      WHERE cve__Claim__c = :cveClaim1.Id
    ];
    cvab__Claim__c cvabClaim = [SELECT Id, Name FROM cvab__Claim__c LIMIT 1];

    String jsonString = JSON.serialize(
      new DocumentsWrapper('cve__Claim__c', 'move')
    );
    test.startTest();
    CopyMoveDeleteDocumentsApex.handleDocumentRecords(
      cveDocument,
      null,
      cvabClaim,
      jsonString
    );
    test.stopTest();

    List<cvab__document__c> cvabDocumentCreated = [
      SELECT Id
      FROM cvab__document__c
      WHERE cvab__Claim__c = :cvabClaim.Id
    ];
    List<contentDocumentLink> cdLinkCreated = [
      SELECT Id
      FROM contentDocumentLink
      WHERE LinkedEntityId = :cvabDocumentCreated[0].Id
    ];
    Assert.isNotNull(cvabDocumentCreated, 'Documents are not moved');
    Assert.isNotNull(cdLinkCreated, 'Files are not moved');
  }

  @isTest
  static void deleteDocuments() {
    cve__Claim__c cveClaim1 = [
      SELECT Id, Name
      FROM cve__Claim__c
      WHERE cve__OriginalName__c = 'claim 1'
    ];
    List<cve__document__c> cveDocument = [
      SELECT Id, Name, cve__Claim__c, cve__AttachmentId__c
      FROM cve__document__c
      WHERE cve__Claim__c = :cveClaim1.Id
    ];

    String jsonString = JSON.serialize(
      new DocumentsWrapper('cve__Claim__c', 'delete')
    );
    test.startTest();
    CopyMoveDeleteDocumentsApex.handleDocumentRecords(
      cveDocument,
      null,
      null,
      jsonString
    );
    test.stopTest();

    List<cve__document__c> cveDocumentDeleted = [
      SELECT Id
      FROM cve__document__c
      WHERE cve__Claim__c = :cveClaim1.Id
    ];
    Assert.areEqual(
      0,
      cveDocumentDeleted.size(),
      'Documents and files are not deleted'
    );
  }

  public class DocumentsWrapper {
    public String objectName;
    public String recordAction;

    public DocumentsWrapper(String objectName, String recordAction) {
      this.objectName = objectName;
      this.recordAction = recordAction;
    }
  }
}