@IsTest
public class AppliedAdjustmentTriggerTest {
  @TestSetup
  static void makeData() {
    Account org = (Account) new TestAccountBuilder()
      .withAccountName('TestAccount')
      .buildAndInsert();

    SObject grp = new TestGroupBuilder()
      .withMasterGroupId(org.Id)
      .withName('testGroup')
      .buildAndInsert();

    Contact employee = (Contact) new TestContactBuilder()
      .withAccountId(org.Id)
      .withGroupId(grp.Id)
      .buildAndInsert();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    TriggerHandler.bypass('CveClaimTriggerHandler');
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    TriggerHandler.bypass('BenefitClaimedTriggerHandler');

    cve__Product__c product = new cve__Product__c(cve__Account__c = org.Id);
    insert product;

    cve__Benefit__c benefit = new cve__Benefit__c(
      Name = 'TestBenefit',
      cve__Product__c = product.Id,
      cve__BenefitPercentage__c = 50.00,
      RecordTypeId = Schema.SObjectType.cve__Benefit__c.getRecordTypeInfosByName()
        .get('Short Term Disability')
        .getRecordTypeId()
    );
    insert benefit;

    cve__Class__c clazz = new cve__Class__c(
      Name = 'Clazz1',
      cve__Account__c = org.Id
    );
    insert clazz;

    cve__Policy__c policy = new cve__Policy__c(
      cve__Product__c = product.Id,
      cve__Version__c = '1.0',
      cve__AdviceToPay__c = true
    );
    insert policy;

    cve__PolicyBenefit__c pBenefit = new cve__PolicyBenefit__c(
      cve__Class__c = clazz.Id,
      cve__Benefit__c = benefit.Id,
      cve__Policy__c = policy.Id
    );
    insert pBenefit;

    cve__Claim__c claim = new cve__Claim__c(
      cve__Policy__c = policy.Id,
      cve__ClaimantInsuredAccount__c = org.Id,
      cve__ClaimantInsured__c = employee.Id,
      cve__PreDisabilityEarningsPeriod__c = 'Weekly',
      cve__PreDisabilityEarnings__c = 1000
    );
    insert claim;
    cvab__Claim__c cvabClaim = new cvab__Claim__c(
      cvab__Employee__c = employee.Id
    );
    insert cvabClaim;

    cvab__ClaimLeave__c cl = new cvab__ClaimLeave__c(
      cvab__Claim__c = cvabClaim.Id,
      cvab__StartDate__c = Date.today().addDays(-60),
      cvab__EndDate__c = Date.today()
    );
    insert cl;

    cvab__ProviderCertification__c providerCertification = new cvab__ProviderCertification__c(
      cvab__CertifiedClaim__c = cvabClaim.Id,
      cvab__ProviderReason__c = 'Employees own illness',
      cvab__LeaveType__c = 'Continuous',
      cvab__StartDate__c = system.today() - 15,
      cvab__EndDate__c = system.today() - 13,
      cvab__AverageWeeklyWage__c = 600
    );
    insert providerCertification;

    cve__ClassRelationship__c cr = new cve__ClassRelationship__c(
      cve__Class__c = clazz.Id,
      cve__Contact__c = claim.cve__ClaimantInsured__c
    );
    insert cr;

    cve__BenefitClaimed__c bClaimed = new cve__BenefitClaimed__c(
      cve__Benefit__c = benefit.Id,
      cve__Claim__c = claim.Id,
      cve__Policy__c = policy.id,
      cve__ClaimantInsuredAccount__c = claim.cve__ClaimantInsuredAccount__c,
      cve__BenefitAmountPeriod__c = 'Weekly',
      cve__BenefitAmount__c = 1000,
      cve__DateOfDisability__c = Date.today(),
      RecordTypeId = Schema.SObjectType.cve__BenefitClaimed__c.getRecordTypeInfosByName()
        .get('Short Term Disability')
        .getRecordTypeId()
    );
    insert bClaimed;

    List<cve__PaymentSpecification__c> payemntSpecsRecords = new List<cve__PaymentSpecification__c>();
    //CVE Payment Spec
    cve__PaymentSpecification__c paymentSpec = new cve__PaymentSpecification__c(
      cve__BenefitClaimed__c = bClaimed.Id,
      cve__PaymentType__c = 'Benefit',
      cve__Claim__c = claim.Id,
      cve__AmountPeriod__c = 'Weekly',
      cve__Amount__c = 1000
    );
    payemntSpecsRecords.add(paymentSpec);

    //CVAB Payment Spec
    cve__PaymentSpecification__c paymentSpec2 = new cve__PaymentSpecification__c(
      cve__PaymentType__c = 'Benefit',
      cvint__AbsenceClaim__c = cvabClaim.Id,
      cve__AmountPeriod__c = 'Weekly',
      cve__Amount__c = 1000
    );
    payemntSpecsRecords.add(paymentSpec2);
    insert payemntSpecsRecords;

    cvab__DateRange__c dr = new cvab__DateRange__c(
      cvab__ClaimLeave__c = cl.Id,
      cvab__ExplainationOfBenefitAmount__c = '<ul><li><strong>Base Period</strong> (<em>period to search for two highest quartly earnings under</em>) is from 1/1/2023 to 12/31/2023.</li><li><strong>Earnings</strong> (<em>did not find any earnings from Earnings By Completed Calendar Quarter</em>).</li><li><strong>Earnings</strong> (<em>found Earnings records from 1/1/2023 to 12/31/2023</em>).</li><li><strong>Highest Quarterly Earnings</strong> (<em>found in quarter starting on 1/1/2023</em>) is $12500.</li><li><strong>Second Highest Quarterly Earnings</strong> (<em>found in quarter starting on 4/1/2023</em>) is $12500.</li><li><strong>Average Weekly Earnings</strong> is $962.</li><li><strong>Benefit Rate</strong> (<em>employee average weekly wage (greater than half of state&#39;s average weekly wage $1796.72)</em>) is (80% of half the state&#39;s average weekly wage) + (50% of difference of employee&#39;s average weekly wage and half of state&#39;s average weekly wage).</li><li><strong>Weekly Amount</strong> (<em>calculated benefit</em>) is $750.51.</li><li><strong>Average work days per week</strong> (<em>taken from the employee&#39;s schedule</em>) is 5.</li><li><strong>Daily Amount</strong> (<em>weekly amount / average work days per week</em>) is $150.10.</li><li><strong>Benefit Amount</strong> (<em>8.60 weeks * $750.51</em>) is $6454.37.</li></ul>',
      cvab__Status__c = 'Approved',
      cvint__PaymentSpecification__c = payemntSpecsRecords[1].id
    );
    insert dr;

    cve__Allocation__c allocRec = new cve__Allocation__c(
      cve__PaymentSpecification__c = payemntSpecsRecords[0].id,
      cve__Contact__c = employee.Id
    );
    insert allocRec;
    List<cve__Adjustment__c> adjustmentRecords = new List<cve__Adjustment__c>();
    //CVE Claims adjustments
    cve__Adjustment__c adjustmentCVE1 = new cve__Adjustment__c(
      cve__Type__c = 'Additional Income (Pre-Tax)',
      cve__Status__c = 'Actual',
      cve__Start__c = System.today(),
      cve__Through__c = System.today().addDays(6),
      cve__Period__c = 'Weekly',
      cve__Amount__c = 200,
      cve__PaymentSpecification__c = payemntSpecsRecords[0].Id
    );
    adjustmentRecords.add(adjustmentCVE1);
    cve__Adjustment__c adjustmentCVE2 = new cve__Adjustment__c(
      cve__Type__c = 'Additional Income (Pre-Tax)',
      cve__Status__c = 'Actual',
      cve__Start__c = System.today().addDays(7),
      cve__Through__c = System.today().addDays(13),
      cve__Period__c = 'Weekly',
      cve__Amount__c = 250,
      cve__PaymentSpecification__c = payemntSpecsRecords[0].Id
    );
    adjustmentRecords.add(adjustmentCVE2);

    //CVAB Claims Adjustments
    cve__Adjustment__c adjustmentCVAB1 = new cve__Adjustment__c(
      cve__Type__c = 'Additional Income (Pre-Tax)',
      cve__Status__c = 'Actual',
      cve__Start__c = System.today(),
      cve__Through__c = System.today().addDays(6),
      cve__Period__c = 'Weekly',
      cve__Amount__c = 250,
      cve__PaymentSpecification__c = payemntSpecsRecords[1].Id
    );
    adjustmentRecords.add(adjustmentCVAB1);
    cve__Adjustment__c adjustmentCVAB2 = new cve__Adjustment__c(
      cve__Type__c = 'Additional Income (Pre-Tax)',
      cve__Status__c = 'Actual',
      cve__Start__c = System.today().addDays(7),
      cve__Through__c = System.today().addDays(13),
      cve__Period__c = 'Weekly',
      cve__Amount__c = 250,
      cve__PaymentSpecification__c = payemntSpecsRecords[1].Id
    );
    adjustmentRecords.add(adjustmentCVAB2);

    insert adjustmentRecords;

    List<cve__UnallocatedPayment__c> unallocatedPaymentRecs = new List<cve__UnallocatedPayment__c>();
    //CVE Payments
    cve__UnallocatedPayment__c unallocatedPaymentCVE1 = new cve__UnallocatedPayment__c(
      cve__PaymentSpecification__c = payemntSpecsRecords[0].Id,
      cve__Start__c = Date.today(),
      cve__Through__c = Date.today().addDays(6),
      cve__GrossBenefit__c = 1000
    );
    unallocatedPaymentRecs.add(unallocatedPaymentCVE1);
    cve__UnallocatedPayment__c unallocatedPaymentCVE2 = new cve__UnallocatedPayment__c(
      cve__PaymentSpecification__c = payemntSpecsRecords[0].Id,
      cve__Start__c = Date.today().addDays(7),
      cve__Through__c = Date.today().addDays(13),
      cve__GrossBenefit__c = 1000
    );
    unallocatedPaymentRecs.add(unallocatedPaymentCVE2);

    //CVAB Payments
    cve__UnallocatedPayment__c unallocatedPaymentCVAB1 = new cve__UnallocatedPayment__c(
      cve__PaymentSpecification__c = payemntSpecsRecords[1].Id,
      cve__Start__c = Date.today(),
      cve__Through__c = Date.today().addDays(6),
      cve__GrossBenefit__c = 1000
    );
    unallocatedPaymentRecs.add(unallocatedPaymentCVAB1);
    cve__UnallocatedPayment__c unallocatedPaymentCVAB2 = new cve__UnallocatedPayment__c(
      cve__PaymentSpecification__c = payemntSpecsRecords[1].Id,
      cve__Start__c = Date.today().addDays(7),
      cve__Through__c = Date.today().addDays(13),
      cve__GrossBenefit__c = 1000
    );
    unallocatedPaymentRecs.add(unallocatedPaymentCVAB2);

    insert unallocatedPaymentRecs;

    cve__ContactHistory__c ch = new cve__ContactHistory__c(
      cve__Contact__c = employee.Id,
      cve__Earnings__c = 60000,
      cve__EarningsPeriod__c = 'Year',
      cve__Effective__c = Date.today().addDays(-1)
    );
    insert ch;

    cve__DateConversionFactors__c dateConversionFactors = new cve__DateConversionFactors__c(
      cve__BusinessDaysPerWeek__c = 5.00000000,
      cve__BusinessHoursName__c = 'USABLE',
      cve__BusinessHoursPerDay__c = 8.00000000,
      cve__DaysPerMonth__c = 30.43680000,
      cve__DaysPerWeek__c = 7.00000000,
      cve__DaysPerYear__c = 365.24220000,
      cve__InterestDaysPerYear__c = 365.00000000,
      cve__MonthsPerYear__c = 12.00000000,
      cve__WeeksPerMonth__c = 4.34810000,
      cve__WeeksPerYear__c = 52.00000000
    );
    insert dateConversionFactors;
    TriggerHandler.clearAllBypasses();
  }

