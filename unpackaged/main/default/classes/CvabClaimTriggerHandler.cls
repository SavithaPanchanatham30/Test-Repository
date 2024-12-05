public with sharing class CvabClaimTriggerHandler extends TriggerHandler {
  CvabandCveClaimTriggerHelper helper;
  List<cvab__Claim__c> claimList;
  List<cvab__Claim__c> oldClaimList;
  Map<Id, cvab__Claim__c> oldClaimMap;
  EventPublisher event;

  public CvabClaimTriggerHandler() {
    this(
      CvabandCveClaimTriggerHelper.getInstance(),
      (List<cvab__Claim__c>) Trigger.New,
      (List<cvab__Claim__c>) Trigger.Old,
      (map<Id, cvab__Claim__c>) Trigger.Oldmap,
      EventPublisher.getInstance()
    );
  }

  @TestVisible
  private CvabClaimTriggerHandler(
    CvabandCveClaimTriggerHelper helper,
    List<cvab__Claim__c> claimList,
    List<cvab__Claim__c> oldClaimList,
    map<Id, cvab__Claim__c> oldClaimMap,
    EventPublisher event
  ) {
    this.helper = helper;
    this.claimList = claimList;
    this.oldClaimList = oldClaimList;
    this.oldClaimMap = oldClaimMap;
    this.event = event;
  }

  public override void afterInsert() {
    List<Contact> contactList = helper.rollupOverpayments(claimList);
    handleUpdate(contactList);
    List<Case> updatedCase = helper.linkClaimToCase(claimList);
    handleUpdate(updatedCase);
  }

  public override void beforeUpdate() {
    helper.setCvabClaimStatus(claimList, oldClaimMap);
    helper.updateStatusReason(claimList, oldClaimMap);
    helper.claimTATCalculation(claimList, oldClaimMap);
  }

  public override void afterUpdate() {
    List<cvab__Claim__c> claims = helper.verifyIfCvabClaimShouldUpdate(
      claimList,
      oldClaimList
    );
    List<Contact> contactList = helper.rollupOverpayments(claims);
    handleUpdate(contactList);

    if (event != null) {
      List<UpdateCancelledStatusReason__e> eventList = helper.updateStatusReasonOfDateRange(
        claimList,
        oldClaimList
      );
      if (eventList != null && eventList.size() > 0) {
        publishEvents(eventList);
      }
      List<ClaimCreatedFromCase__e> publishAbClaimEventList = helper.publishAbClaimEvent(
        claimList,
        oldClaimList
      );
      if (publishAbClaimEventList != null) {
        publishEvents(publishAbClaimEventList);
      }

      List<cvab__Claim__c> filteredCvab = helper.filterCvabClaims(
        claimList,
        oldClaimList
      );
      if (filteredCvab != null && filteredCvab.size() > 0) {
        List<ClaimCreatedFromCase__e> caseEventList = helper.createEvents(
          filteredCvab
        );
        publishEvents(caseEventList);
      }
    }
  }

  public override void afterDelete() {
    List<Contact> contactList = helper.rollupOverpayments(this.oldClaimList);
    handleUpdate(contactList);
  }

  public override void afterUndelete() {
    List<Contact> contactList = helper.rollupOverpayments(this.claimList);
    handleUpdate(contactList);
  }

  public void handleUpdate(List<SObject> sobjectList) {
    try {
      List<Database.SaveResult> results = Database.update(sobjectList, false);
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
        'Exception while updating cvab Contacts :- ' + e
      );
    }
  }

  public void publishEvents(List<SObject> events) {
    if (event != null && events != null && events.size() > 0) {
      List<Database.SaveResult> result = event.publish(events);
      handleErrors(result);
    }
  }

  public void handleErrors(List<Database.SaveResult> result) {
    for (Database.SaveResult sr : result) {
      if (!sr.isSuccess()) {
        String s = '';
        for (Database.Error err : sr.getErrors()) {
          s += ('Error returned : ' +
          err.getStatusCode() +
          ' - ' +
          err.getMessage());
        }
        throw new CustomException(s);
      }
    }
  }

  public class CustomException extends Exception {
  }
}