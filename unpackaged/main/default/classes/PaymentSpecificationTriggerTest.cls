@isTest
public class PaymentSpecificationTriggerTest {
  @TestSetup
  public static void makeData() {
    User u = [
      SELECT id, name, email
      FROM User
      WHERE id = :UserInfo.getUserId()
    ];
    System.runAs(u) {
      PermissionSet ps = [
        SELECT Id
        FROM PermissionSet
        WHERE Name = 'OverpaymentFlag_WRITE'
      ];

      List<PermissionSetAssignment> psas = [
        SELECT Id
        FROM PermissionSetAssignment
        WHERE PermissionSetId = :ps.Id AND AssigneeId = :u.Id
      ];

      if (psas.size() == 0) {
        insert new PermissionSetAssignment(
          AssigneeId = u.Id,
          PermissionSetId = ps.Id
        );
      }
    }

    SObject acc = new TestAccountBuilder().buildAndInsert();
    SObject grp = new TestGroupBuilder()
      .withMasterGroupId(acc.Id)
      .buildAndInsert();
    SObject con = new TestContactBuilder()
      .withAccountId(acc.Id)
      .withGroupId(grp.Id)
      .buildAndInsert();

    TriggerHandler.bypass('CvabClaimTriggerHandler');
    TriggerHandler.bypass('CveClaimTriggerHandler');
    cvab__Claim__c c1 = new cvab__Claim__c(cvab__Employee__c = con.Id);
    insert c1;

    cve__Claim__c c2 = new cve__Claim__c(cve__ClaimantInsured__c = con.Id);
    insert c2;
    TriggerHandler.clearAllBypasses();
  }

  @isTest
  public static void checkAfterUpdate() {
    cvab__Claim__c claim = getCvabClaim();
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = claim.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert ps;
    ps.cve__OverpaymentNet__c = 0.00;
    update ps;
    TriggerHandler.clearAllBypasses();

    List<cve__PaymentSpecification__c> newPsList = new List<cve__PaymentSpecification__c>{
      ps
    };
    Map<Id, cve__PaymentSpecification__c> newPsMap = new Map<Id, cve__PaymentSpecification__c>(
      newPsList
    );

    PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
      PaymentSpecificationTriggerHelper.getInstance(),
      null,
      newPsList,
      null,
      newPsMap,
      null
    );

    Test.startTest();
    handler.afterUpdate();
    Test.stopTest();

