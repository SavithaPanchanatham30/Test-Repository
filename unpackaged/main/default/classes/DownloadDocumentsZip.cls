public with sharing class DownloadDocumentsZip {
  @AuraEnabled
  public static List<Id> getAttachement(String recordId, String apiName) {
    Set<Id> contentDocIds = new Set<Id>();
    Set<Id> cvabDocIds = new Set<Id>();
    List<Id> contentVersionIds = new List<Id>();
    List<sObject> documentList = new List<sObject>();
    if (apiName == 'cvab__Claim__c') {
      documentList = [
        SELECT id, cvab__Url__c
        FROM cvab__Document__c
        WHERE cvab__Claim__c = :recordId
        WITH SECURITY_ENFORCED
      ];
    } else if (apiName == 'cve__Claim__c') {
      documentList = [
        SELECT id, cve__AttachmentId__c
        FROM cve__Document__c
        WHERE cve__Claim__c = :recordId
        WITH SECURITY_ENFORCED
      ];
    }
    if (!(documentList.size() > 0)) {
      return null;
    }
    for (sObject doc : documentList) {
      if (apiName == 'cvab__Claim__c') {
        cvab__Document__c cvabDoc = (cvab__Document__c) doc;
        if (cvabDoc.cvab__Url__c != null) {
          contentDocIds.add(cvabDoc.cvab__Url__c);
        }
      }
      if (apiName == 'cve__Claim__c') {
        cve__Document__c cveDoc = (cve__Document__c) doc;
        if (cveDoc.cve__AttachmentId__c != null) {
          contentDocIds.add(cveDoc.cve__AttachmentId__c);
        }
      }
      cvabDocIds.add(doc.Id);
    }
    for (ContentDocumentLink cdl : [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN :cvabDocIds
      WITH SECURITY_ENFORCED
    ]) {
      contentDocIds.add(cdl.ContentDocumentId);
    }
    Set<String> titles = new Set<String>();
    if (contentDocIds.size() > 0) {
      for (ContentVersion cv : [
        SELECT Id, title
        FROM ContentVersion
        WHERE ContentDocumentId IN :contentDocIds
        WITH SECURITY_ENFORCED
      ]) {
        if (!titles.contains(cv.Title)) {
          titles.add(cv.Title);
          contentVersionIds.add(cv.Id);
        }
      }
      return contentVersionIds;
    } else {
      return null;
    }
  }
}