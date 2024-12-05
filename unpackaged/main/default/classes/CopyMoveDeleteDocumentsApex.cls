public with sharing class CopyMoveDeleteDocumentsApex {
  private static final String SUCCESS = 'SUCCESS';
  private static final String CVE_ATTACHMENTID = 'cve__AttachmentId__c';
  private static final String CVAB_URL = 'cvab__Url__c';
  private static final String CVE_CLAIM = 'cve__Claim__c';
  private static final String CVAB_CLAIM = 'cvab__Claim__c';
  private static final String DELETE_TEXT = 'delete';
  private static final String COPY_TEXT = 'copy';

  // To fetch the cve and cvab claims searched from the input screen
  @AuraEnabled
  public static list<sObject> fetchLookupData(
    string searchKey,
    string sObjectApiName
  ) {
    List<sObject> returnList = new List<sObject>();
    string sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
    string objectName = sObjectApiName;
    string sQuery = 'Select Id, Name FROM ' + objectName;
    sQuery += ' WHERE Name Like :sWildCardText order by createdDate DESC LIMIT 5';

    for (sObject obj : database.query(String.escapeSingleQuotes(sQuery))) {
      returnList.add(obj);
    }
    return returnList;
  }

  // Main method referencing all the documents creation/deletion, files creation/deletion
  @AuraEnabled
  public static String handleDocumentRecords(
    List<sobject> documentsSelected,
    sobject cveClaim,
    sobject cvabClaim,
    String jsonString
  ) {
    DocumentsWrapper wrapper = (DocumentsWrapper) JSON.deserialize(
      jsonString,
      DocumentsWrapper.class
    );
    String objectName = wrapper.objectName;
    String recordAction = wrapper.recordAction;
    String claimId;
    Boolean multipleFilesCreation = (cveClaim != null) ? false : true;

    if (cveClaim != null && recordAction != DELETE_TEXT) {
      claimId = cveDocumentsCreation(
        documentsSelected,
        cveClaim,
        objectName,
        multipleFilesCreation
      );
    }
    if (cvabClaim != null && recordAction != DELETE_TEXT) {
      claimId = cvabDocumentsCreation(
        documentsSelected,
        cvabClaim,
        objectName,
        multipleFilesCreation
      );
    }
    if (recordAction != COPY_TEXT) {
      claimId = deleteDocuments(documentsSelected, recordAction);
    }

    //logic to check which Claim Record to show whent he process is finished
    Boolean renderCVEClaimRecord = false;
    if (objectName == 'cve__Claim__c') {
      if (cveClaim != null) {
        renderCVEClaimRecord = true;
      }
    } else if (objectName == 'cvab__Claim__c') {
      if (cvabClaim == null) {
        renderCVEClaimRecord = true;
      }
    }
    claimId = (claimId == SUCCESS &&
      renderCVEClaimRecord == true &&
      recordAction != DELETE_TEXT)
      ? cveClaim?.Id
      : cvabClaim?.Id;
    return claimId;
  }

  // Creating the selected cve documents in the selected claim/s
  public static String cveDocumentsCreation(
    List<sobject> documentsSelected,
    sobject claimSelected,
    String objectName,
    boolean multipleFilesCreation
  ) {
    String isSuccess = SUCCESS;
    try {
      List<cve__document__c> cveDocumentList = new List<cve__document__c>();
      List<Id> cveDocIds = new List<Id>();
      Map<String, String> docsMap = new Map<String, String>();
      Map<Id, Id> docIdCdIdMap = new Map<Id, Id>();
      String attachmentId = (objectName == CVE_CLAIM)
        ? 'cve__AttachmentId__c'
        : 'cvab__Url__c';

      for (sobject record : documentsSelected) {
        String cdId = ((String) record.get(attachmentId))
          ?.replaceAll('[^a-zA-Z0-9]', '');
        String docName = (String) record.get('Name');
        cve__document__C cveDocument = new cve__document__C();
        cveDocument.cve__Claim__c = claimSelected.Id;
        cveDocument.Name = docName;
        cveDocument.cve__AttachmentIsFile__c = true;
        cveDocument.cve__AttachmentId__c = cdId;
        cveDocumentList.add(cveDocument);
        if (!multipleFilesCreation && cdId != null) {
          docIdCdIdMap.put(record.Id, cdId);
        }
        cveDocIds.add(record.Id);
        docsMap.put(docName, record.id);
      }
      insert cveDocumentList;
      isSuccess = contentDocumentLinkCreation(
        cveDocumentList,
        cveDocIds,
        docsMap,
        docIdCdIdMap
      );
    } catch (exception e) {
      isSuccess = e.getMessage() + ' | ' + e.getLineNumber();
      throw new CustomException(isSuccess);
    }
    return isSuccess;
  }

  // Creating the selected cvab documents in the selected claim/s
  public static String cvabDocumentsCreation(
    List<sobject> documentsSelected,
    sobject claimSelected,
    String objectName,
    boolean multipleFilesCreation
  ) {
    String isSuccess = SUCCESS;
    try {
      List<cvab__document__c> cvabDocumentList = new List<cvab__document__c>();
      List<Id> cvabDocIds = new List<Id>();
      Map<String, String> docsMap = new Map<String, String>();
      Map<Id, Id> docIdCdIdMap = new Map<Id, Id>();
      String attachmentId = (objectName == CVE_CLAIM)
        ? 'cve__AttachmentId__c'
        : 'cvab__Url__c';

      for (sobject record : documentsSelected) {
        cvab__document__c cvabDocument = new cvab__document__c();
        String cdId = ((String) record.get(attachmentId))
          ?.replaceAll('[^a-zA-Z0-9]', '');
        String docName = (String) record.get('Name');
        cvabDocument.cvab__Claim__c = claimSelected.Id;
        cvabDocument.Name = docName;
        cvabDocument.cvab__Url__c = cdId;
        cvabDocumentList.add(cvabDocument);
        if (!multipleFilesCreation && cdId != null) {
          docIdCdIdMap.put(record.Id, cdId);
        }
        cvabDocIds.add(record.Id);
        docsMap.put(docName, record.id);
      }
      insert cvabDocumentList;
      isSuccess = contentDocumentLinkCreation(
        cvabDocumentList,
        cvabDocIds,
        docsMap,
        docIdCdIdMap
      );
    } catch (exception e) {
      isSuccess = e.getMessage() + ' | ' + e.getLineNumber();
      throw new CustomException(isSuccess);
    }
    return isSuccess;
  }

  public static String contentDocumentLinkCreation(
    List<sobject> documentList,
    List<Id> docIds,
    Map<String, String> docsMap,
    Map<Id, Id> docIdCdIdMap
  ) {
    String isSuccess = SUCCESS;
    try {
      for (sobject doc : documentList) {
        String docName = (String) doc.get('Name');
        if (docsMap.containsKey(docName)) {
          docsMap.put(docsMap.get(docName), doc.Id);
          docsMap.remove(docName);
        }
      }
      Map<Id, List<ContentDocumentLink>> docIdcdlinksMap = new Map<Id, List<ContentDocumentLink>>();
      for (ContentDocumentLink cdlink : [
        SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN :docIds
      ]) {
        if (docIdcdlinksMap.containsKey(cdlink.LinkedEntityId)) {
          docIdcdlinksMap.get(cdlink.LinkedEntityId).add(cdlink);
        } else {
          docIdcdlinksMap.put(
            cdlink.LinkedEntityId,
            new List<ContentDocumentLink>{ cdlink }
          );
        }
      }
      List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
      for (Id docId : docIdcdlinksMap.keySet()) {
        cdLinkList.addall(
          contentDocumentLinkCreationCheck(
            docIdcdlinksMap.get(docId),
            docsMap,
            docIdCdIdMap
          )
        );
      }
      insert cdLinkList;
    } catch (exception e) {
      isSuccess = e.getMessage() + ' | ' + e.getLineNumber();
      throw new CustomException(isSuccess);
    }
    return isSuccess;
  }

  public static List<ContentDocumentLink> contentDocumentLinkCreationCheck(
    List<ContentDocumentLink> contentDocumentsList,
    Map<String, String> docsMap,
    Map<Id, Id> docIdCdIdMap
  ) {
    List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
    for (ContentDocumentLink cdl : contentDocumentsList) {
      ContentDocumentLink cdlink = new ContentDocumentLink();
      if (docIdCdIdMap.containsKey(cdl.LinkedEntityId)) {
        cdlink.ContentDocumentId = docIdCdIdMap.get(cdl.LinkedEntityId);
        cdlink.LinkedEntityId = docsMap.get(cdl.LinkedEntityId);
        cdlink.ShareType = cdl.ShareType;
        cdlink.Visibility = cdl.Visibility;
        cdLinkList.add(cdlink);
        break;
      } else {
        cdlink.ContentDocumentId = cdl.ContentDocumentId;
        cdlink.LinkedEntityId = docsMap.get(cdl.LinkedEntityId);
        cdlink.ShareType = cdl.ShareType;
        cdlink.Visibility = cdl.Visibility;
        cdLinkList.add(cdlink);
      }
    }
    return cdLinkList;
  }
  // Deleting the selected cve and cvab documents along with the files
  public static String deleteDocuments(
    List<sobject> documentsSelected,
    String recordAction
  ) {
    String isSuccess = SUCCESS;
    try {
      Set<Id> documentIds = new Set<Id>();
      for (sobject obj : documentsSelected) {
        documentIds.add(obj.Id);
      }
      if (recordAction != DELETE_TEXT) {
        delete [
          SELECT Id
          FROM ContentDocumentLink
          WHERE LinkedEntityId IN :documentIds
        ];
      }
      delete documentsSelected;
    } catch (exception e) {
      isSuccess = e.getMessage() + ' | ' + e.getLineNumber();
      throw new CustomException(isSuccess);
    }
    return isSuccess;
  }

  public class DocumentsWrapper {
    @AuraEnabled
    public String objectName { get; set; }
    @AuraEnabled
    public String recordAction { get; set; }

    public DocumentsWrapper(String objectName, String recordAction) {
      this.objectName = objectName;
      this.recordAction = recordAction;
    }
  }
  public class CustomException extends Exception {
  }
}