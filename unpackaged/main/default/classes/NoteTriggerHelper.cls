public with sharing class NoteTriggerHelper {
  private static NoteTriggerHelper instance = null;

  public static NoteTriggerHelper getHelperInstance() {
    if (instance == null) {
      instance = new NoteTriggerHelper();
    }

    return instance;
  }

  //Method to fetch the disability claim based on absence claim Id
  public List<cvab__claim__c> getAbsenceClaims(List<Note> notes) {
    List<cvab__claim__c> absenceClaims = new List<cvab__claim__c>();
    try {
      Set<Id> claimIds = getClaimIds(notes);
      //Fetching the disability claims
      if (
        claimIds != null &&
        cvab__Claim__c.SObjectType.getDescribe().isAccessible()
      ) {
        absenceClaims = [
          SELECT Id, cvint__DisabilityClaim__c
          FROM cvab__Claim__c
          WHERE Id IN :claimIds
        ];
      }
    } catch (DmlException e) {
      System.debug('Exception has occurred: ' + e.getMessage());
    }
    return absenceClaims;
  }

  //Method to publish the platform event
  public List<ExplanationNoteCreatedEvent__e> getEventList(List<Note> notes) {
    List<cvab__claim__c> absenceClaims = getAbsenceClaims(notes);
    List<ExplanationNoteCreatedEvent__e> explanationNoteEvents = new List<ExplanationNoteCreatedEvent__e>();
    for (cvab__claim__c clm : absenceClaims) {
      explanationNoteEvents.add(generateEvent(clm));
    }
    return ExplanationNoteEvents;
  }

  public Set<ID> getClaimIds(List<Note> notes) {
    Set<Id> claimIds = new Set<Id>();
    if (notes != null) {
      for (Note note : notes) {
        if (
          note.Title == 'STD Claim has been created' ||
          note.Title == 'STD Claim has not been created' ||
          note.Title == 'Problem with ClaimFirst Creation' ||
          note.Title == 'Problem With Disability Claim Creation'
        ) {
          claimIds.add(note.ParentId);
        }
      }
    }
    return claimIds;
  }

  public ExplanationNoteCreatedEvent__e generateEvent(cvab__claim__c clm) {
    ExplanationNoteCreatedEvent__e explanationNoteEvent = new ExplanationNoteCreatedEvent__e();
    explanationNoteEvent.AbsenceClaimId__c = clm.Id;
    explanationNoteEvent.DisabilityClaimId__c = clm.cvint__DisabilityClaim__c;
    if (clm.cvint__DisabilityClaim__c != null) {
      explanationNoteEvent.HasDisabilityClaim__c = true;
    } else {
      explanationNoteEvent.HasDisabilityClaim__c = false;
    }
    return explanationNoteEvent;
  }
}