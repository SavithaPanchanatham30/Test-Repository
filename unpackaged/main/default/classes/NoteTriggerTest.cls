@IsTest
public class NoteTriggerTest {
  @TestSetup
  static void makeData() {
    SObject acc = new TestAccountBuilder().buildAndInsert();
    SObject customGroup = new TestGroupBuilder()
      .withMasterGroupId(acc.Id)
      .buildAndInsert();
    SObject con = new TestContactBuilder()
      .withAccountId(acc.Id)
      .withGroupId(customGroup.Id)
      .buildAndInsert();

    cve__Claim__c disability = new cve__Claim__c();
    insert disability;

    cvab__Claim__c clm = new cvab__Claim__c(
      cvab__Employee__c = con.id,
      cvab__Reason__c = 'Employees Own Illness or Injury',
      cvint__DisabilityClaim__c = disability.Id
    );
    insert clm;

    List<cvab__Claim__c> claimsWithoutDisabilityClaim = generateAbsenceOnlyClaims(
      con.id
    );
    insert claimsWithoutDisabilityClaim;
  }

  @IsTest
  static void eventPublishingWithDisabilityClaim() {
    List<cvab__Claim__c> clm = getIntegratedClaims();
    Note note = new Note(
      Title = 'STD Claim has been created',
      Body = 'test',
      ParentId = clm[0].Id
    );

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    NoteTriggerHandler testHandler = new NoteTriggerHandler(
      NoteTriggerHelper.getHelperInstance(),
      new List<Note>{ note },
      eventPublisherDouble
    );
    testHandler.afterInsert();
    Test.stopTest();
    ExplanationNoteCreatedEvent__e expectedOutcome = new ExplanationNoteCreatedEvent__e(
      AbsenceClaimId__c = clm[0].Id,
      DisabilityClaimId__c = clm[0].cvint__DisabilityClaim__c,
      HasDisabilityClaim__c = true
    );

    List<ExplanationNoteCreatedEvent__e> actualOutcome = (List<ExplanationNoteCreatedEvent__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      new List<ExplanationNoteCreatedEvent__e>{ expectedOutcome },
      actualOutcome,
      'Published event does not match the expected ExplanationNoteCreatedEvent__e'
    );
  }

  @IsTest
  static void eventPublishingWithoutDisabilityClaim() {
    List<cvab__Claim__c> clm = getAbsenceOnlyClaim();

    List<Note> notes = generateNotes(clm);

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    NoteTriggerHandler testHandler = new NoteTriggerHandler(
      NoteTriggerHelper.getHelperInstance(),
      notes,
      eventPublisherDouble
    );
    testHandler.afterInsert();

    List<ExplanationNoteCreatedEvent__e> expectedOutcome = generateExpectedResult(
      clm
    );

    List<ExplanationNoteCreatedEvent__e> actualOutcome = (List<ExplanationNoteCreatedEvent__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      expectedOutcome,
      actualOutcome,
      'Published event match with expected ExplanationNoteCreatedEvent__e'
    );
  }

  @IsTest
  static void triggerTest() {
    List<cvab__Claim__c> clm = getAbsenceOnlyClaim();

    Test.startTest();
    Note note = new Note(
      Title = 'STD Claim has not been created',
      Body = 'test',
      ParentId = clm[0].Id
    );

    Boolean errorsEncountered = false;

    try {
      insert note;
    } catch (Exception e) {
      errorsEncountered = true;
    }

    Assert.isFalse(
      errorsEncountered,
      'Error encountered during Trigger operation'
    );
  }

  static List<cvab__Claim__c> generateAbsenceOnlyClaims(Id employeeId) {
    List<cvab__Claim__c> claimList = new List<cvab__Claim__c>();
    for (Integer i = 0; i < 3; i += 1) {
      claimList.add(
        new cvab__Claim__c(
          cvab__Employee__c = employeeId,
          cvab__Reason__c = 'Employees Own Illness or Injury'
        )
      );
    }

    return claimList;
  }

  static List<ExplanationNoteCreatedEvent__e> generateExpectedResult(
    List<cvab__Claim__c> claimList
  ) {
    List<ExplanationNoteCreatedEvent__e> expectedResult = new List<ExplanationNoteCreatedEvent__e>();
    for (cvab__Claim__c claim : claimList) {
      expectedResult.add(
        new ExplanationNoteCreatedEvent__e(
          AbsenceClaimId__c = claim.id,
          DisabilityClaimId__c = null,
          HasDisabilityClaim__c = false
        )
      );
    }
    return expectedResult;
  }

  static List<Note> generateNotes(List<cvab__Claim__c> claimList) {
    List<String> titles = new List<String>{
      'STD Claim has not been created',
      'Problem with ClaimFirst Creation',
      'Problem With Disability Claim Creation'
    };
    List<Note> notes = new List<Note>();
    Integer titleIndex = 0;
    for (cvab__Claim__c claim : claimList) {
      notes.add(
        new Note(Title = titles[titleIndex], Body = 'test', ParentId = claim.id)
      );
      titleIndex += 1;
    }
    return notes;
  }

  static List<cvab__Claim__c> getIntegratedClaims() {
    return [
      SELECT Id, cvint__DisabilityClaim__c
      FROM cvab__Claim__c
      WHERE cvint__DisabilityClaim__c != NULL
    ];
  }

  static List<cvab__Claim__c> getAbsenceOnlyClaim() {
    return [
      SELECT Id
      FROM cvab__Claim__c
      WHERE cvint__DisabilityClaim__c = NULL
    ];
  }
}