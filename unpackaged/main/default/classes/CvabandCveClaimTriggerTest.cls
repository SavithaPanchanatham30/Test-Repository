@isTest
public class CvabandCveClaimTriggerTest {
  @TestSetup
  public static void makeData() {
    SObject acc = new TestAccountBuilder().buildAndInsert();
    SObject customGroup = new TestGroupBuilder()
      .withMasterGroupId(acc.Id)
      .buildAndInsert();
    SObject con = new TestContactBuilder()
      .withAccountId(acc.Id)
      .withGroupId(customGroup.Id)
      .build();

    // using "buildAndInsert()" above would be better, but PMD wants to see
    // us use the variable
    insert con;

    Case cs = new Case();
    cs.ContactId = con.id;
    cs.Employee_Statement__c = true;
    cs.Employer_Statement__c = true;
    cs.ClaimIntakeLastRunByUser__c = userinfo.getuserid();
    insert cs;

    cve__claim__c disclaim = new cve__claim__c();
    insert disclaim;

    cvab__claim__c cvab = new cvab__claim__c();
    cvab.cvab__Employee__c = con.id;
    cvab.IntakeCase__c = null;
    insert cvab;
  }

  @isTest
  public static void checkAfterInsertOnCvab() {
    Contact con = getContact();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    cvab__Claim__c c1 = new cvab__Claim__c(
      cvab__Employee__c = con.id,
      TotalOverpayments__c = 2000.00
    );
    insert c1;
    TriggerHandler.clearAllBypasses();

    CvabClaimTriggerHandler handler = new CvabClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cvab__Claim__c>{ c1 },
      null,
      null,
      null
    );
    Test.startTest();
    handler.afterInsert();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(true, con.HasOverPayment__c, 'Flag was not set');
  }

  @isTest
  public static void checkAfterUpdateOnCvab() {
    Contact con = getContact();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    cvab__Claim__c c1 = new cvab__Claim__c(
      cvab__AbsenceStatus__c = 'Pending',
      cvab__Employee__c = con.id,
      TotalOverpayments__c = 2000.00
    );
    insert c1;
    cvab__Claim__c c2 = [
      SELECT id, cvab__AbsenceStatus__c, cvab__Employee__c, TotalOverpayments__c
      FROM cvab__Claim__c
      WHERE id = :c1.id
    ];
    c2.TotalOverpayments__c = 0;
    TriggerHandler.clearAllBypasses();

    CvabClaimTriggerHandler handler = new CvabClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cvab__Claim__c>{ c1 },
      new List<cvab__Claim__c>{ c2 },
      null,
      null
    );
    Test.startTest();
    handler.afterUpdate();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(true, con.HasOverPayment__c, 'Flag was not set');
  }

  @isTest
  public static void checkClaimStatus() {
    Contact con = getContact();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    cvab__Claim__c c1 = new cvab__Claim__c(
      UsableCvabStatus__c = 'Pending',
      cvab__AbsenceStatus__c = 'Pending',
      cvab__Employee__c = con.id,
      TotalOverpayments__c = 2000.00
    );
    insert c1;
    cvab__Claim__c c2 = [
      SELECT
        id,
        StatusChangedDate__c,
        FinalStatusChangedDate__c,
        InitialDecisionDate__c,
        FinalDecisionDate__c,
        CaseCreatedDate__c,
        UsableCvabStatus__c,
        cvab__Status__c,
        cvab__AbsenceStatus__c,
        cvab__Employee__c,
        TotalOverpayments__c
      FROM cvab__Claim__c
      WHERE id = :c1.id
    ];
    c2.TotalOverpayments__c = 0;
    c2.UsableCvabStatus__c = 'Incomplete';
    TriggerHandler.clearAllBypasses();

    CvabClaimTriggerHandler handler = new CvabClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cvab__Claim__c>{ c2 },
      new List<cvab__Claim__c>{ c1 },
      new Map<Id, cvab__Claim__c>{ c1.id => c1 },
      null
    );
    Test.startTest();
    handler.beforeUpdate();
    Test.stopTest();

    Assert.areEqual('Open', c2.cvab__Status__c, 'Status not updated correctly');
  }

  @isTest
  public static void checkAfterUpdateCvabClaimToZero() {
    Contact con = getContact();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    cvab__Claim__c c1 = new cvab__Claim__c(
      cvab__AbsenceStatus__c = 'Pending',
      cvab__Employee__c = con.id,
      TotalOverpayments__c = 0.00
    );
    insert c1;
    cvab__Claim__c c2 = [
      SELECT
        id,
        cvab__AbsenceStatus__c,
        cvab__Employee__c,
        TotalOverpayments__c,
        IntakeCase__c
      FROM cvab__Claim__c
      WHERE id = :c1.id
    ];
    c2.TotalOverpayments__c = 2000;
    TriggerHandler.clearAllBypasses();

    CvabClaimTriggerHandler handler = new CvabClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cvab__Claim__c>{ c1 },
      new List<cvab__Claim__c>{ c2 },
      null,
      null
    );
    Test.startTest();
    handler.afterUpdate();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(false, con.HasOverPayment__c, 'Flag was incorrectly set');
  }

  @isTest
  public static void checkAfterDeleteOnCvab() {
    Contact con = getContact();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    cvab__Claim__c c1 = new cvab__Claim__c(
      cvab__Employee__c = con.id,
      TotalOverpayments__c = 2000.00
    );
    insert c1;
    delete c1;
    TriggerHandler.clearAllBypasses();

    CvabClaimTriggerHandler handler = new CvabClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      null,
      new List<cvab__Claim__c>{ c1 },
      null,
      null
    );
    Test.startTest();
    handler.afterDelete();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(false, con.HasOverPayment__c, 'Flag was set');
  }

  @isTest
  public static void checkAfterUndeleteOnCvab() {
    Contact con = getContact();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    cvab__Claim__c c1 = new cvab__Claim__c(
      cvab__Employee__c = con.id,
      TotalOverpayments__c = 2000.00
    );
    insert c1;
    delete c1;
    undelete c1;
    TriggerHandler.clearAllBypasses();

    CvabClaimTriggerHandler handler = new CvabClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cvab__Claim__c>{ c1 },
      null,
      null,
      null
    );
    Test.startTest();
    handler.afterUndelete();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(true, con.HasOverPayment__c, 'Flag was not set');
  }

  @isTest
  public static void checkAfterUpdateOnCve() {
    Contact con = getContact();

    TriggerHandler.bypass('CveClaimTriggerHandler');
    cve__Claim__c c1 = new cve__Claim__c(
      cve__ClaimantInsured__c = con.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert c1;
    cve__Claim__c c2 = [
      SELECT id, cve__ClaimantInsured__c, cve__OverpaymentNet__c
      FROM cve__Claim__c
      WHERE id = :c1.id
    ];
    c2.cve__OverpaymentNet__c = 0.0;
    TriggerHandler.clearAllBypasses();

    CveClaimTriggerHandler handler = new CveClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cve__Claim__c>{ c1 },
      new List<cve__Claim__c>{ c2 },
      null,
      null
    );
    Test.startTest();
    handler.afterUpdate();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(true, con.HasOverPayment__c, 'Flag was not set');
  }

  @isTest
  public static void checkAfterUpdateCveClaimToZero() {
    Contact con = getContact();

    TriggerHandler.bypass('CveClaimTriggerHandler');
    cve__Claim__c c1 = new cve__Claim__c(
      cve__ClaimantInsured__c = con.id,
      cve__OverpaymentNet__c = 0.00
    );
    insert c1;
    cve__Claim__c c2 = [
      SELECT id, cve__ClaimantInsured__c, cve__OverpaymentNet__c
      FROM cve__Claim__c
      WHERE id = :c1.id
    ];
    c2.cve__OverpaymentNet__c = 2000.0;
    TriggerHandler.clearAllBypasses();

    CveClaimTriggerHandler handler = new CveClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cve__Claim__c>{ c1 },
      new List<cve__Claim__c>{ c2 },
      null,
      null
    );
    Test.startTest();
    handler.afterUpdate();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(false, con.HasOverPayment__c, 'Flag was incorrectly set');
  }

  @isTest
  public static void checkAfterDeleteOnCve() {
    Contact con = getContact();

    TriggerHandler.bypass('CveClaimTriggerHandler');
    cve__Claim__c c1 = new cve__Claim__c(
      cve__ClaimantInsured__c = con.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert c1;
    delete c1;
    TriggerHandler.clearAllBypasses();

    CveClaimTriggerHandler handler = new CveClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      null,
      new List<cve__Claim__c>{ c1 },
      null,
      null
    );
    Test.startTest();
    handler.afterDelete();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(false, con.HasOverPayment__c, 'Flag was set');
  }

  @isTest
  public static void checkAfterUndeleteOnCve() {
    Contact con = getContact();

    TriggerHandler.bypass('CveClaimTriggerHandler');
    cve__Claim__c c1 = new cve__Claim__c(
      cve__ClaimantInsured__c = con.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert c1;
    delete c1;
    undelete c1;
    TriggerHandler.clearAllBypasses();

    CveClaimTriggerHandler handler = new CveClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cve__Claim__c>{ c1 },
      null,
      null,
      null
    );
    Test.startTest();
    handler.afterUndelete();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(true, con.HasOverPayment__c, 'Flag was not set');
  }

  @isTest
  public static void checkWithBothCveAndCvab() {
    Contact con = getContact();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    cvab__Claim__c c1 = new cvab__Claim__c(
      cvab__Employee__c = con.id,
      TotalOverpayments__c = 2000.00
    );
    insert c1;
    TriggerHandler.bypass('CveClaimTriggerHandler');
    cve__Claim__c cve1 = new cve__Claim__c(
      cve__ClaimantInsured__c = con.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert cve1;
    delete cve1;
    TriggerHandler.clearAllBypasses();

    CveClaimTriggerHandler handler = new CveClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      null,
      new List<cve__Claim__c>{ cve1 },
      null,
      null
    );
    Test.startTest();
    handler.afterDelete();
    Test.stopTest();

    con = getContact();
    Assert.areEqual(true, con.HasOverPayment__c, 'Flag was not set');
  }

  public static Account getAccount() {
    return [SELECT id FROM Account LIMIT 1];
  }

  public static Contact getContact() {
    return [SELECT Id, HasOverPayment__c FROM Contact LIMIT 1];
  }

  @isTest
  public static void checkBeforeUpdateOnCvab() {
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    contact con = [SELECT Id FROM contact LIMIT 1];
    cvab__Claim__c cvabClaim = new cvab__Claim__c(cvab__Employee__c = con.Id);
    insert cvabClaim;
    cvab__ClaimLeave__c claimLeave = new cvab__ClaimLeave__c(
      name = 'Massachusetts Paid Family and Medical Leave',
      cvab__Claim__c = cvabClaim.Id,
      cvab__Approved__c = 8025,
      cvab__ApprovedLabel__c = '3 weeks, 1 day, 5 hours, 45 minutes',
      cvab__LeaveType__c = 'Continuous'
    );
    insert claimLeave;

    cvab__WeeklySchedule__c weeklySchedule = new cvab__WeeklySchedule__c();
    weeklySchedule.cvab__HoursFriday__c = 8;
    weeklySchedule.cvab__HoursMonday__c = 8;
    weeklySchedule.cvab__HoursTuesday__c = 8;
    weeklySchedule.cvab__HoursWednesday__c = 8;
    weeklySchedule.cvab__HoursThursday__c = 8;
    insert weeklySchedule;

    Id clinicRecordTypeId = Schema.SObjectType.cvab__DateRange__c.getRecordTypeInfosByName()
      .get('Continuous')
      .getRecordTypeId();
    cvab__DateRange__c[] dateRanges = new List<cvab__DateRange__c>{};
    for (Integer i = 0; i < 21; i++) {
      cvab__DateRange__c dr = new cvab__DateRange__c(
        RecordTypeId = clinicRecordTypeId,
        cvab__Schedule__c = weeklySchedule.Id,
        cvab__StartDate__c = Date.newInstance(2012, 3, 7 + i),
        cvab__EndDate__c = Date.newInstance(2012, 3, 7 + i),
        cvab__MinutesEachDay__c = 195,
        cvab__DurationInMinutes__c = 195,
        cvab__DurationLabel__c = '3 hours, 15 minutes',
        cvab__ClaimLeave__c = claimLeave.Id,
        cvab__Status__c = 'Waiting',
        cvab__StatusReason__c = 'Waiting'
      );
      dateRanges.add(dr);
    }
    insert dateRanges;

    TriggerHandler.clearAllBypasses();
    cvabClaim.cvab__AbsenceStatus__c = 'Waiting';
    update cvabClaim;

    cvab__Claim__c claim = [
      SELECT Id, AbsenceStatusReason__c
      FROM cvab__Claim__c
      WHERE Id = :cvabClaim.Id
    ];

    Assert.areEqual(
      'Waiting',
      claim.AbsenceStatusReason__c,
      'Absence status reason not updated successfully'
    );
  }

  @isTest
  public static void testEventPublishing() {
    Contact con = getContact();
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    cvab__Claim__c claim = new cvab__Claim__c(
      cvab__ReturnToWork__c = Date.newInstance(2012, 1, 1),
      cvab__Employee__c = con.id,
      TotalOverpayments__c = 0.0
    );
    insert claim;
    TriggerHandler.clearAllBypasses();

    cvab__Claim__c oldClaim = [
      SELECT
        id,
        cvab__AbsenceStatus__c,
        cvab__ReturnToWork__c,
        cvab__Employee__c,
        TotalOverpayments__c,
        cvint__DisabilityClaim__c
      FROM cvab__Claim__c
      WHERE cvab__ReturnToWork__c = :Date.newInstance(2012, 1, 1)
    ];

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    claim.cvab__ReturnToWork__c = Date.newInstance(2024, 1, 1);
    update claim;
    TriggerHandler.clearAllBypasses();
    cvab__Claim__c newClaim = [
      SELECT
        id,
        cvab__AbsenceStatus__c,
        cvab__ReturnToWork__c,
        cvab__Employee__c,
        TotalOverpayments__c,
        cvint__DisabilityClaim__c
      FROM cvab__Claim__c
      WHERE cvab__ReturnToWork__c = :Date.newInstance(2024, 1, 1)
    ];

    CvabClaimTriggerHandler handler = new CvabClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cvab__Claim__c>{ newClaim },
      new List<cvab__Claim__c>{ oldClaim },
      new Map<Id, cvab__Claim__c>{ oldClaim.id => oldClaim },
      eventPublisherDouble
    );
    Test.startTest();
    handler.afterUpdate();
    Test.stopTest();

    List<UpdateCancelledStatusReason__e> expectedOutput = new List<UpdateCancelledStatusReason__e>{
      new UpdateCancelledStatusReason__e(
        ClaimId__c = newClaim.id,
        ReturnToWork__c = newClaim.cvab__ReturnToWork__c
      )
    };
    List<UpdateCancelledStatusReason__e> actualOutcome = (List<UpdateCancelledStatusReason__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    System.assertEquals(expectedOutput, actualOutcome, 'Event not published');
  }

  @istest
  public static void absenceClaimTest() {
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    case c = [
      SELECT
        id,
        Employee_Statement__c,
        Employer_Statement__c,
        ClaimIntakeLastRunByUser__c,
        ContactId
      FROM case
    ];

    List<cvab__claim__c> oldClaimsList = [
      SELECT
        id,
        cvab__AbsenceStatus__c,
        cvab__Employee__c,
        TotalOverpayments__c,
        IntakeCase__c,
        cvab__ReturnToWork__c,
        cvint__DisabilityClaim__c
      FROM cvab__claim__c
    ];
    List<cvab__claim__c> newClaimList = [
      SELECT
        id,
        cvab__AbsenceStatus__c,
        cvab__Employee__c,
        TotalOverpayments__c,
        IntakeCase__c,
        cvab__ReturnToWork__c,
        cvint__DisabilityClaim__c
      FROM cvab__claim__c
    ];
    newClaimList[0].cvab__Employee__c = c.ContactId;
    Map<Id, cvab__claim__c> oldClaimMap = new Map<Id, cvab__claim__c>();
    for (cvab__claim__c clm : oldClaimsList) {
      oldClaimMap.put(clm.Id, clm);
    }
    Amoss_Instance mockEventPublisher1 = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher1.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble1 = (EventPublisher) mockEventPublisher1.getDouble();

    CvabClaimTriggerHandler testHandler = new CvabClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      newClaimList,
      oldClaimsList,
      null,
      eventPublisherDouble1
    );

    TriggerHandler.clearAllBypasses();
    Test.startTest();
    testHandler.afterUpdate();
    Test.stopTest();

    List<ClaimCreatedFromCase__e> actualPublishEventOutcome = (List<ClaimCreatedFromCase__e>) mockEventPublisher1.call(
        0
      )
      .of('publish')
      .parameter('events');

    ClaimCreatedFromCase__e expectedPublishEvent = new ClaimCreatedFromCase__e();
    expectedPublishEvent.CvabClaimId__c = newClaimList[0].id;
    expectedPublishEvent.IntakeCaseId__c = c.id;

    system.assertEquals(
      expectedPublishEvent.IntakeCaseId__c,
      actualPublishEventOutcome[0].IntakeCaseId__c,
      'Absence Claim Event not Published successfully.'
    );
    system.assertEquals(
      expectedPublishEvent.CvabClaimId__c,
      actualPublishEventOutcome[0].CvabClaimId__c,
      'Absence Claim Event not Published successfully.'
    );
  }

  @istest
  public static void disabilityClaimTest() {
    case c = [
      SELECT
        id,
        Employee_Statement__c,
        Employer_Statement__c,
        ClaimIntakeLastRunByUser__c,
        ContactId
      FROM case
    ];

    List<cve__claim__c> oldClaimsList = [
      SELECT
        id,
        cve__ClaimantInsured__c,
        Autopay__c,
        cve__overpaymentnet__c,
        cvint__AbsenceClaim__c
      FROM cve__claim__c
    ];
    oldClaimsList[0].cve__ClaimantInsured__c = null;

    List<cve__claim__c> newClaimList = [
      SELECT
        id,
        cve__ClaimantInsured__c,
        Autopay__c,
        cve__overpaymentnet__c,
        cvint__AbsenceClaim__c
      FROM cve__claim__c
    ];
    newClaimList[0].cve__ClaimantInsured__c = c.ContactId;
    database.update(newClaimList[0]);
    Map<Id, cve__Claim__c> oldClaimMap = new Map<Id, cve__Claim__c>();
    for (cve__Claim__c clm : oldClaimsList) {
      oldClaimMap.put(clm.Id, clm);
    }

    Map<Id, cve__Claim__c> newClaimMap = new Map<Id, cve__Claim__c>();
    for (cve__Claim__c clm : newClaimList) {
      newClaimMap.put(clm.Id, clm);
    }

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    CveClaimTriggerHandler testHandler = new CveClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      newClaimList,
      oldClaimsList,
      CveClaimTriggerHelper.getHelperInstance()
        .withOldMap(oldClaimMap)
        .withNewMap(newClaimMap),
      eventPublisherDouble
    );

    TriggerHandler.clearAllBypasses();
    Test.startTest();
    testHandler.afterUpdate();
    Test.stopTest();
    ClaimCreatedFromCase__e expectedPublishEvent = new ClaimCreatedFromCase__e();
    expectedPublishEvent.CveClaimId__c = newClaimList[0].id;
    expectedPublishEvent.IntakeCaseId__c = c.id;

    List<ClaimCreatedFromCase__e> actualPublishEventOutcome = (List<ClaimCreatedFromCase__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');
    system.assertequals(
      expectedPublishEvent.IntakeCaseId__c,
      actualPublishEventOutcome[0].IntakeCaseId__c,
      'Insurance Claim Event not Published successfully.'
    );
    system.assertequals(
      expectedPublishEvent.CveClaimId__c,
      actualPublishEventOutcome[0].CveClaimId__c,
      'Insurance Claim Event not Published successfully.'
    );
  }

  @istest
  public static void concurrentClaimTest() {
    test.startTest();
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    TriggerHandler.bypass('CveClaimTriggerHandler');
    case c = [
      SELECT
        id,
        Employee_Statement__c,
        Employer_Statement__c,
        ClaimIntakeLastRunByUser__c,
        ContactId
      FROM case
    ];
    List<cve__claim__c> oldClaimsList = [
      SELECT
        id,
        cve__ClaimantInsured__c,
        Autopay__c,
        cve__overpaymentnet__c,
        cvint__AbsenceClaim__c,
        EmployeeStatement__c,
        EmployerStatement__c,
        IntakeCase__c
      FROM cve__claim__c
    ];
    oldClaimsList[0].cve__ClaimantInsured__c = null;

    cvab__claim__c cbclaim = [
      SELECT id, cvab__Employee__c, TotalOverpayments__c, IntakeCase__c
      FROM cvab__claim__c
      LIMIT 1
    ];

    List<cve__claim__c> newClaimList = [
      SELECT
        id,
        cve__ClaimantInsured__c,
        Autopay__c,
        cve__overpaymentnet__c,
        cvint__AbsenceClaim__c,
        EmployeeStatement__c,
        EmployerStatement__c,
        IntakeCase__c
      FROM cve__claim__c
    ];
    newClaimList[0].cve__ClaimantInsured__c = c.ContactId;
    newClaimList[0].cvint__AbsenceClaim__c = cbclaim.id;

    Map<Id, cve__Claim__c> oldClaimMap = new Map<Id, cve__Claim__c>();
    for (cve__Claim__c clm : oldClaimsList) {
      oldClaimMap.put(clm.Id, clm);
    }

    Map<Id, cve__Claim__c> newClaimMap = new Map<Id, cve__Claim__c>();
    for (cve__Claim__c clm : newClaimList) {
      newClaimMap.put(clm.Id, clm);
    }
    TriggerHandler.clearAllBypasses();
    CveClaimTriggerHandler testHandler = new CveClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      newClaimList,
      oldClaimsList,
      CveClaimTriggerHelper.getHelperInstance()
        .withOldMap(oldClaimMap)
        .withNewMap(newClaimMap),
      EventPublisher.getInstance()
    );

    testHandler.afterUpdate();
    test.stopTest();
    cve__claim__c afterpopulateFromCase = [
      SELECT id, EmployeeStatement__c
      FROM cve__claim__c
      LIMIT 1
    ];
    system.assertequals(
      true,
      afterpopulateFromCase.EmployeeStatement__c,
      'Concurrent claim not populated from case.'
    );
  }
  @isTest
  static void claimTATCalculation() {
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    cvabClaim.UsableCvabStatus__c = 'Open';
    cvabClaim.cvab__Status__c = 'Open';
    insert cvabClaim;
    TriggerHandler.clearAllBypasses();

    Case cs = new Case();
    cs.CvabClaim__c = cvabClaim.Id;
    insert cs;

    cvab__Claim__c claim = [
      SELECT
        Id,
        UsableCvabStatus__c,
        CaseCreatedDate__c,
        StatusChangedDate__c,
        FinalStatusChangedDate__c,
        cvab__AbsenceStatus__c,
        cvab__Status__c
      FROM cvab__Claim__c
      WHERE id = :cvabClaim.id
    ];

    Map<Id, cvab__Claim__c> oldClaims = getMap(
      new List<cvab__Claim__c>{ claim }
    );
    cvabClaim.UsableCvabStatus__c = 'Closed';
    cvabClaim.cvab__Status__c = 'Closed';

    Test.startTest();
    CvabClaimTriggerHandler testHandler = new CvabClaimTriggerHandler(
      CvabandCveClaimTriggerHelper.getInstance(),
      new List<cvab__Claim__c>{ cvabClaim },
      null,
      oldClaims,
      null
    );
    testHandler.beforeUpdate();
    Test.stopTest();

    Case csResult = [SELECT Id, CreatedDate FROM Case LIMIT 1];
    Date caseCreatedDate = Date.newInstance(
      csResult.CreatedDate.year(),
      csResult.CreatedDate.month(),
      csResult.CreatedDate.day()
    );
    Date claimCaseCreatedDate = Date.newInstance(
      cvabClaim.CaseCreatedDate__c.year(),
      cvabClaim.CaseCreatedDate__c.month(),
      cvabClaim.CaseCreatedDate__c.day()
    );

    Assert.areEqual(
      caseCreatedDate,
      claimCaseCreatedDate,
      'Case Created date was not populated correctly'
    );
    Assert.areEqual(
      system.today(),
      cvabClaim.StatusChangedDate__c,
      'Status Changed date was not populated correctly'
    );
    Assert.areEqual(
      system.today(),
      cvabClaim.FinalStatusChangedDate__c,
      'Final Status Changed date was not populated correctly'
    );
  }

  static Map<Id, cvab__Claim__c> getMap(List<cvab__Claim__c> claims) {
    Map<Id, cvab__Claim__c> claimMap = new Map<Id, cvab__Claim__c>();
    for (cvab__Claim__c clm : claims) {
      claimMap.put(clm.Id, clm);
    }
    return claimMap;
  }
}