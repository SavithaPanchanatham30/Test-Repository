@IsTest
class PaymentTriggerTest {
  static Contact con;
  static cvab__Claim__c cvabClaim;
  static cve__Claim__c cveClaim;
  static cve__PaymentSpecification__c cvabPaymentSpec;
  static cve__PaymentSpecification__c cvePaymentSpec;

  @TestSetup
  static void makeData() {
    SObject masterGroup = new TestAccountBuilder().buildAndInsert();
    SObject customGroup = new TestGroupBuilder()
      .withMasterGroupId(masterGroup.Id)
      .buildAndInsert();
    SObject con = new TestContactBuilder()
      .withAccountId(masterGroup.Id)
      .withGroupId(customGroup.Id)
      .buildAndInsert();

    cvab__Claim__c cvabClaim = new cvab__Claim__c(cvab__Employee__c = con.Id);
    insert cvabClaim;

    cve__Claim__c cveClaim = new cve__Claim__c(
      cve__ClaimantInsured__c = con.Id
    );
    insert cveClaim;

    cve__PaymentSpecification__c cvabPaymentSpec = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvabClaim.Id,
      RecordTypeId = getRecordTypeId('cve__PaymentSpecification__c', 'Generic')
    );
    cve__PaymentSpecification__c cvePaymentSpec = new cve__PaymentSpecification__c(
      cve__Claim__c = cveClaim.Id,
      RecordTypeId = getRecordTypeId(
        'cve__PaymentSpecification__c',
        'Short Term Disability'
      )
    );
    insert new List<cve__PaymentSpecification__c>{
      cvabPaymentSpec,
      cvePaymentSpec
    };
  }

  @isTest
  static void checkPayableAndIssueDateOnInsert() {
    cvab__Claim__c cvab = new cvab__Claim__c();
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    insert cvab;
    TriggerHandler.clearAllBypasses();

    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvab.id
    );
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    insert ps;
    TriggerHandler.clearAllBypasses();

    cve__Payment__c pay = new cve__Payment__c(
      cve__Start__c = Date.newInstance(2023, 1, 1),
      cve__Through__c = Date.newInstance(2023, 1, 31),
      cve__PaymentSpecification__c = ps.id
    );

    PaymentTriggerHandler handler = new PaymentTriggerHandler(
      PaymentTriggerHelper.getInstance(),
      null,
      new List<cve__Payment__c>{ pay },
      null,
      null
    );

    Test.startTest();
    handler.beforeInsert();
    Test.stopTest();

    Assert.areEqual(
      pay.cve__Through__c,
      pay.cve__Payable__c,
      'Payable date was not set correctly'
    );

    Assert.areEqual(
      pay.cve__Through__c,
      pay.cve__Issue__c,
      'Issue date was not set correctly'
    );
  }

  @isTest
  static void checkPayableAndIssueDateOnUpdate() {
    cvab__Claim__c cvab = new cvab__Claim__c();
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    insert cvab;
    TriggerHandler.clearAllBypasses();

    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvab.id
    );
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    insert ps;
    TriggerHandler.clearAllBypasses();

    TriggerHandler.bypass('PaymentTriggerHandler');
    cve__Payment__c pay = new cve__Payment__c(
      cve__Start__c = Date.newInstance(2023, 1, 1),
      cve__Through__c = Date.newInstance(2023, 1, 31),
      cve__PaymentSpecification__c = ps.id
    );
    insert pay;
    TriggerHandler.clearAllBypasses();

    cve__Payment__c newPay = [
      SELECT id, cve__Status__c, cve__Through__c, cve__Payable__c, cve__Issue__c
      FROM cve__Payment__c
      WHERE id = :pay.id
    ];
    newPay.cve__Through__c = Date.newInstance(2023, 2, 28);
    PaymentTriggerHandler handler = new PaymentTriggerHandler(
      PaymentTriggerHelper.getInstance(),
      new List<cve__Payment__c>{ pay },
      new List<cve__Payment__c>{ newPay },
      new Map<Id, cve__Payment__c>{ pay.id => pay },
      new Map<Id, cve__Payment__c>{ newPay.id => newPay }
    );

    Test.startTest();
    handler.beforeUpdate();
    Test.stopTest();

    Assert.areEqual(
      newPay.cve__Through__c,
      newPay.cve__Payable__c,
      'Payable date was not set correctly'
    );

    Assert.areEqual(
      newPay.cve__Through__c,
      newPay.cve__Issue__c,
      'Issue date was not set correctly'
    );
  }

  @IsTest
  static void insert_payment_for_std_populates_claimant_lookup() {
    populateClassVariables();

    cve__Payment__c cvePayment = new cve__Payment__c(
      cve__PaymentSpecification__c = cvePaymentSpec.Id
    );

    PaymentTriggerHandler handler = new PaymentTriggerHandler(
      PaymentTriggerHelper.getInstance(),
      null,
      new List<cve__Payment__c>{ cvePayment },
      null,
      null
    );

    Test.startTest();
    handler.beforeInsert();
    Test.stopTest();

    List<cve__Payment__c> payments = handler.payments;
    cve__Payment__c actualPayment = payments[0];

    Assert.areEqual(
      con.Id,
      actualPayment.Claimant__c,
      'Payment not linked to expected Contact'
    );
  }

  @IsTest
  static void insert_payment_for_cvab_populates_claimant_lookup() {
    populateClassVariables();

    cve__Payment__c cvabPayment = new cve__Payment__c(
      cve__PaymentSpecification__c = cvabPaymentSpec.Id
    );

    Test.startTest();
    insert cvabPayment;
    Test.stopTest();

    cve__Payment__c actualPayment = [
      SELECT Claimant__c
      FROM cve__Payment__c
      WHERE Id = :cvabPayment.Id
    ];

    Assert.areEqual(
      con.Id,
      actualPayment.Claimant__c,
      'Payment not linked to expected Contact'
    );
  }

  static void populateClassVariables() {
    con = queryContact();
    cvabClaim = queryCvabClaim();
    cveClaim = queryCveClaim();
    cvabPaymentSpec = queryCvabPaymentSpec();
    cvePaymentSpec = queryCvePaymentSpec();
  }

  static Id getRecordTypeId(String sObjectName, String recordTypeName) {
    System.debug(sObjectName + '.' + recordTypeName);
    return [
      SELECT Id
      FROM RecordType
      WHERE SobjectType = :sObjectName AND Name = :recordTypeName
      LIMIT 1
    ]
    .Id;
  }

  static Contact queryContact() {
    return [SELECT Id, LastName FROM Contact LIMIT 1];
  }

  static cvab__Claim__c queryCvabClaim() {
    return [
      SELECT Id, cvab__Employee__c
      FROM cvab__Claim__c
      LIMIT 1
    ];
  }

  static cve__Claim__c queryCveClaim() {
    return [
      SELECT Id, cve__ClaimantInsured__c
      FROM cve__Claim__c
      LIMIT 1
    ];
  }

  static cve__PaymentSpecification__c queryCvabPaymentSpec() {
    return [
      SELECT Id, cvint__AbsenceClaim__c, RecordType.Name
      FROM cve__PaymentSpecification__c
      WHERE
        RecordTypeId = :getRecordTypeId(
          'cve__PaymentSpecification__c',
          'Generic'
        )
      LIMIT 1
    ];
  }

  static cve__PaymentSpecification__c queryCvePaymentSpec() {
    return [
      SELECT Id, RecordType.Name, cve__Claim__c
      FROM cve__PaymentSpecification__c
      WHERE
        RecordTypeId = :getRecordTypeId(
          'cve__PaymentSpecification__c',
          'Short Term Disability'
        )
      LIMIT 1
    ];
  }
}