@IsTest
public with sharing class AdjustmentTriggerTest {
  @TestSetup
  static void makeData() {
    User u = [
      SELECT Id, Name, Email
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];

    System.runAs(u) {
      User testUser = (User) new TestUserBuilder()
        .withLastName('AdjustmentTriggerTestUser')
        .buildAndInsert();

      assignPermissionSetsToUser(
        testUser,
        new List<String>{ 'FICAandMedicareTaxability_WRITE' }
      );
      cve__Rates__c ficaRate = new cve__Rates__c();
      ficaRate.Name = 'FICARate';
      ficaRate.cve__Type__c = 'FICA Tax';
      ficaRate.cve__Effective__c = Date.newInstance(2000, 1, 1);
      ficaRate.cve__Percentage__c = 6.2;
      insert ficaRate;

      cve__Rates__c medicareRate = new cve__Rates__c();
      medicareRate.Name = 'Medicare';
      medicareRate.cve__Type__c = 'Medicare Tax';
      medicareRate.cve__Effective__c = Date.newInstance(2000, 1, 1);
      medicareRate.cve__Percentage__c = 1.45;
      insert medicareRate;
    }

    Account acc = (Account) new TestAccountBuilder()
      .withAccountName('TestAccount')
      .buildAndInsert();

    SObject customGroup = new TestGroupBuilder()
      .withMasterGroupId(acc.Id)
      .withName('testGroup')
      .buildAndInsert();

    Contact con = (Contact) new TestContactBuilder()
      .withAccountId(acc.Id)
      .withGroupId(customGroup.Id)
      .buildAndInsert();

    cve__Class__c cveClass = new cve__Class__c(cve__Account__c = acc.Id);
    insert cveClass;

    cve__Claim__c claim = new cve__Claim__c(cve__ClaimantInsured__c = con.Id);
    insert claim;

    cve__Product__c prod = new cve__Product__c(cve__Account__c = acc.Id);
    insert prod;

    cve__Benefit__c benefit = new cve__Benefit__c(
      cve__BenefitFlatAmountValue__c = 1000,
      cve__BenefitFlatAmountPeriod__c = 'Week',
      cve__Product__c = prod.Id
    );
    insert benefit;

    cve__BenefitClaimed__c bc = new cve__BenefitClaimed__c(
      cve__Claim__c = claim.Id,
      cve__Benefit__c = benefit.Id
    );
    insert bc;

    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    insert new cve__PaymentSpecification__c(
      cve__DisabledAutomatedAdjustmentTypes__c = '',
      cve__BenefitClaimed__c = bc.Id,
      cve__Claim__c = claim.Id,
      Claimant__c = con.Id,
      RecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE
          SObjectType = 'cve__PaymentSpecification__c'
          AND DeveloperName = 'ShortTermDisability'
        LIMIT 1
      ]
      .Id
    );
    TriggerHandler.clearBypass('PaymentSpecificationTriggerHandler');

    cvab__Claim__c cvabClaim = new cvab__Claim__c(cvab__Employee__c = con.Id);
    insert cvabClaim;

    insert new cve__PaymentSpecification__c(
      cve__DisabledAutomatedAdjustmentTypes__c = '',
      cvint__AbsenceClaim__c = cvabClaim.Id,
      Claimant__c = con.Id,
      RecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE
          SObjectType = 'cve__PaymentSpecification__c'
          AND DeveloperName = 'Generic'
        LIMIT 1
      ]
      .Id
    );
  }

  @IsTest
  static void contact_overrides_preferred_to_class_and_account_for_cvab_on_update() {
    System.runAs(getTestUser()) {
      Account acc = getAccount();
      cve__Class__c cveClass = getClass();
      Contact con = getContact();
      new Taxability()
        .withSObj(acc)
        .withAbsenceFica(100)
        .withDisabilityFica(null)
        .withAbsenceMedicare(100)
        .withDisabilityMedicare(null)
        .setTaxabilities();
      new Taxability()
        .withSObj(cveClass)
        .withAbsenceFica(100)
        .withDisabilityFica(null)
        .withAbsenceMedicare(100)
        .withDisabilityMedicare(null)
        .setTaxabilities();
      new Taxability()
        .withSObj(con)
        .withAbsenceFica(20)
        .withDisabilityFica(null)
        .withAbsenceMedicare(20)
        .withDisabilityMedicare(null)
        .setTaxabilities();

      Decimal expectedFicaPercentage = 50;
      Decimal expectedMedicarePercentage = 50;

      List<Decimal> taxabilities = runAbsenceUpdateTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }

  }

  @IsTest
  static void contact_overrides_preferred_to_class_and_account_for_cvab() {
    System.runAs(getTestUser()) {
      Account acc = getAccount();
      cve__Class__c cveClass = getClass();
      Contact con = getContact();
      new Taxability()
        .withSObj(acc)
        .withAbsenceFica(100)
        .withDisabilityFica(null)
        .withAbsenceMedicare(100)
        .withDisabilityMedicare(null)
        .setTaxabilities();
      new Taxability()
        .withSObj(cveClass)
        .withAbsenceFica(100)
        .withDisabilityFica(null)
        .withAbsenceMedicare(100)
        .withDisabilityMedicare(null)
        .setTaxabilities();
      new Taxability()
        .withSObj(con)
        .withAbsenceFica(10)
        .withDisabilityFica(null)
        .withAbsenceMedicare(10)
        .withDisabilityMedicare(null)
        .setTaxabilities();

      Decimal expectedFicaPercentage = .62;
      Decimal expectedMedicarePercentage = .145;

      List<Decimal> taxabilities = runAbsenceTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }

  }

  @IsTest
  static void contact_overrides_preferred_to_class_and_account_for_cve() {
    System.runAs(getTestUser()) {
      Account acc = getAccount();
      cve__Class__c cveClass = getClass();
      Contact con = getContact();
      new Taxability()
        .withSObj(acc)
        .withAbsenceFica(null)
        .withDisabilityFica(100)
        .withAbsenceMedicare(null)
        .withDisabilityMedicare(100)
        .setTaxabilities();
      new Taxability()
        .withSObj(cveClass)
        .withAbsenceFica(null)
        .withDisabilityFica(100)
        .withAbsenceMedicare(null)
        .withDisabilityMedicare(100)
        .setTaxabilities();
      new Taxability()
        .withSObj(con)
        .withAbsenceFica(null)
        .withDisabilityFica(10)
        .withAbsenceMedicare(null)
        .withDisabilityMedicare(10)
        .setTaxabilities();

      Decimal expectedFicaPercentage = .62;
      Decimal expectedMedicarePercentage = .145;

      List<Decimal> taxabilities = runDisabilityTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void class_overrides_preferred_to_account_for_cvab() {
    System.runAs(getTestUser()) {
      Contact con = getContact();
      Account acc = getAccount();
      cve__Class__c cveClass = getClass();
      cve__ClassRelationship__c cr = new cve__ClassRelationship__c(
        cve__Contact__c = con.Id,
        cve__Class__c = cveClass.Id
      );
      insert cr;
      new Taxability()
        .withSObj(acc)
        .withAbsenceFica(100)
        .withDisabilityFica(null)
        .withAbsenceMedicare(100)
        .withDisabilityMedicare(null)
        .setTaxabilities();
      new Taxability()
        .withSObj(cveClass)
        .withAbsenceFica(10)
        .withDisabilityFica(null)
        .withAbsenceMedicare(10)
        .withDisabilityMedicare(null)
        .setTaxabilities();

      Decimal expectedFicaPercentage = .62;
      Decimal expectedMedicarePercentage = .145;

      List<Decimal> taxabilities = runAbsenceTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void class_overrides_preferred_to_account_for_cve() {
    System.runAs(getTestUser()) {
      Contact con = getContact();
      Account acc = getAccount();
      cve__Class__c cveClass = getClass();
      cve__ClassRelationship__c cr = new cve__ClassRelationship__c(
        cve__Contact__c = con.Id,
        cve__Class__c = cveClass.Id
      );
      insert cr;
      new Taxability()
        .withSObj(acc)
        .withAbsenceFica(null)
        .withDisabilityFica(100)
        .withAbsenceMedicare(null)
        .withDisabilityMedicare(100)
        .setTaxabilities();
      new Taxability()
        .withSObj(cveClass)
        .withAbsenceFica(null)
        .withDisabilityFica(10)
        .withAbsenceMedicare(null)
        .withDisabilityMedicare(10)
        .setTaxabilities();

      Decimal expectedFicaPercentage = .62;
      Decimal expectedMedicarePercentage = .145;

      List<Decimal> taxabilities = runDisabilityTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void account_overrides_used_when_nothing_else_for_cvab() {
    System.runAs(getTestUser()) {
      Account acc = getAccount();
      new Taxability()
        .withSObj(acc)
        .withAbsenceFica(10)
        .withDisabilityFica(null)
        .withAbsenceMedicare(10)
        .withDisabilityMedicare(null)
        .setTaxabilities();

      Decimal expectedFicaPercentage = .62;
      Decimal expectedMedicarePercentage = .145;

      List<Decimal> taxabilities = runAbsenceTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void override_logic_bypassed_when_adjustment_not_automated() {
    System.runAs(getTestUser()) {
      Account acc = getAccount();
      new Taxability()
        .withSObj(acc)
        .withAbsenceFica(10)
        .withDisabilityFica(null)
        .withAbsenceMedicare(10)
        .withDisabilityMedicare(null)
        .setTaxabilities();

      Decimal expectedFicaPercentage = 6.2;
      Decimal expectedMedicarePercentage = 1.45;

      List<Decimal> taxabilities = runAbsenceTest(false);
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }
  @IsTest
  static void account_overrides_used_when_nothing_else_for_cve() {
    System.runAs(getTestUser()) {
      Account acc = getAccount();
      Contact con = getContact();
      new Taxability()
        .withSObj(acc)
        .withAbsenceFica(null)
        .withDisabilityFica(10)
        .withAbsenceMedicare(null)
        .withDisabilityMedicare(10)
        .setTaxabilities();
      con = [
        SELECT Account.Id, AccountId, Account.FICATaxabilityDisability__c
        FROM Contact
        WHERE Id = :con.Id
        LIMIT 1
      ];

      Decimal expectedFicaPercentage = .62;
      Decimal expectedMedicarePercentage = .145;

      List<Decimal> taxabilities = runDisabilityTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void zero_override_means_zero_taxability_for_cvab() {
    System.runAs(getTestUser()) {
      Contact con = getContact();
      new Taxability()
        .withSObj(con)
        .withAbsenceFica(0)
        .withDisabilityFica(null)
        .withAbsenceMedicare(0)
        .withDisabilityMedicare(null)
        .setTaxabilities();

      Decimal expectedFicaPercentage = 0;
      Decimal expectedMedicarePercentage = 0;

      List<Decimal> taxabilities = runAbsenceTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void zero_override_means_zero_taxability_for_cve() {
    System.runAs(getTestUser()) {
      Contact con = getContact();
      new Taxability()
        .withSObj(con)
        .withAbsenceFica(null)
        .withDisabilityFica(0)
        .withAbsenceMedicare(null)
        .withDisabilityMedicare(0)
        .setTaxabilities();

      Decimal expectedFicaPercentage = 0;
      Decimal expectedMedicarePercentage = 0;

      List<Decimal> taxabilities = runDisabilityTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void no_overrides_retains_full_taxability_for_cvab() {
    System.runAs(getTestUser()) {
      Decimal expectedFicaPercentage = 6.2;
      Decimal expectedMedicarePercentage = 1.45;

      List<Decimal> taxabilities = runAbsenceTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void no_overrides_retains_full_taxability_for_cve() {
    System.runAs(getTestUser()) {
      Decimal expectedFicaPercentage = 6.2;
      Decimal expectedMedicarePercentage = 1.45;

      List<Decimal> taxabilities = runDisabilityTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void lowest_taxability_selected_from_possible_classes() {
    System.runAs(getTestUser()) {
      Contact con = getContact();
      Account acc = getAccount();
      cve__Class__c class1 = getClass();
      cve__Class__c class2 = new cve__Class__c(cve__Account__c = acc.Id);
      insert class2;
      new Taxability()
        .withSObj(class1)
        .withAbsenceFica(10)
        .withDisabilityFica(10)
        .withAbsenceMedicare(10)
        .withDisabilityMedicare(10)
        .setTaxabilities();
      new Taxability()
        .withSObj(class2)
        .withAbsenceFica(20)
        .withDisabilityFica(20)
        .withAbsenceMedicare(20)
        .withDisabilityMedicare(20)
        .setTaxabilities();

      cve__ClassRelationship__c cr1 = new cve__ClassRelationship__c(
        cve__Contact__c = con.Id,
        cve__Class__c = class1.Id
      );
      cve__ClassRelationship__c cr2 = new cve__ClassRelationship__c(
        cve__Contact__c = con.Id,
        cve__Class__c = class2.Id
      );
      insert new List<cve__ClassRelationship__c>{ cr1, cr2 };

      Decimal expectedFicaPercentage = .62;
      Decimal expectedMedicarePercentage = .145;

      List<Decimal> taxabilities = runDisabilityTest();
      Decimal actualFicaPercentage = taxabilities[0];
      Decimal actualMedicarePercentage = taxabilities[1];

      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  @IsTest
  static void trigger_runs_without_error() {
    System.runAs(getTestUser()) {
      Contact con = getContact();
      con.FicaTaxabilityDisability__c = 10;
      con.MedicareTaxabilityDisability__c = 10;
      update con;

      Boolean errorEncountered = false;

      cve__PaymentSpecification__c paymentSpecification = getPaymentSpecification();
      List<cve__Adjustment__c> adjustments = generateAdjustments(
        paymentSpecification
      );

      Decimal expectedFicaPercentage = .62;
      Decimal expectedMedicarePercentage = .145;

      Test.startTest();

      try {
        insert adjustments;
      } catch (Exception e) {
        errorEncountered = true;
      }

      Test.stopTest();

      Decimal actualFicaPercentage = [
        SELECT cve__Percentage__c
        FROM cve__Adjustment__c
        WHERE cve__Type__c = 'FICA Tax'
        LIMIT 1
      ]
      .cve__Percentage__c;
      Decimal actualMedicarePercentage = [
        SELECT cve__Percentage__c
        FROM cve__Adjustment__c
        WHERE cve__Type__c = 'Medicare Tax'
        LIMIT 1
      ]
      .cve__Percentage__c;

      Assert.isFalse(
        errorEncountered,
        'Triggers failed to execute without encountering an error'
      );
      Assert.areEqual(
        expectedFicaPercentage,
        actualFicaPercentage,
        'Unexpected FICA Percentage'
      );
      Assert.areEqual(
        expectedMedicarePercentage,
        actualMedicarePercentage,
        'Unexpected Medicare Percentage'
      );
    }
  }

  static List<Decimal> runAbsenceTest() {
    return runAbsenceTest(true);
  }

  static List<Decimal> runAbsenceTest(Boolean automated) {
    Test.startTest();
    cve__PaymentSpecification__c paymentSpecification = getAbsencePaymentSpecification();
    paymentSpecification.RecordType = [
      SELECT Id
      FROM RecordType
      WHERE
        SObjectType = 'cve__PaymentSpecification__c'
        AND DeveloperName = 'Generic'
      LIMIT 1
    ];
    List<cve__Adjustment__c> adjustments = generateAdjustments(
      paymentSpecification,
      automated
    );

    AdjustmentTriggerHandler handler = new AdjustmentTriggerHandler(
      AdjustmentTriggerHelper.getInstance(),
      new AdjustmentTriggerHandler.ContextVariables().withNewList(adjustments)
    );

    handler.beforeInsert();
    TriggerHandler.bypass('AdjustmentTriggerHandler');
    insert adjustments;
    TriggerHandler.clearBypass('AdjustmentTriggerHandler');

    Decimal actualFicaPercentage = [
      SELECT cve__Percentage__c
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'FICA Tax'
      LIMIT 1
    ]
    .cve__Percentage__c;
    Decimal actualMedicarePercentage = [
      SELECT cve__Percentage__c
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'Medicare Tax'
      LIMIT 1
    ]
    .cve__Percentage__c;

    Test.stopTest();

    return new List<Decimal>{ actualFicaPercentage, actualMedicarePercentage };
  }

  static List<Decimal> runDisabilityTest() {
    Test.startTest();
    cve__PaymentSpecification__c paymentSpecification = getPaymentSpecification();
    List<cve__Adjustment__c> adjustments = generateAdjustments(
      paymentSpecification
    );

    AdjustmentTriggerHandler handler = new AdjustmentTriggerHandler(
      AdjustmentTriggerHelper.getInstance(),
      new AdjustmentTriggerHandler.ContextVariables().withNewList(adjustments)
    );

    handler.beforeInsert();
    TriggerHandler.bypass('AdjustmentTriggerHandler');
    insert adjustments;
    TriggerHandler.clearBypass('AdjustmentTriggerHandler');

    Decimal actualFicaPercentage = [
      SELECT cve__Percentage__c
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'FICA Tax'
      LIMIT 1
    ]
    .cve__Percentage__c;
    Decimal actualMedicarePercentage = [
      SELECT cve__Percentage__c
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'Medicare Tax'
      LIMIT 1
    ]
    .cve__Percentage__c;

    Test.stopTest();

    return new List<Decimal>{ actualFicaPercentage, actualMedicarePercentage };
  }

  static String runAfterTest() {
    cve__PaymentSpecification__c paymentSpecification = getPaymentSpecification();

    List<cve__Adjustment__c> adjustments = generateAdjustments(
      paymentSpecification
    );

    TriggerHandler.bypass('AdjustmentTriggerHandler');
    insert adjustments;
    TriggerHandler.clearBypass('AdjustmentTriggerHandler');

    Map<Id, cve__Adjustment__c> adjustmentsMap = new Map<Id, cve__Adjustment__c>();
    for (cve__Adjustment__c adjustment : adjustments) {
      adjustmentsMap.put(adjustment.Id, adjustment);
    }

    AdjustmentTriggerHandler handler = new AdjustmentTriggerHandler(
      AdjustmentTriggerHelper.getInstance(),
      new AdjustmentTriggerHandler.ContextVariables()
        .withNewList(adjustments)
        .withNewMap(adjustmentsMap)
    );

    Test.startTest();
    handler.afterInsert();
    Test.stopTest();

    String disabledTypes = [
      SELECT cve__DisabledAutomatedAdjustmentTypes__c
      FROM cve__PaymentSpecification__c
      WHERE Id = :paymentSpecification.Id
      LIMIT 1
    ]
    .cve__DisabledAutomatedAdjustmentTypes__c;

    return disabledTypes;
  }

  static List<Decimal> runAbsenceUpdateTest() {
    Test.startTest();
    cve__PaymentSpecification__c paymentSpecification = getAbsencePaymentSpecification();
    paymentSpecification.RecordType = [
      SELECT Id
      FROM RecordType
      WHERE
        SObjectType = 'cve__PaymentSpecification__c'
        AND DeveloperName = 'Generic'
      LIMIT 1
    ];
    List<cve__Adjustment__c> adjustments = generateAdjustments(
      paymentSpecification
    );

    AdjustmentTriggerHandler handler = new AdjustmentTriggerHandler(
      AdjustmentTriggerHelper.getInstance(),
      new AdjustmentTriggerHandler.ContextVariables().withNewList(adjustments)
    );

    handler.beforeInsert();
    TriggerHandler.bypass('AdjustmentTriggerHandler');
    insert adjustments;
    TriggerHandler.clearBypass('AdjustmentTriggerHandler');

    new Taxability()
      .withSObj(getContact())
      .withAbsenceFica(50)
      .withAbsenceMedicare(50)
      .setTaxabilities();

    for (cve__Adjustment__c adjustment : adjustments) {
      adjustment.cve__Percentage__c = 100;
    }

    handler = new AdjustmentTriggerHandler(
      AdjustmentTriggerHelper.getInstance(),
      new AdjustmentTriggerHandler.ContextVariables().withNewList(adjustments)
    );

    handler.beforeUpdate();

    Test.stopTest();

    Decimal actualFicaPercentage;
    Decimal actualMedicarePercentage;

    for (cve__Adjustment__c adjustment : adjustments) {
      if (adjustment.cve__Type__c == 'FICA Tax') {
        actualFicaPercentage = adjustment.cve__Percentage__c;
      }

      if (adjustment.cve__Type__c == 'Medicare Tax') {
        actualMedicarePercentage = adjustment.cve__Percentage__c;
      }
    }

    return new List<Decimal>{ actualFicaPercentage, actualMedicarePercentage };
  }

  static Account getAccount() {
    return [
      SELECT
        Id,
        FICATaxabilityAbsence__c,
        FICATaxabilityDisability__c,
        MedicareTaxabilityAbsence__c,
        MedicareTaxabilityDisability__c
      FROM Account
      LIMIT 1
    ];
  }

  static cve__Class__c getClass() {
    return [
      SELECT
        Id,
        FICATaxabilityAbsence__c,
        FICATaxabilityDisability__c,
        MedicareTaxabilityAbsence__c,
        MedicareTaxabilityDisability__c
      FROM cve__Class__c
      LIMIT 1
    ];
  }

  static Contact getContact() {
    return [
      SELECT
        Id,
        FICATaxabilityAbsence__c,
        FICATaxabilityDisability__c,
        MedicareTaxabilityAbsence__c,
        MedicareTaxabilityDisability__c
      FROM Contact
      LIMIT 1
    ];
  }

  static cve__PaymentSpecification__c getAbsencePaymentSpecification() {
    return [
      SELECT
        Id,
        cve__DisabledAutomatedAdjustmentTypes__c,
        cvint__AbsenceClaim__c
      FROM cve__PaymentSpecification__c
      WHERE RecordType.DeveloperName = 'Generic'
      LIMIT 1
    ];
  }

  static cve__PaymentSpecification__c getPaymentSpecification() {
    return [
      SELECT Id, cve__DisabledAutomatedAdjustmentTypes__c, cve__Claim__c
      FROM cve__PaymentSpecification__c
      WHERE cvint__AbsenceClaim__c = NULL
      LIMIT 1
    ];
  }

  static User getTestUser() {
    return [
      SELECT Id
      FROM User
      WHERE LastName = 'AdjustmentTriggerTestUser'
      LIMIT 1
    ];
  }

  static List<cve__Adjustment__c> generateAdjustments(
    cve__PaymentSpecification__c paymentSpecification
  ) {
    return generateAdjustments(paymentSpecification, true);
  }

  static List<cve__Adjustment__c> generateAdjustments(
    cve__PaymentSpecification__c paymentSpecification,
    Boolean automated
  ) {
    Id psId = paymentSpecification.Id;

    cve__Adjustment__c ficaAdjustment = new cve__Adjustment__c(
      cve__PaymentSpecification__c = psId,
      cve__Percentage__c = 6.2,
      cve__Type__c = 'FICA Tax',
      cve__Automated__c = automated
    );
    cve__Adjustment__c medicareAdjustment = new cve__Adjustment__c(
      cve__PaymentSpecification__c = psId,
      cve__Percentage__c = 1.45,
      cve__Type__c = 'Medicare Tax',
      cve__Automated__c = automated
    );

    List<cve__Adjustment__c> adjustments = new List<cve__Adjustment__c>{
      ficaAdjustment,
      medicareAdjustment
    };

    return adjustments;
  }

  static void assignPermissionSetsToUser(
    User u,
    List<String> permissionSetNames
  ) {
    List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
    List<PermissionSet> permSets = [
      SELECT Id
      FROM PermissionSet
      WHERE Name IN :permissionSetNames
    ];

    List<PermissionSetAssignment> preexistingPSAs = [
      SELECT PermissionSetId
      FROM PermissionSetAssignment
      WHERE AssigneeId = :u.Id AND PermissionSetId IN :permsets
    ];

    List<String> psaIdentifiers = new List<String>();
    for (PermissionSetAssignment psa : preexistingPSAs) {
      psaIdentifiers.add(psa.PermissionSetId);
    }

    for (PermissionSet permset : permsets) {
      if (psaIdentifiers.contains(permset.Id)) {
        continue;
      }

      psas.add(
        new PermissionSetAssignment(
          AssigneeId = u.Id,
          PermissionSetId = permset.Id
        )
      );
    }

    insert psas;
  }

  public class Taxability {
    SObject sobj;
    Decimal absenceFica;
    Decimal disabilityFica;
    Decimal absenceMedicare;
    Decimal disabilityMedicare;

    public Taxability withSObj(SObject sobj) {
      this.sobj = sobj;
      return this;
    }

    public Taxability withAbsenceFica(Decimal absenceFica) {
      this.absenceFica = absenceFica;
      return this;
    }

    public Taxability withDisabilityFica(Decimal disabilityFica) {
      this.disabilityFica = disabilityFica;
      return this;
    }

    public Taxability withAbsenceMedicare(Decimal absenceMedicare) {
      this.absenceMedicare = absenceMedicare;
      return this;
    }

    public Taxability withDisabilityMedicare(Decimal disabilityMedicare) {
      this.disabilityMedicare = disabilityMedicare;
      return this;
    }

    void setTaxabilities() {
      sobj.put('FICATaxabilityAbsence__c', absenceFica);
      sobj.put('FICATaxabilityDisability__c', disabilityFica);
      sobj.put('MedicareTaxabilityAbsence__c', absenceMedicare);
      sobj.put('MedicareTaxabilityDisability__c', disabilityMedicare);
      update sobj;
    }
  }
}