    claim = getCvabClaim();
    Assert.areEqual(
      0.00,
      claim.TotalOverpayments__c,
      'Aggregate was not calculated'
    );
  }

  @isTest
  public static void checkAfterDelete() {
    cvab__Claim__c claim = getCvabClaim();
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = claim.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert ps;
    delete ps;
    TriggerHandler.clearAllBypasses();

    List<cve__PaymentSpecification__c> newPsList = new List<cve__PaymentSpecification__c>{
      ps
    };
    Map<Id, cve__PaymentSpecification__c> newPsMap = new Map<Id, cve__PaymentSpecification__c>(
      newPsList
    );

    PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
      PaymentSpecificationTriggerHelper.getInstance(),
      null,
      newPsList,
      null,
      newPsMap,
      null
    );

    Test.startTest();
    handler.afterDelete();
    Test.stopTest();

    claim = getCvabClaim();
    Assert.areEqual(
      0.00,
      claim.TotalOverpayments__c,
      'Aggregate was not calculated'
    );
  }

  @isTest
  public static void checkAfterUndelete() {
    cvab__Claim__c claim = getCvabClaim();
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = claim.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert ps;
    delete ps;
    undelete ps;
    TriggerHandler.clearAllBypasses();

    List<cve__PaymentSpecification__c> newPsList = new List<cve__PaymentSpecification__c>{
      ps
    };
    Map<Id, cve__PaymentSpecification__c> newPsMap = new Map<Id, cve__PaymentSpecification__c>(
      newPsList
    );

    PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
      PaymentSpecificationTriggerHelper.getInstance(),
      null,
      newPsList,
      null,
      newPsMap,
      null
    );

    Test.startTest();
    handler.afterUndelete();
    Test.stopTest();

    claim = getCvabClaim();
    Assert.areEqual(
      2000.00,
      claim.TotalOverpayments__c,
      'Aggregate was not calculated'
    );
  }

  @isTest
  public static void checkAfterUpdateWithTwoPaymentSpec() {
    cvab__Claim__c claim = getCvabClaim();
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = claim.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert ps;
    cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = claim.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert ps2;
    ps.cve__OverpaymentNet__c = 0.00;
    update ps;
    TriggerHandler.clearAllBypasses();

    List<cve__PaymentSpecification__c> newPsList = new List<cve__PaymentSpecification__c>{
      ps
    };
    Map<Id, cve__PaymentSpecification__c> newPsMap = new Map<Id, cve__PaymentSpecification__c>(
      newPsList
    );

    PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
      PaymentSpecificationTriggerHelper.getInstance(),
      null,
      newPsList,
      null,
      newPsMap,
      null
    );

    Test.startTest();
    handler.afterUpdate();
    Test.stopTest();

    claim = getCvabClaim();
    Assert.areEqual(
      2000.00,
      claim.TotalOverpayments__c,
      'Aggregate was not calculated'
    );
  }

  @isTest
  public static void checkAfterDeleteWithTwoPaymentSpec() {
    cvab__Claim__c claim = getCvabClaim();

    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = claim.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert ps;
    cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = claim.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert ps2;
    delete ps;
    TriggerHandler.clearAllBypasses();

    List<cve__PaymentSpecification__c> newPsList = new List<cve__PaymentSpecification__c>{
      ps
    };
    Map<Id, cve__PaymentSpecification__c> newPsMap = new Map<Id, cve__PaymentSpecification__c>(
      newPsList
    );

    PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
      PaymentSpecificationTriggerHelper.getInstance(),
      null,
      newPsList,
      null,
      newPsMap,
      null
    );

    Test.startTest();
    handler.afterDelete();
    Test.stopTest();

    claim = getCvabClaim();
    Assert.areEqual(
      2000.00,
      claim.TotalOverpayments__c,
      'Aggregate was not calculated'
    );
  }

  @isTest
  public static void checkAfterUndeleteWithTwoPaymentSpec() {
    cvab__Claim__c claim = getCvabClaim();

    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = claim.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert ps;
    cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = claim.id,
      cve__OverpaymentNet__c = 2000.00
    );
    insert ps2;
    delete ps;
    undelete ps;
    TriggerHandler.clearAllBypasses();

    List<cve__PaymentSpecification__c> newPsList = new List<cve__PaymentSpecification__c>{
      ps
    };
    Map<Id, cve__PaymentSpecification__c> newPsMap = new Map<Id, cve__PaymentSpecification__c>(
      newPsList
    );

    PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
      PaymentSpecificationTriggerHelper.getInstance(),
      null,
      newPsList,
      null,
      newPsMap,
      null
    );

    Test.startTest();
    handler.afterUndelete();
    Test.stopTest();

    claim = getCvabClaim();
    Assert.areEqual(
      4000.00,
      claim.TotalOverpayments__c,
      'Aggregate was not calculated'
    );
  }

  @IsTest
  static void create_paymentspec_calls_populateClaimants() {
    Boolean verificationSucceeded = false;
    cve__Claim__c cveClaim = getCveClaim();

    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c();
    ps.cve__Claim__c = cveClaim.Id;

    List<cve__PaymentSpecification__c> newPsList = new List<cve__PaymentSpecification__c>{
      ps
    };

    List<cve__PaymentSpecification__c> expectedPaymentSpecs = new List<cve__PaymentSpecification__c>{
      new cve__PaymentSpecification__c(Claimant__c = queryContact().Id)
    };

    Amoss_Instance mockHelper = new Amoss_Instance(
      PaymentSpecificationTriggerHelper.class
    );
    mockHelper.expects('withContextVars')
      .returningItself()
      .also()
      .expects('populateClaimants')
      .returning(expectedPaymentSpecs)
      .also()
      .expects('disableFicaAdjustments');
    PaymentSpecificationTriggerHelper helperDouble = (PaymentSpecificationTriggerHelper) mockHelper.getDouble();

    PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
      helperDouble,
      null,
      newPsList,
      null,
      null,
      null
    );

    Test.startTest();
    handler.beforeInsert();
    Test.stopTest();

    try {
      mockHelper.verify();
      verificationSucceeded = true;
    } finally {
      Assert.isTrue(
        verificationSucceeded,
        'PaymentSpecificationTriggerHelper.populateClaimants() method not called'
      );
    }
  }

  @IsTest
  static void populateClaimants_returns_claimantIds_on_paymentspecs_for_cvab_claims() {
    Contact con = queryContact();
    cvab__Claim__c cvabClaim1 = getCvabClaim();
    cvab__Claim__c cvabClaim2 = new cvab__Claim__c(cvab__Employee__c = con.Id);
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    insert cvabClaim2;
    TriggerHandler.clearAllBypasses();

    cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvabClaim1.Id
    );
    cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvabClaim2.Id
    );

    List<cve__PaymentSpecification__c> newPsList = new List<cve__PaymentSpecification__c>{
      ps1,
      ps2
    };

    PaymentSpecificationTriggerHelper helper = PaymentSpecificationTriggerHelper.getInstance()
      .withContextVars(
        new PaymentSpecificationTriggerHandler.ContextVariables(
          null,
          newPsList,
          null,
          null
        )
      );

    Test.startTest();
    List<cve__PaymentSpecification__c> returnedPaymentSpecs = helper.populateClaimants();
    helper.disableFicaAdjustments();
    Test.stopTest();

    Id expectedClaimantId = con.Id;

    for (cve__PaymentSpecification__c ps : returnedPaymentSpecs) {
      Id actualClaimantId = ps.Claimant__c;

      Assert.areEqual(
        expectedClaimantId,
        actualClaimantId,
        'Unexpected Claimant Id found on Payment Specification'
      );
    }
  }

  @IsTest
  static void populateClaimants_returns_claimantIds_on_paymentspecs_for_cve_claims() {
    Contact con = queryContact();
    cve__Claim__c cveClaim1 = getCveClaim();
    cve__Claim__c cveClaim2 = new cve__Claim__c(
      cve__ClaimantInsured__c = con.Id
    );
    TriggerHandler.bypass('CveClaimTriggerHandler');
    insert cveClaim2;
    TriggerHandler.clearAllBypasses();

    cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
      cve__Claim__c = cveClaim1.Id
    );
    cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
      cve__Claim__c = cveClaim2.Id
    );

    List<cve__PaymentSpecification__c> newPsList = new List<cve__PaymentSpecification__c>{
      ps1,
      ps2
    };

    PaymentSpecificationTriggerHelper helper = PaymentSpecificationTriggerHelper.getInstance()
      .withContextVars(
        new PaymentSpecificationTriggerHandler.ContextVariables(
          null,
          newPsList,
          null,
          null
        )
      );

    Test.startTest();
    List<cve__PaymentSpecification__c> returnedPaymentSpecs = helper.populateClaimants();
    Test.stopTest();

    Id expectedClaimantId = con.Id;

    for (cve__PaymentSpecification__c ps : returnedPaymentSpecs) {
      Id actualClaimantId = ps.Claimant__c;

      Assert.areEqual(
        expectedClaimantId,
        actualClaimantId,
        'Unexpected Claimant Id found on Payment Specification'
      );
    }
  }

  @IsTest
  static void trigger_sets_claimant_lookups_on_payment_spec_create() {
    cvab__Claim__c cvabClaim = getCvabClaim();
    cve__Claim__c cveClaim = getCveClaim();

    cve__PaymentSpecification__c cvabPs = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvabClaim.Id
    );
    cve__PaymentSpecification__c cvePs = new cve__PaymentSpecification__c(
      cve__Claim__c = cveClaim.Id
    );

    Test.startTest();
    insert new List<cve__PaymentSpecification__c>{ cvabPs, cvePs };
    Test.stopTest();

    Id expectedClaimantId = queryContact().Id;

    Id actualCvabClaimantId = [
      SELECT Id, Claimant__c
      FROM cve__PaymentSpecification__c
      WHERE cvint__AbsenceClaim__c != NULL
      LIMIT 1
    ]
    .Claimant__c;
    Id actualCveClaimantId = [
      SELECT Id, Claimant__c
      FROM cve__PaymentSpecification__c
      WHERE cvint__AbsenceClaim__c = NULL
      LIMIT 1
    ]
    .Claimant__c;

    Assert.areEqual(
      expectedClaimantId,
      actualCvabClaimantId,
      'Unexpected value found for Claimant when executing trigger'
    );
    Assert.areEqual(
      expectedClaimantId,
      actualCveClaimantId,
      'Unexpected value found for Claimant when executing trigger'
    );
  }

  @isTest
  static void testPaymentSpecificationWhenDenied() {
    Contact con = [SELECT id FROM Contact];
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    TriggerHandler.bypass('AdjustmentTriggerHandler');
    cvab__Claim__c c = new cvab__Claim__c(cvab__Employee__c = con.Id);
    insert c;

    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = c.id,
      cve__Period__c = 'Weekly',
      cve__Start__c = Date.newInstance(2024, 1, 1),
      cve__OverpaymentNet__c = 0,
      PaymentApprovalStatus__c = 'Approved'
    );
    insert ps;

    id repaymentRecordTypeId = Schema.getGlobalDescribe()
      .get('cve__UnallocatedPayment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Lump Sum Repayment')
      .getRecordTypeId();
    cve__UnallocatedPayment__c up = new cve__UnallocatedPayment__c(
      cve__Start__c = Date.Today(),
      RecordTypeId = repaymentRecordTypeId,
      cve__PaymentSpecification__c = ps.id,
      cve__LumpSum__c = -180,
      cve__LumpSumBeforeTaxes__c = -180,
      cve__BeforeTaxesPaid__c = -180,
      cve__Paid__c = -180
    );
    insert up;

    cvab__Claim__c c1 = new cvab__Claim__c(cvab__Employee__c = con.Id);
    insert c1;

    cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
      ClaimLeaveStatus__c = 'Pending',
      cvint__AbsenceClaim__c = c1.id,
      cve__Period__c = 'Weekly',
      cve__Start__c = Date.newInstance(2024, 1, 1),
      cve__OverpaymentNet__c = 0,
      PaymentApprovalStatus__c = 'Approved'
    );
    insert ps1;

    cve__PaymentSpecification__c oldPs = [
      SELECT
        id,
        PaymentApprovalStatus__c,
        ClaimLeaveStatus__c,
        cvint__AbsenceClaim__c,
        cve__Period__c,
        cve__Start__c,
        cve__OverpaymentNet__c
      FROM cve__PaymentSpecification__c
      WHERE id = :ps1.id
    ];

    ps1.ClaimLeaveStatus__c = 'Denied';

    cve__Adjustment__c adj = new cve__Adjustment__c(
      cve__Amount__c = 100,
      cve__Period__c = 'Weekly',
      cve__Type__c = 'Recoup Overpayment (Pre-Tax)',
      UnallocatedPayment__c = up.id,
      cve__PaymentSpecification__c = ps1.id,
      PriorPaymentSpecs__c = ps.id
    );
    insert adj;

    TriggerHandler.clearAllBypasses();

    PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
      PaymentSpecificationTriggerHelper.getInstance(),
      new List<cve__PaymentSpecification__c>{ oldPs },
      new List<cve__PaymentSpecification__c>{ ps1 },
      new Map<Id, cve__PaymentSpecification__c>{ oldPs.id => oldPs },
      new Map<Id, cve__PaymentSpecification__c>{ ps1.id => ps1 },
      EventPublisher.getInstance()
    );

    test.startTest();

    handler.afterUpdate();

    test.stopTest();

    List<cve__Adjustment__c> adjList = [
      SELECT id, UnallocatedPayment__c
      FROM cve__Adjustment__c
      WHERE cve__PaymentSpecification__c = :ps1.id
    ];

    System.assertEquals(
      0,
      adjList.size(),
      'Unallocated Payment and adjustment was not deleted'
    );
  }

  public static cvab__Claim__c getCvabClaim() {
    return [
      SELECT Id, TotalOverpayments__c, cvab__Employee__c
      FROM cvab__Claim__c
    ];
  }

  public static cve__Claim__c getCveClaim() {
    return [
      SELECT Id, cve__OverpaymentNet__c, cve__ClaimantInsured__c
      FROM cve__Claim__c
    ];
  }

  public static Contact queryContact() {
    return [SELECT Id, AccountId FROM Contact LIMIT 1];
  }
}