@isTest
public class ExplanationNoteTriggerTest {
  @TestSetup
  public static void createData() {
    cve__Claim__c disability = new cve__Claim__c();
    insert disability;

    disability.cve__Status__c = 'Pending';
    update disability;

    cvab__Claim__c absence = new cvab__Claim__c();
    absence.cvint__DisabilityClaim__c = disability.Id;
    insert absence;

    cve__ClaimIntakeOptions__c setting = new cve__ClaimIntakeOptions__c();
    setting.cve__InitialClaimStatus__c = 'Open';
    insert setting;
  }

  @isTest
  public static void insertExplanationNote() {
    // cve__PaymentSpecification__c ps = getPaymentSpec();
    cvab__Claim__c absenceClm = [
      SELECT Id, cvint__DisabilityClaim__c
      FROM cvab__Claim__c
    ];
    ExplanationNoteCreatedEvent__e explanationNote = new ExplanationNoteCreatedEvent__e(
      DisabilityClaimId__c = absenceClm.cvint__DisabilityClaim__c
    );

    ExplanationNoteTriggerHandler testHandler = new ExplanationNoteTriggerHandler(
      ExplanationNoteTriggerHelper.getHelperInstance(),
      null,
      new List<ExplanationNoteCreatedEvent__e>{ explanationNote },
      null
    );

    Test.startTest();
    testHandler.afterInsert();
    Test.stopTest();
    cve__ClaimIntakeOptions__c myCS1 = cve__ClaimIntakeOptions__c.getInstance();
    Assert.areEqual(
      'Open',
      myCS1.cve__InitialClaimStatus__c,
      'disablity claim with status not equal to open'
    );
  }

  @isTest
  public static void triggerTest() {
    Boolean errorOccurred = false;
    cvab__Claim__c absenceClm = [
      SELECT Id, cvint__DisabilityClaim__c
      FROM cvab__Claim__c
    ];
    ExplanationNoteCreatedEvent__e explanationNote = new ExplanationNoteCreatedEvent__e(
      DisabilityClaimId__c = absenceClm.cvint__DisabilityClaim__c
    );
    List<ExplanationNoteCreatedEvent__e> eventList = new List<ExplanationNoteCreatedEvent__e>();
    eventList.add(explanationNote);

    List<Database.SaveResult> results;

    Test.startTest();
    try {
      EventPublisher eventp = EventPublisher.getInstance();
      results = eventp.publish(eventList);
    } catch (Exception e) {
      errorOccurred = true;
    }
    Test.stopTest();
    cve__ClaimIntakeOptions__c myCS1 = cve__ClaimIntakeOptions__c.getInstance();
    Assert.areEqual(
      'Open',
      myCS1.cve__InitialClaimStatus__c,
      'disablity claim with status not equal to open'
    );
  }

  @isTest
  public static void insertExplanationNotewithoutDisabilityId() {
    cvab__Claim__c absenceClm = [SELECT Id FROM cvab__Claim__c];
    ExplanationNoteCreatedEvent__e explanationNote = new ExplanationNoteCreatedEvent__e(
      AbsenceClaimId__c = absenceClm.Id,
      DisabilityClaimId__c = null
    );

    ExplanationNoteTriggerHandler testHandler = new ExplanationNoteTriggerHandler(
      ExplanationNoteTriggerHelper.getHelperInstance(),
      null,
      new List<ExplanationNoteCreatedEvent__e>{ explanationNote },
      null
    );

    Test.startTest();
    testHandler.afterInsert();
    Test.stopTest();
    cve__ClaimIntakeOptions__c myCS1 = cve__ClaimIntakeOptions__c.getInstance();
    Assert.areNotEqual(
      'Pending',
      myCS1.cve__InitialClaimStatus__c,
      'Expected claim status not equal to pending'
    );
  }
}