  @isTest
  static void checkAdditionalIncomeAdj() {
    List<cve__Adjustment__c> adjRec = [SELECT Id FROM cve__Adjustment__c];
    List<cve__UnallocatedPayment__c> unallocPayment = [
      SELECT Id, cve__PaymentSpecification__c
      FROM cve__UnallocatedPayment__c
    ];
    List<cve__AppliedAdjustment__c> appAdjRecs = new List<cve__AppliedAdjustment__c>();
    TriggerHandler.bypass('AppliedAdjustmentTriggerHandler');
    // Create the applied adjustment record
    cve__AppliedAdjustment__c appliedAdjustment = new cve__AppliedAdjustment__c();
    appliedAdjustment.cve__Adjustment__c = adjRec[0].Id;
    appliedAdjustment.cve__Start__c = System.today() - 10;
    appliedAdjustment.cve__Through__c = System.today() - 6;
    appliedAdjustment.cve__Amount__c = -200;
    appliedAdjustment.cve__UnallocatedPayment__c = unallocPayment[0].Id;
    appAdjRecs.add(appliedAdjustment);
    cve__AppliedAdjustment__c appliedAdj = new cve__AppliedAdjustment__c();
    appliedAdj.cve__Adjustment__c = adjRec[1].Id;
    appliedAdj.cve__Start__c = System.today() - 5;
    appliedAdj.cve__Through__c = System.today() - 2;
    appliedAdj.cve__Amount__c = -200;
    appliedAdj.cve__UnallocatedPayment__c = unallocPayment[1].Id;
    appAdjRecs.add(appliedAdj);

    cve__AppliedAdjustment__c appliedAdjust = new cve__AppliedAdjustment__c(
      cve__Adjustment__c = adjRec[2].Id,
      cve__Start__c = System.today() - 15,
      cve__Through__c = System.today() - 13,
      cve__Amount__c = -200,
      cve__UnallocatedPayment__c = unallocPayment[1].Id
    );
    appAdjRecs.add(appliedAdjust);
    cve__AppliedAdjustment__c absAppliedAdjust = new cve__AppliedAdjustment__c(
      cve__Adjustment__c = adjRec[2].Id,
      cve__Start__c = System.today() - 15,
      cve__Through__c = System.today() - 13,
      cve__Amount__c = -200,
      cve__UnallocatedPayment__c = unallocPayment[2].Id
    );
    appAdjRecs.add(absAppliedAdjust);
    cve__AppliedAdjustment__c absenceAppliedAdjust = new cve__AppliedAdjustment__c(
      cve__Adjustment__c = adjRec[3].Id,
      cve__Start__c = System.today() - 12,
      cve__Through__c = System.today() - 10,
      cve__Amount__c = -200,
      cve__UnallocatedPayment__c = unallocPayment[2].Id
    );
    appAdjRecs.add(absenceAppliedAdjust);
    insert appAdjRecs;
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    AppliedAdjustmentTriggerHandler.ContextVariables cv = new AppliedAdjustmentTriggerHandler.ContextVariables(
      null,
      appAdjRecs,
      null,
      null
    );

    AppliedAdjustmentTriggerHandler handler = new AppliedAdjustmentTriggerHandler(
      AppliedAdjustmentTriggerHelper.getInstance(),
      eventPublisherDouble,
      cv
    );
    Test.startTest();
    handler.afterInsert();

    Test.stopTest();

    List<cve__Adjustment__c> adjustmentCreatedRecords = [
      SELECT Id, cve__Type__c
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'Additional Income Offset (Pre-Tax)'
    ];
    System.assertEquals(
      'Additional Income Offset (Pre-Tax)',
      adjustmentCreatedRecords[0].cve__Type__c,
      'Adjustment created is not of correct type'
    );

    List<RecalculatePayments__e> calcPayments = new List<RecalculatePayments__e>();
    List<Id> paySpecIds = new List<Id>();
    paySpecIds.add(unallocPayment[0].cve__PaymentSpecification__c);
    paySpecIds.add(unallocPayment[0].cve__PaymentSpecification__c);
    paySpecIds.add(unallocPayment[1].cve__PaymentSpecification__c);
    paySpecIds.add(unallocPayment[2].cve__PaymentSpecification__c);
    paySpecIds.add(unallocPayment[2].cve__PaymentSpecification__c);
    for (Id pay : paySpecIds) {
      calcPayments.add(
        new RecalculatePayments__e(PaymentSpecificationId__c = pay)
      );
    }
    List<RecalculatePayments__e> actualOutcome = (List<RecalculatePayments__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');
    Assert.areEqual(
      calcPayments,
      actualOutcome,
      'Published RecalculatePayments__e does not match expected RecalculatePayments__e'
    );
  }

  @isTest
  static void checkSocialSecurityTaxAdj() {
    List<cve__UnallocatedPayment__c> unallocPayment = [
      SELECT Id, cve__PaymentSpecification__c
      FROM cve__UnallocatedPayment__c
    ];
    cve__Adjustment__c absAdjustmentRec = new cve__Adjustment__c(
      cve__Type__c = 'Social Security Tax',
      cve__Status__c = 'Actual',
      cve__Start__c = System.today() - 20,
      cve__Through__c = System.today() - 18,
      cve__Period__c = 'Daily',
      cve__Amount__c = 100,
      cve__PaymentSpecification__c = unallocPayment[1]
        .cve__PaymentSpecification__c
    );
    insert absAdjustmentRec;
    List<cve__AppliedAdjustment__c> appAdjRecs = new List<cve__AppliedAdjustment__c>();
    TriggerHandler.bypass('AppliedAdjustmentTriggerHandler');
    // Create the applied adjustment record
    cve__AppliedAdjustment__c appliedAdjustment = new cve__AppliedAdjustment__c();
    appliedAdjustment.cve__Adjustment__c = absAdjustmentRec.Id;
    appliedAdjustment.cve__Start__c = System.today() - 20;
    appliedAdjustment.cve__Through__c = System.today() - 18;
    appliedAdjustment.cve__Amount__c = 200;
    appliedAdjustment.cve__UnallocatedPayment__c = unallocPayment[2].Id;
    appAdjRecs.add(appliedAdjustment);

    insert appAdjRecs;
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    AppliedAdjustmentTriggerHandler.ContextVariables cv = new AppliedAdjustmentTriggerHandler.ContextVariables(
      null,
      appAdjRecs,
      null,
      null
    );

    AppliedAdjustmentTriggerHandler handler = new AppliedAdjustmentTriggerHandler(
      AppliedAdjustmentTriggerHelper.getInstance(),
      eventPublisherDouble,
      cv
    );

    Test.startTest();
    handler.afterInsert();
    Test.stopTest();

    List<cve__Adjustment__c> adjustmentCreatedRecords = [
      SELECT Id, cve__Type__c
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'Additional Income Offset (Pre-Tax)'
    ];
    System.assertEquals(
      0,
      adjustmentCreatedRecords.size(),
      'Trigger Creating Additonal Income Offset Adjustment Records'
    );
  }

  @isTest
  static void checkAdjustmentValueDisability() {
    List<cve__Adjustment__c> adjRec = [SELECT Id FROM cve__Adjustment__c];
    List<cve__UnallocatedPayment__c> unallocPayment = [
      SELECT
        Id,
        cve__PaymentSpecification__c,
        cve__PaymentSpecification__r.cve__Claim__r.Name
      FROM cve__UnallocatedPayment__c
    ];
    List<cve__AppliedAdjustment__c> appAdjRecs = new List<cve__AppliedAdjustment__c>();
    TriggerHandler.bypass('AppliedAdjustmentTriggerHandler');
    // Create the applied adjustment record
    cve__AppliedAdjustment__c appliedAdjustmentCVE1 = new cve__AppliedAdjustment__c();
    appliedAdjustmentCVE1.cve__Adjustment__c = adjRec[0].Id;
    appliedAdjustmentCVE1.cve__Start__c = System.today();
    appliedAdjustmentCVE1.cve__Through__c = System.today().addDays(6);
    appliedAdjustmentCVE1.cve__Amount__c = -200;
    appliedAdjustmentCVE1.cve__UnallocatedPayment__c = unallocPayment[0].Id;
    appAdjRecs.add(appliedAdjustmentCVE1);
    cve__AppliedAdjustment__c appliedAdjustmentCVE2 = new cve__AppliedAdjustment__c();
    appliedAdjustmentCVE2.cve__Adjustment__c = adjRec[1].Id;
    appliedAdjustmentCVE2.cve__Start__c = System.today().addDays(7);
    appliedAdjustmentCVE2.cve__Through__c = System.today().addDays(13);
    appliedAdjustmentCVE2.cve__Amount__c = -250;
    appliedAdjustmentCVE2.cve__UnallocatedPayment__c = unallocPayment[1].Id;
    appAdjRecs.add(appliedAdjustmentCVE2);

    insert appAdjRecs;
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    AppliedAdjustmentTriggerHandler.ContextVariables cv = new AppliedAdjustmentTriggerHandler.ContextVariables(
      null,
      appAdjRecs,
      null,
      null
    );

    AppliedAdjustmentTriggerHandler handler = new AppliedAdjustmentTriggerHandler(
      AppliedAdjustmentTriggerHelper.getInstance(),
      eventPublisherDouble,
      cv
    );
    Test.startTest();
    handler.afterInsert();

    Test.stopTest();

    List<cve__Adjustment__c> adjustmentCreatedRecords = [
      SELECT Id, cve__Amount__c
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'Additional Income Offset (Pre-Tax)'
    ];
    System.assertEquals(
      46.15,
      adjustmentCreatedRecords[0].cve__Amount__c,
      'Adjustment created is not of correct Amount'
    );
    System.assertEquals(
      96.15,
      adjustmentCreatedRecords[1].cve__Amount__c,
      'Adjustment created is not of correct Amount'
    );
  }

  @isTest
  static void checkAdjustmentValueAbsence() {
    List<cve__Adjustment__c> adjRec = [SELECT Id FROM cve__Adjustment__c];
    List<cve__UnallocatedPayment__c> unallocPayment = [
      SELECT
        Id,
        cve__PaymentSpecification__c,
        cve__PaymentSpecification__r.cvint__AbsenceClaim__r.Name
      FROM cve__UnallocatedPayment__c
    ];
    List<cve__AppliedAdjustment__c> appAdjRecs = new List<cve__AppliedAdjustment__c>();
    TriggerHandler.bypass('AppliedAdjustmentTriggerHandler');
    // Create the applied adjustment record
    cve__AppliedAdjustment__c appliedAdjustment = new cve__AppliedAdjustment__c();
    appliedAdjustment.cve__Adjustment__c = adjRec[0].Id;
    appliedAdjustment.cve__Start__c = System.today();
    appliedAdjustment.cve__Through__c = System.today().addDays(6);
    appliedAdjustment.cve__Amount__c = -200;
    appliedAdjustment.cve__UnallocatedPayment__c = unallocPayment[2].Id;
    appAdjRecs.add(appliedAdjustment);
    cve__AppliedAdjustment__c appliedAdj = new cve__AppliedAdjustment__c();
    appliedAdj.cve__Adjustment__c = adjRec[1].Id;
    appliedAdj.cve__Start__c = System.today().addDays(7);
    appliedAdj.cve__Through__c = System.today().addDays(13);
    appliedAdj.cve__Amount__c = -250;
    appliedAdj.cve__UnallocatedPayment__c = unallocPayment[3].Id;
    appAdjRecs.add(appliedAdj);

    insert appAdjRecs;
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    AppliedAdjustmentTriggerHandler.ContextVariables cv = new AppliedAdjustmentTriggerHandler.ContextVariables(
      null,
      appAdjRecs,
      null,
      null
    );

    AppliedAdjustmentTriggerHandler handler = new AppliedAdjustmentTriggerHandler(
      AppliedAdjustmentTriggerHelper.getInstance(),
      eventPublisherDouble,
      cv
    );
    Test.startTest();
    handler.afterInsert();

    Test.stopTest();

    List<cve__Adjustment__c> adjustmentCreatedRecords = [
      SELECT Id, cve__Amount__c
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'Additional Income Offset (Pre-Tax)'
    ];
    System.assertEquals(
      238,
      adjustmentCreatedRecords[0].cve__Amount__c,
      'Adjustment created is not of correct Amount'
    );
    System.assertEquals(
      288,
      adjustmentCreatedRecords[1].cve__Amount__c,
      'Adjustment created is not of correct Amount'
    );
  }

  @isTest
  static void checkNoAdjustmentCreated() {
    //Test for when new adjustment amount is <= 0 and therefore should not create
    List<cve__Adjustment__c> adjRec = [SELECT Id FROM cve__Adjustment__c];
    List<cve__UnallocatedPayment__c> unallocPayment = [
      SELECT Id, cve__PaymentSpecification__c
      FROM cve__UnallocatedPayment__c
    ];
    List<cve__AppliedAdjustment__c> appAdjRecs = new List<cve__AppliedAdjustment__c>();
    TriggerHandler.bypass('AppliedAdjustmentTriggerHandler');
    // Create the applied adjustment record
    cve__AppliedAdjustment__c appliedAdjustment = new cve__AppliedAdjustment__c();
    appliedAdjustment.cve__Adjustment__c = adjRec[0].Id;
    appliedAdjustment.cve__Start__c = System.today();
    appliedAdjustment.cve__Through__c = System.today().addDays(6);
    appliedAdjustment.cve__Amount__c = -50;
    appliedAdjustment.cve__UnallocatedPayment__c = unallocPayment[0].Id;
    appAdjRecs.add(appliedAdjustment);
    cve__AppliedAdjustment__c appliedAdj = new cve__AppliedAdjustment__c();
    appliedAdj.cve__Adjustment__c = adjRec[1].Id;
    appliedAdj.cve__Start__c = System.today().addDays(7);
    appliedAdj.cve__Through__c = System.today().addDays(13);
    appliedAdj.cve__Amount__c = -50;
    appliedAdj.cve__UnallocatedPayment__c = unallocPayment[1].Id;
    appAdjRecs.add(appliedAdj);

    insert appAdjRecs;
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    AppliedAdjustmentTriggerHandler.ContextVariables cv = new AppliedAdjustmentTriggerHandler.ContextVariables(
      null,
      appAdjRecs,
      null,
      null
    );

    AppliedAdjustmentTriggerHandler handler = new AppliedAdjustmentTriggerHandler(
      AppliedAdjustmentTriggerHelper.getInstance(),
      eventPublisherDouble,
      cv
    );
    Test.startTest();
    handler.afterInsert();

    Test.stopTest();

    List<cve__Adjustment__c> adjustmentCreatedRecords = [
      SELECT Id, cve__Amount__c
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'Additional Income Offset (Pre-Tax)'
    ];
    System.assertEquals(
      0,
      adjustmentCreatedRecords.size(),
      'More adjustments created than expected'
    );
  }
}