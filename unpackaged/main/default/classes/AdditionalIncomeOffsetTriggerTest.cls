@isTest
public class AdditionalIncomeOffsetTriggerTest {
  @TestSetup
  public static void testSetup() {
    cve__Claim__c cveClaim = new cve__Claim__c();
    insert cveClaim;

    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;
    cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
      cve__Claim__c = cveClaim.id,
      cvint__AbsenceClaim__c = null
    );
    insert ps1;
    cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
      cve__Claim__c = null,
      cvint__AbsenceClaim__c = cvabClaim.id
    );
    insert ps2;
  }

  @isTest
  public static void triggerTest() {
    cve__Claim__c c1 = getCveClaim();
    cve__PaymentSpecification__c p1 = getCvePaymentSpec(c1.id);

    Test.startTest();
    AdditionalIncome__c income = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 200.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'PTO',
      PaymentSpecification__c = p1.id,
      Period__c = 'Weekly',
      StartDate__c = Date.newInstance(2024, 1, 1)
    );
    insert income;
    Test.stopTest();

    Assert.areEqual(
      1,
      [
          SELECT id
          FROM cve__Adjustment__c
          WHERE cve__PaymentSpecification__c = :p1.id
        ]
        .size()
    );
  }

  @isTest
  public static void additionalIncome_on_cveClaim_creates_adjustments() {
    cve__Claim__c c1 = getCveClaim();
    cve__PaymentSpecification__c p1 = getCvePaymentSpec(c1.id);
    TriggerHandler.bypass('AdditionalIncomeTriggerHandler');
    AdditionalIncome__c income = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 200.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'PTO',
      PaymentSpecification__c = p1.id,
      Period__c = 'Weekly',
      StartDate__c = Date.newInstance(2024, 1, 1)
    );
    insert income;
    TriggerHandler.clearAllBypasses();
    OffsetEvent eventPayload = new OffsetEvent(
      p1,
      c1,
      null,
      new List<AdditionalIncome__c>{ income }
    );
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    AdditionalIncomeOffsetTriggerHandler handler = new AdditionalIncomeOffsetTriggerHandler(
      AdditionalIncomeOffsetTriggerHelper.getInstance(),
      new List<AdditionalIncomeOffset__e>{
        new AdditionalIncomeOffset__e(
          OffsetIncomeData__c = JSON.serialize(eventPayload)
        )
      },
      eventPublisherDouble
    );
    handler.afterInsert();

    Test.stopTest();

    List<RecalculatePayments__e> actualOutcome = (List<RecalculatePayments__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      new List<RecalculatePayments__e>{
        new RecalculatePayments__e(PaymentSpecificationId__c = p1.id)
      },
      actualOutcome
    );
    Assert.areEqual(
      1,
      [
          SELECT id
          FROM cve__Adjustment__c
          WHERE cve__PaymentSpecification__c = :p1.id
        ]
        .size()
    );
  }

  @isTest
  public static void additionalIncome_on_cvabClaim_creates_adjustments() {
    cvab__Claim__c c1 = getCvabClaim();
    cve__PaymentSpecification__c p1 = getCvabPaymentSpec(c1.id);
    TriggerHandler.bypass('AdditionalIncomeTriggerHandler');
    AdditionalIncome__c income = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 200.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'PTO',
      PaymentSpecification__c = p1.id,
      Period__c = 'Weekly',
      StartDate__c = Date.newInstance(2024, 1, 1)
    );
    insert income;
    TriggerHandler.clearAllBypasses();
    OffsetEvent eventPayload = new OffsetEvent(
      p1,
      null,
      c1,
      new List<AdditionalIncome__c>{ income }
    );
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    AdditionalIncomeOffsetTriggerHandler handler = new AdditionalIncomeOffsetTriggerHandler(
      AdditionalIncomeOffsetTriggerHelper.getInstance(),
      new List<AdditionalIncomeOffset__e>{
        new AdditionalIncomeOffset__e(
          OffsetIncomeData__c = JSON.serialize(eventPayload)
        )
      },
      eventPublisherDouble
    );
    handler.afterInsert();

    Test.stopTest();

    List<RecalculatePayments__e> actualOutcome = (List<RecalculatePayments__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');
    Assert.areEqual(
      new List<RecalculatePayments__e>{
        new RecalculatePayments__e(PaymentSpecificationId__c = p1.id)
      },
      actualOutcome
    );
    Assert.areEqual(
      1,
      [
          SELECT id
          FROM cve__Adjustment__c
          WHERE cve__PaymentSpecification__c = :p1.id
        ]
        .size()
    );
  }

  @isTest
  public static void pfmlAdditionalIncome_on_IntegratedClaim_creates_adjustments() {
    cve__Claim__c cveClaim = getCveClaim();
    cve__PaymentSpecification__c cvePaymentSpec = getCvePaymentSpec(
      cveClaim.id
    );
    cvab__Claim__c cvabClaim = getCvabClaim();
    cve__PaymentSpecification__c cvabPaymentSpec = getCvabPaymentSpec(
      cvabClaim.id
    );
    cveClaim.cvint__AbsenceClaim__c = cvabClaim.id;
    cvabClaim.cvint__DisabilityClaim__c = cveClaim.id;

    update cveClaim;
    update cvabClaim;

    TriggerHandler.bypass('AdditionalIncomeTriggerHandler');
    AdditionalIncome__c income = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 200.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'PFML Income',
      PaymentSpecification__c = cvePaymentSpec.id,
      Period__c = 'Weekly',
      StartDate__c = Date.newInstance(2024, 1, 1)
    );
    insert income;
    TriggerHandler.clearAllBypasses();
    OffsetEvent eventPayload = new OffsetEvent(
      cvePaymentSpec,
      cveClaim,
      cvabClaim,
      new List<AdditionalIncome__c>{ income }
    );
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    AdditionalIncomeOffsetTriggerHandler handler = new AdditionalIncomeOffsetTriggerHandler(
      AdditionalIncomeOffsetTriggerHelper.getInstance(),
      new List<AdditionalIncomeOffset__e>{
        new AdditionalIncomeOffset__e(
          OffsetIncomeData__c = JSON.serialize(eventPayload)
        )
      },
      eventPublisherDouble
    );
    handler.afterInsert();

    Test.stopTest();

    List<RecalculatePayments__e> actualOutcome = (List<RecalculatePayments__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');
    Assert.areEqual(
      new List<RecalculatePayments__e>{
        new RecalculatePayments__e(
          PaymentSpecificationId__c = cvePaymentSpec.id
        )
      },
      actualOutcome
    );
    Assert.areEqual(
      1,
      [
          SELECT id
          FROM cve__Adjustment__c
          WHERE cve__PaymentSpecification__c = :cvePaymentSpec.id
        ]
        .size()
    );
  }

  @isTest
  public static void stdAdditionalIncome_on_IntegratedClaim_creates_adjustments() {
    cve__Claim__c cveClaim = getCveClaim();
    cve__PaymentSpecification__c cvePaymentSpec = getCvePaymentSpec(
      cveClaim.id
    );
    cvab__Claim__c cvabClaim = getCvabClaim();
    cve__PaymentSpecification__c cvabPaymentSpec = getCvabPaymentSpec(
      cvabClaim.id
    );
    cveClaim.cvint__AbsenceClaim__c = cvabClaim.id;
    cvabClaim.cvint__DisabilityClaim__c = cveClaim.id;

    update cveClaim;
    update cvabClaim;

    TriggerHandler.bypass('AdditionalIncomeTriggerHandler');
    AdditionalIncome__c income1 = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 200.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'STD Income',
      PaymentSpecification__c = cvePaymentSpec.id,
      Period__c = 'Weekly',
      StartDate__c = Date.newInstance(2024, 1, 1)
    );
    insert income1;
    AdditionalIncome__c income2 = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 200.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'PTO',
      PaymentSpecification__c = cvePaymentSpec.id,
      Period__c = 'Weekly',
      StartDate__c = Date.newInstance(2024, 1, 1)
    );
    insert income2;
    TriggerHandler.clearAllBypasses();
    OffsetEvent eventPayload = new OffsetEvent(
      cvePaymentSpec,
      cveClaim,
      cvabClaim,
      new List<AdditionalIncome__c>{ income1, income2 }
    );
    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    AdditionalIncomeOffsetTriggerHandler handler = new AdditionalIncomeOffsetTriggerHandler(
      AdditionalIncomeOffsetTriggerHelper.getInstance(),
      new List<AdditionalIncomeOffset__e>{
        new AdditionalIncomeOffset__e(
          OffsetIncomeData__c = JSON.serialize(eventPayload)
        )
      },
      eventPublisherDouble
    );
    handler.afterInsert();

    Test.stopTest();

    List<RecalculatePayments__e> actualOutcome = (List<RecalculatePayments__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');
    Assert.areEqual(
      new List<RecalculatePayments__e>{
        new RecalculatePayments__e(
          PaymentSpecificationId__c = cvabPaymentSpec.id
        ),
        new RecalculatePayments__e(
          PaymentSpecificationId__c = cvePaymentSpec.id
        )
      },
      actualOutcome
    );
    Assert.areEqual(
      2,
      [
          SELECT id
          FROM cve__Adjustment__c
          WHERE cve__PaymentSpecification__c = :cvabPaymentSpec.id
        ]
        .size()
    );
    Assert.areEqual(
      1,
      [
          SELECT id
          FROM cve__Adjustment__c
          WHERE cve__PaymentSpecification__c = :cvePaymentSpec.id
        ]
        .size()
    );
  }

  public static cve__Claim__c getCveClaim() {
    return [SELECT id FROM cve__Claim__c];
  }

  public static cvab__Claim__c getCvabClaim() {
    return [SELECT id FROM cvab__Claim__c];
  }

  public static cve__PaymentSpecification__c getCvePaymentSpec(Id claimId) {
    return [
      SELECT id
      FROM cve__PaymentSpecification__c
      WHERE cve__Claim__c = :claimId
    ];
  }

  public static cve__PaymentSpecification__c getCvabPaymentSpec(Id claimId) {
    return [
      SELECT id
      FROM cve__PaymentSpecification__c
      WHERE cvint__AbsenceClaim__c = :claimId
    ];
  }
}