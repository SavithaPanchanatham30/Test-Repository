@isTest
public class AdditionalIncomeTriggerTest {
  @TestSetup
  public static void testSetup() {
    cvab__Claim__c absence = new cvab__Claim__c();
    insert absence;
    cve__Claim__c disability = new cve__Claim__c(
      cvint__AbsenceClaim__c = absence.id
    );
    insert disability;
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cve__Claim__c = disability.id,
      cvint__AbsenceClaim__c = null
    );
    insert ps;
  }

  @isTest
  public static void insert_additional_income_for_nonintegrated_disability() {
    cve__PaymentSpecification__c ps = queryPaymentSpec();
    cve__Claim__c disability = [
      SELECT Id, cvint__AbsenceClaim__c
      FROM cve__Claim__c
    ];

    disability.cvint__AbsenceClaim__c = null;
    update disability;
    cvab__Claim__c absence = [SELECT id FROM cvab__Claim__c];

    TriggerHandler.bypass('AdditionalIncomeTriggerHandler');
    AdditionalIncome__c income = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 2000.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'PTO',
      PaymentSpecification__c = ps.id,
      Period__c = 'Yearly',
      StartDate__c = Date.newInstance(2024, 1, 1),
      PFMLClaim__c = null,
      STDClaim__c = null
    );
    insert income;
    TriggerHandler.clearAllBypasses();

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    AdditionalIncomeTriggerHandler testHandler = new AdditionalIncomeTriggerHandler(
      AdditionalIncomeTriggerHelper.getHelperInstance(),
      null,
      new List<AdditionalIncome__c>{ income },
      eventPublisherDouble
    );
    testHandler.afterInsert();

    Test.stopTest();

    OffsetEvent result = new OffsetEvent(
      queryPaymentSpec(),
      disability,
      null,
      getRelatedAdditionalIncomes(ps.id)
    );
    AdditionalIncomeOffset__e expectedOutcome = new AdditionalIncomeOffset__e(
      OffsetIncomeData__c = JSON.serialize(result)
    );
    List<AdditionalIncomeOffset__e> actualOutcome = (List<AdditionalIncomeOffset__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      new List<AdditionalIncomeOffset__e>{ expectedOutcome },
      actualOutcome,
      'Published AdditionalIncomeOffset__e does not match expected AdditionalIncomeOffset__e'
    );
  }

  @isTest
  public static void insert_additional_income_for_integrated_disability() {
    cve__PaymentSpecification__c ps = queryPaymentSpec();
    cve__Claim__c disability = [
      SELECT Id, cvint__AbsenceClaim__c
      FROM cve__Claim__c
    ];

    cvab__Claim__c absence = [SELECT id FROM cvab__Claim__c];

    TriggerHandler.bypass('AdditionalIncomeTriggerHandler');
    AdditionalIncome__c income = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 2000.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'PTO',
      PaymentSpecification__c = ps.id,
      Period__c = 'Yearly',
      StartDate__c = Date.newInstance(2024, 1, 1),
      PFMLClaim__c = null,
      STDClaim__c = null
    );
    insert income;
    TriggerHandler.clearAllBypasses();

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    AdditionalIncomeTriggerHandler testHandler = new AdditionalIncomeTriggerHandler(
      AdditionalIncomeTriggerHelper.getHelperInstance(),
      null,
      new List<AdditionalIncome__c>{ income },
      eventPublisherDouble
    );
    testHandler.afterInsert();

    Test.stopTest();

    OffsetEvent result = new OffsetEvent(
      queryPaymentSpec(),
      disability,
      absence,
      getRelatedAdditionalIncomes(ps.id)
    );
    AdditionalIncomeOffset__e expectedOutcome = new AdditionalIncomeOffset__e(
      OffsetIncomeData__c = JSON.serialize(result)
    );
    List<AdditionalIncomeOffset__e> actualOutcome = (List<AdditionalIncomeOffset__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      new List<AdditionalIncomeOffset__e>{ expectedOutcome },
      actualOutcome,
      'Published AdditionalIncomeOffset__e does not match expected AdditionalIncomeOffset__e'
    );
  }

  @isTest
  public static void insert_additional_income_for_nonintegrated_absence() {
    cve__PaymentSpecification__c ps = queryPaymentSpec();

    cvab__Claim__c absence = [SELECT id FROM cvab__Claim__c];

    ps.cvint__AbsenceClaim__c = absence.Id;
    ps.cve__Claim__c = null;
    update ps;

    TriggerHandler.bypass('AdditionalIncomeTriggerHandler');
    AdditionalIncome__c income = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 2000.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'PTO',
      PaymentSpecification__c = ps.id,
      Period__c = 'Yearly',
      StartDate__c = Date.newInstance(2024, 1, 1),
      PFMLClaim__c = null,
      STDClaim__c = null
    );
    insert income;
    TriggerHandler.clearAllBypasses();

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    AdditionalIncomeTriggerHandler testHandler = new AdditionalIncomeTriggerHandler(
      AdditionalIncomeTriggerHelper.getHelperInstance(),
      null,
      new List<AdditionalIncome__c>{ income },
      eventPublisherDouble
    );
    testHandler.afterInsert();

    Test.stopTest();

    OffsetEvent result = new OffsetEvent(
      queryPaymentSpec(),
      null,
      absence,
      getRelatedAdditionalIncomes(ps.id)
    );
    AdditionalIncomeOffset__e expectedOutcome = new AdditionalIncomeOffset__e(
      OffsetIncomeData__c = JSON.serialize(result)
    );
    List<AdditionalIncomeOffset__e> actualOutcome = (List<AdditionalIncomeOffset__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      new List<AdditionalIncomeOffset__e>{ expectedOutcome },
      actualOutcome,
      'Published AdditionalIncomeOffset__e does not match expected AdditionalIncomeOffset__e'
    );
  }

  @isTest
  public static void updateAdditionalIncomeTest() {
    cve__PaymentSpecification__c ps = queryPaymentSpec();
    cve__Claim__c disability = [
      SELECT Id, cvint__AbsenceClaim__c
      FROM cve__Claim__c
    ];
    cvab__Claim__c absence = [SELECT id FROM cvab__Claim__c];

    TriggerHandler.bypass('AdditionalIncomeTriggerHandler');
    AdditionalIncome__c income = new AdditionalIncome__c(
      Name = 'test',
      Amount__c = 2000.00,
      EndDate__c = Date.newInstance(2024, 1, 1),
      IncomeType__c = 'PTO',
      PaymentSpecification__c = ps.id,
      Period__c = 'Yearly',
      StartDate__c = Date.newInstance(2024, 1, 1),
      PFMLClaim__c = null,
      STDClaim__c = null
    );
    insert income;
    TriggerHandler.clearAllBypasses();

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    Test.startTest();

    AdditionalIncomeTriggerHandler testHandler = new AdditionalIncomeTriggerHandler(
      AdditionalIncomeTriggerHelper.getHelperInstance(),
      null,
      new List<AdditionalIncome__c>{ income },
      eventPublisherDouble
    );
    testHandler.afterUpdate();

    Test.stopTest();

    OffsetEvent result = new OffsetEvent(
      queryPaymentSpec(),
      disability,
      absence,
      getRelatedAdditionalIncomes(ps.id)
    );
    AdditionalIncomeOffset__e expectedOutcome = new AdditionalIncomeOffset__e(
      OffsetIncomeData__c = JSON.serialize(result)
    );
    List<AdditionalIncomeOffset__e> actualOutcome = (List<AdditionalIncomeOffset__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      new List<AdditionalIncomeOffset__e>{ expectedOutcome },
      actualOutcome,
      'Published AdditionalIncomeOffset__e does not match expected AdditionalIncomeOffset__e'
    );
  }

  // WICKED FRAGILE - TESTS DEPEND ON SAME ORDER OF QUERIED FIELDS AS HANDLER IN ORDER TO ASSERT TRUE
  public static List<AdditionalIncome__c> getRelatedAdditionalIncomes(
    Id paymentSpecId
  ) {
    return [
      SELECT
        PaymentSpecification__c,
        Id,
        Name,
        Amount__c,
        EndDate__c,
        IncomeType__c,
        Period__c,
        StartDate__c,
        PFMLClaim__c,
        STDClaim__c
      FROM AdditionalIncome__c
      WHERE PaymentSpecification__c = :paymentSpecId
    ];
  }

  // WICKED FRAGILE - TESTS DEPEND ON SAME ORDER OF QUERIED FIELDS AS HANDLER IN ORDER TO ASSERT TRUE
  static cve__PaymentSpecification__c queryPaymentSpec() {
    return [
      SELECT
        Id,
        cvint__AbsenceClaim__c,
        cve__Claim__c,
        cve__Claim__r.cvint__AbsenceClaim__c,
        (
          SELECT
            Id,
            Name,
            Amount__c,
            EndDate__c,
            IncomeType__c,
            PaymentSpecification__c,
            Period__c,
            StartDate__c,
            PFMLClaim__c,
            STDClaim__c
          FROM AdditionalIncomes__r
        )
      FROM cve__PaymentSpecification__c
      LIMIT 1
    ];
  }
}