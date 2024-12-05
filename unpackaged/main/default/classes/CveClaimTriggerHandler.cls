public with sharing class CveClaimTriggerHandler extends TriggerHandler {
  CvabandCveClaimTriggerHelper helper;
  List<cve__Claim__c> claimList;
  List<cve__Claim__c> oldClaimList;

  CveClaimTriggerHelper cveHelper;
  EventPublisher event;
  List<cve__Claim__c> newList;
  @TestVisible
  List<cve__Claim__c> autoPayTrueClaims;

  public CveClaimTriggerHandler() {
    this(
      CvabandCveClaimTriggerHelper.getInstance(),
      (List<cve__Claim__c>) Trigger.New,
      (List<cve__Claim__c>) Trigger.Old,
      CveClaimTriggerHelper.getHelperInstance()
        .withOldMap((Map<Id, cve__Claim__c>) Trigger.oldMap)
        .withNewMap((Map<Id, cve__Claim__c>) Trigger.newMap),
      EventPublisher.getInstance()
    );
  }

  @TestVisible
  private CveClaimTriggerHandler(
    CvabandCveClaimTriggerHelper helper,
    List<cve__Claim__c> claimList,
    List<cve__Claim__c> oldClaimList,
    CveClaimTriggerHelper cveHelper,
    EventPublisher event
  ) {
    this.helper = helper;
    this.claimList = claimList;
    this.oldClaimList = oldClaimList;
    this.cveHelper = cveHelper;
    this.event = event;
  }

  public override void beforeUpdate() {
    if (cveHelper != null) {
      cveHelper.claimTATCalculation();
    }
  }

  public override void afterUpdate() {
    if (helper != null) {
      List<cve__Claim__c> claims = helper.verifyIfCveClaimShouldUpdate(
        claimList,
        oldClaimList
      );
      List<Contact> contactList = helper.rollupOverpayments(claims);
      handleUpdate(contactList);
    }

    // for Autopay
    if (cveHelper != null) {
      autoPayTrueClaims = cveHelper.getClaims();
      if (autoPayTrueClaims != null && autoPayTrueClaims.size() > 0) {
        List<cve__PaymentSpecification__c> setRunApprovalAs = cveHelper.setRunApprovalAs(
          autoPayTrueClaims
        );
        handleUpdate(setRunApprovalAs);
        List<RecalculatePayments__e> recalculatePaymentEvents = cveHelper.getEventList(
          autoPayTrueClaims
        );
        if (recalculatePaymentEvents.size() > 0) {
          publishEvents(recalculatePaymentEvents);
        }
      }
    }
    if (cvehelper != null) {
      List<ClaimCreatedFromCase__e> publishClaimEventList = cveHelper.publishClaimEvent(
        claimList,
        oldClaimList
      );
      if (publishClaimEventList != null) {
        publishEvents(publishClaimEventList);
      }
    }
  }

  public override void afterDelete() {
    if (helper != null) {
      List<Contact> contactList = helper.rollupOverpayments(this.oldClaimList);
      handleUpdate(contactList);
    }
  }

  public override void afterUndelete() {
    if (helper != null) {
      List<Contact> contactList = helper.rollupOverpayments(this.claimList);
      handleUpdate(contactList);
    }
  }

  public void handleUpdate(List<SObject> sobjectList) {
    try {
      List<Database.SaveResult> results = Database.update(
        sobjectList,
        false //,
        //AccessLevel.USER_MODE
      );
      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          String s = '';
          for (Database.Error err : result.getErrors()) {
            s += 'Error: ' + err.getStatusCode() + ' ' + err.getMessage();
          }
          throw new CustomException(s);
        }
      }
    } catch (Exception e) {
      throw new CustomException(
        'Exception while updating cve Contacts :- ' + e
      );
    }
  }

  public void publishEvents(List<SObject> events) {
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
  }

  public void handleErrors(List<Database.SaveResult> results) {
    Boolean result = false;
    for (Database.SaveResult sr : results) {
      if (sr.isSuccess()) {
        result = true;
      } else {
        for (Database.Error err : sr.getErrors()) {
          throw new CustomException(
            'Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage()
          );
        }
      }
    }
  }

  public class CustomException extends Exception {
  }
}