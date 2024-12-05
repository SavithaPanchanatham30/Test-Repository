@isTest
public class ConsolidatePaymentsTest {
  @TestSetup
  public static void createData() {
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

    cvab__Claim__c absence = new cvab__Claim__c(cvab__Employee__c = con.Id);
    insert absence;

    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = absence.id,
      cve__Amount__c = 800,
      cve__Start__c = Date.newInstance(2015, 1, 1),
      cve__Through__c = Date.newInstance(2015, 6, 31),
      cve__Period__c = 'Weekly',
      cve__AmountPeriod__c = 'Weekly'
    );
    insert ps;

    cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = absence.id,
      cve__Amount__c = 1500,
      cve__Start__c = Date.newInstance(2015, 1, 1),
      cve__Through__c = Date.newInstance(2015, 6, 31),
      cve__Period__c = 'Monthly',
      cve__AmountPeriod__c = 'Monthly'
    );
    insert ps2;
    cve__Payment__c pLumpSum;
    insert pLumpSum = new cve__Payment__c(
      RecordTypeId = getIdFromName('cve__Payment__c', 'Lump Sum'),
      cve__PaymentSpecification__c = ps2.Id,
      cve__Claim__c = disability.Id,
      cve__Net__c = 3000.00,
      cve__Status__c = 'Pending',
      cve__Start__c = Date.newInstance(2010, 2, 18),
      cve__Through__c = Date.newInstance(2010, 3, 18),
      cve__Payable__c = Date.newInstance(2024, 3, 4)
    );

    cve__Payment__c pLumpSum1;
    insert pLumpSum1 = new cve__Payment__c(
      RecordTypeId = getIdFromName('cve__Payment__c', 'Lump Sum'),
      cve__PaymentSpecification__c = ps2.Id,
      cve__Claim__c = disability.Id,
      cve__Net__c = 3000.00,
      cve__Status__c = 'Consolidated',
      cve__Start__c = Date.newInstance(2011, 2, 18),
      cve__Through__c = Date.newInstance(2011, 3, 18),
      cve__Payable__c = Date.newInstance(2024, 3, 4)
    );

    cve__PaymentSpecification__c ps3 = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = absence.id,
      cve__Amount__c = 2500,
      cve__Start__c = Date.newInstance(2015, 1, 1),
      cve__Through__c = Date.newInstance(2015, 6, 31),
      cve__Period__c = 'monthly',
      cve__AmountPeriod__c = 'monthly'
    );
    insert ps3;
    insert pLumpSum = new cve__Payment__c(
      RecordTypeId = getIdFromName('cve__Payment__c', 'Lump Sum Repayment'),
      cve__PaymentSpecification__c = ps3.Id,
      cve__Claim__c = disability.Id,
      cve__Net__c = 2500.00,
      cve__Status__c = 'Pending',
      cve__Start__c = Date.newInstance(2010, 2, 18),
      cve__Through__c = Date.newInstance(2010, 3, 18),
      cve__Payable__c = Date.newInstance(2024, 3, 4)
    );

    insert pLumpSum1 = new cve__Payment__c(
      RecordTypeId = getIdFromName('cve__Payment__c', 'Lump Sum Repayment'),
      cve__PaymentSpecification__c = ps3.Id,
      cve__Claim__c = disability.Id,
      cve__Net__c = 3000.00,
      cve__Status__c = 'Pending',
      cve__Start__c = Date.newInstance(2011, 2, 18),
      cve__Through__c = Date.newInstance(2011, 3, 18),
      cve__Payable__c = Date.newInstance(2024, 3, 4)
    );
    cve__UnallocatedPayment__c up = new cve__UnallocatedPayment__c(
      cve__PaymentSpecification__c = ps.Id,
      cve__Start__c = Date.today(),
      cve__Through__c = Date.today().addDays(6),
      cve__GrossBenefit__c = 1000
    );
    insert up;
    insert pLumpSum = new cve__Payment__c(
      RecordTypeId = getIdFromName('cve__Payment__c', 'Calculated'),
      cve__PaymentSpecification__c = ps.Id,
      cve__PaymentMethod__c = 'Check',
      cve__MailingStreet__c = 'test',
      cve__MailingCity__c = 'test city',
      cve__MailingState__c = 'MA',
      cve__MailingPostalCode__c = '123456',
      cve__MailingCountry__c = 'US',
      cve__UnallocatedPayment__c = up.id,
      cve__Claim__c = disability.Id,
      cve__Net__c = 3000.00,
      cve__Status__c = 'Pending',
      cve__Start__c = Date.newInstance(2024, 1, 2),
      cve__Through__c = Date.newInstance(2024, 1, 8),
      cve__Payable__c = Date.today()
    );
    cve__UnallocatedPayment__c up1 = new cve__UnallocatedPayment__c(
      cve__PaymentSpecification__c = ps.Id,
      cve__Start__c = Date.today(),
      cve__Through__c = Date.today().addDays(6),
      cve__GrossBenefit__c = 1000
    );
    insert up1;
    cve__Payment__c calculated;
    insert calculated = new cve__Payment__c(
      RecordTypeId = getIdFromName('cve__Payment__c', 'Calculated'),
      cve__PaymentSpecification__c = ps.Id,
      cve__PaymentMethod__c = 'Check',
      cve__MailingStreet__c = 'test',
      cve__MailingCity__c = 'test city',
      cve__MailingState__c = 'MA',
      cve__MailingPostalCode__c = '123456',
      cve__MailingCountry__c = 'US',
      cve__UnallocatedPayment__c = up1.id,
      cve__Claim__c = disability.Id,
      cve__Net__c = 3000.00,
      cve__Status__c = 'Pending',
      cve__Start__c = Date.newInstance(2024, 1, 9),
      cve__Through__c = Date.newInstance(2024, 1, 15),
      cve__Payable__c = Date.today()
    );
    insert new cve__ExplanationOfBenefit__c(
      cve__AdjustmentType__c = null,
      cve__Amount__c = pLumpSum.cve__Net__c,
      cve__AmountPeriod__c = 'Lump Sum',
      cve__Description__c = 'Manually entered lump sum',
      cve__Payment__c = pLumpSum.Id,
      RecordTypeId = getIdFromName('cve__ExplanationOfBenefit__c', 'Gross'),
      cve__Start__c = pLumpSum.cve__Start__c,
      cve__Through__c = pLumpSum.cve__Through__c
    );
    insert new cve__ExplanationOfBenefit__c(
      cve__AdjustmentType__c = null,
      cve__Amount__c = calculated.cve__Net__c,
      cve__AmountPeriod__c = 'Calculated',
      cve__Description__c = 'Manually entered lump sum',
      cve__Payment__c = calculated.Id,
      cve__Start__c = calculated.cve__Start__c,
      cve__Through__c = calculated.cve__Through__c
    );
    cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = absence.id,
      cve__Amount__c = 1000,
      cve__Start__c = Date.newInstance(2015, 1, 1),
      cve__Through__c = Date.newInstance(2015, 6, 31),
      cve__Period__c = 'Weekly',
      cve__AmountPeriod__c = 'Weekly'
    );
    insert ps1;
    insert pLumpSum = new cve__Payment__c(
      RecordTypeId = getIdFromName('cve__Payment__c', 'Calculated'),
      cve__PaymentSpecification__c = ps1.Id,
      cve__Claim__c = disability.Id,
      cve__Net__c = 3000.00,
      cve__Status__c = 'Consolidated',
      cve__Start__c = Date.newInstance(2024, 1, 2),
      cve__Through__c = Date.newInstance(2024, 1, 8),
      cve__Payable__c = Date.newInstance(2024, 3, 4)
    );

    cve__Allocation__c allocation = new cve__Allocation__c(
      cve__Contact__c = con.Id,
      cve__PaymentSpecification__c = ps.Id,
      cve__AllocatedNetPercentage__c = 100
    );
    insert allocation;
  }

  @IsTest
  static void testConsolidate() {
    Map<Id, Date> issueDates = new Map<Id, Date>();
    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec = new Map<Id, List<cve__Payment__c>>();
    cve__PaymentSpecification__c ps = [
      SELECT Id
      FROM cve__PaymentSpecification__c
      WHERE cve__Amount__c = 800
    ];
    payments = getPayments(new Set<Id>{ ps.Id });
    paymentsPerPaySpec = paymentsPerPaymentsSpecification(payments);
    Set<Id> ids = new Set<Id>(getIds(payments));
    List<Id> psIds = new List<Id>();
    psIds.add(ps.Id);
    Test.StartTest();
    ConsolidatePayments cp = new ConsolidatePayments();
    cp.consolidatePaymentsByPaymentSpecIds(psIds);
    new ConsolidatePayments.ConsolidateAction(
      paymentsPerPaySpec,
      payments,
      issueDates
    );
    Test.StopTest();

    customAssert_assertConsolidatedPayableDate(ids, ps.id);
    customAssert_assertConsolidatedIssueDate(ids, ps.id);
    customAssert_assertConsolidatedStatus(ids, ps.id);
  }

  @IsTest
  static void testConsolidateWithMultiplePaymentSpecification() {
    Map<Id, Date> issueDates = new Map<Id, Date>();
    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec = new Map<Id, List<cve__Payment__c>>();
    List<cve__PaymentSpecification__c> paymentSpecifications = [
      SELECT Id
      FROM cve__PaymentSpecification__c
    ];
    Set<Id> pids = new Set<Id>(getIds(paymentSpecifications));
    payments = getPayments(pids);
    for (cve__Payment__c p : payments) {
      if (paymentsPerPaySpec.get(p.cve__PaymentSpecification__c) == null) {
        paymentsPerPaySpec.put(
          p.cve__PaymentSpecification__c,
          new List<cve__Payment__c>()
        );
      }
      paymentsPerPaySpec.get(p.cve__PaymentSpecification__c).add(p);
    }

    Test.StartTest();

    String result;
    for (Id id : paymentsPerPaySpec.keyset()) {
      ConsolidatePayments.ConsolidateAction ca = new ConsolidatePayments.ConsolidateAction(
        paymentsPerPaySpec,
        payments,
        issueDates
      );
      payments = paymentsPerPaySpec.get(id);
      for (Integer i = 0; i < payments.size(); i++) {
        result = ca.validate(payments.get(i), i == 0, i == payments.size() - 1);
      }
      Boolean validatePayment = false;
      if (result != null) {
        paymentsPerPaySpec.remove(id);
        validatePayment = true;
      }

      Assert.isTrue(
        validatePayment,
        'Validate failed - Payment will not consolidate'
      );
    }

    Test.StopTest();

    for (Id id : paymentsPerPaySpec.keyset()) {
      customAssert_assertConsolidatedPayableDate(
        new Set<Id>(getIds(paymentsPerPaySpec.get(id))),
        id
      );
      customAssert_assertConsolidatedIssueDate(
        new Set<Id>(getIds(paymentsPerPaySpec.get(id))),
        id
      );
      customAssert_assertConsolidatedStatus(
        new Set<Id>(getIds(paymentsPerPaySpec.get(id))),
        id
      );
    }
  }

  @isTest
  static void validateOnePayment() {
    Map<Id, Date> issueDates = new Map<Id, Date>();
    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec = new Map<Id, List<cve__Payment__c>>();
    cve__PaymentSpecification__c ps = [
      SELECT Id
      FROM cve__PaymentSpecification__c
      WHERE cve__Amount__c = 1000
    ];
    payments = getPayments(new Set<Id>{ ps.Id });
    paymentsPerPaySpec = paymentsPerPaymentsSpecification(payments);

    Test.StartTest();

    ConsolidatePayments.ConsolidateAction ca = new ConsolidatePayments.ConsolidateAction(
      paymentsPerPaySpec,
      payments,
      issueDates
    );
    String result;
    cve__Payment__c payment;
    for (Integer i = 0; i < payments.size(); i++) {
      payment = payments.get(i);
      result = ca.validate(payments.get(i), i == 0, i == payments.size() - 1);
    }
    Test.StopTest();

    Assert.areEqual(
      payment.Name + ' consolidate failed; multiple payments must be selected',
      result,
      'Multiple payments must be selected'
    );
  }

  @isTest
  static void validateStatus() {
    Map<Id, Date> issueDates = new Map<Id, Date>();

    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec = new Map<Id, List<cve__Payment__c>>();
    cve__PaymentSpecification__c ps = [
      SELECT Id
      FROM cve__PaymentSpecification__c
      WHERE cve__Amount__c = 1500
    ];
    payments = getPayments(new Set<Id>{ ps.Id });
    paymentsPerPaySpec = paymentsPerPaymentsSpecification(payments);

    Test.StartTest();
    ConsolidatePayments.ConsolidateAction ca = new ConsolidatePayments.ConsolidateAction(
      paymentsPerPaySpec,
      payments,
      issueDates
    );
    String result;
    cve__Payment__c p1;
    for (cve__Payment__c p : payments) {
      result = ca.validate(p, false, false);
      p1 = p;
    }

    Test.StopTest();
    Assert.areEqual(
      p1.Name +
      ' consolidate failed; only payments with a status of (Pending, Approved, Rejected) can be consolidated',
      result,
      'only payments with status of Pending, Approved and Rejected can be consolidated'
    );
  }

  @isTest
  static void validateRecordType() {
    Map<Id, Date> issueDates = new Map<Id, Date>();
    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec = new Map<Id, List<cve__Payment__c>>();
    cve__PaymentSpecification__c ps = [
      SELECT Id
      FROM cve__PaymentSpecification__c
      WHERE cve__Amount__c = 2500
    ];
    payments = getPayments(new Set<Id>{ ps.Id });
    paymentsPerPaySpec = paymentsPerPaymentsSpecification(payments);

    Test.StartTest();
    ConsolidatePayments.ConsolidateAction ca = new ConsolidatePayments.ConsolidateAction(
      paymentsPerPaySpec,
      payments,
      issueDates
    );
    String result;
    cve__Payment__c p1;
    for (cve__Payment__c p : payments) {
      result = ca.validate(p, false, false);
      p1 = p;
    }
    Test.StopTest();
    Assert.areEqual(
      p1.Name +
      ' consolidate failed; only "Calculated" or "Lump Sum" payments can be consolidated',
      result,
      'Only calculated or lump sum payments can be consolidated'
    );
  }

  public static Map<Id, List<cve__Payment__c>> paymentsPerPaymentsSpecification(
    List<cve__Payment__c> payments
  ) {
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec = new Map<Id, List<cve__Payment__c>>();
    for (cve__Payment__c p : payments) {
      if (paymentsPerPaySpec.get(p.cve__PaymentSpecification__c) == null) {
        paymentsPerPaySpec.put(
          p.cve__PaymentSpecification__c,
          new List<cve__Payment__c>()
        );
      }
      paymentsPerPaySpec.get(p.cve__PaymentSpecification__c).add(p);
    }
    return paymentsPerPaySpec;
  }

  public static cve__Payment__c getSinglePayment() {
    cve__Payment__c p = [
      SELECT
        Id,
        cve__Status__c,
        Name,
        cve__Start__c,
        cve__Through__c,
        RecordTypeId
      FROM cve__Payment__c
      LIMIT 1
    ];
    return p;
  }

  public static List<cve__Payment__c> getPayments(
    Set<Id> paymentSpecificationsIds
  ) {
    List<cve__Payment__c> payments = [
      SELECT
        Id,
        Name,
        cve__PaymentSpecification__c,
        cve__PaymentSpecification__r.cve__Period__c,
        cve__BenefitClaimed__c,
        RecordTypeId,
        cve__NetBeforeTaxes__c,
        cve__NetAfterTaxes__c,
        cve__Net__c,
        cve__FicaTaxableBenefitAmount__c,
        cve__EmployerMatchingMedicare__c,
        cve__EmployerMatchingFica__c,
        cve__IssueOverride__c,
        cve__Issue__c,
        cve__Payable__c,
        cve__Through__c,
        cve__Start__c,
        cve__PaymentMethod__c,
        cve__Account__c,
        cve__Contact__c,
        cve__Claim__c,
        cve__Status__c
      FROM cve__Payment__c
      WHERE cve__PaymentSpecification__c IN :paymentSpecificationsIds
    ];

    return payments;
  }

  public static Map<Id, cve__PaymentSpecification__c> getPaymentSpec() {
    Map<Id, cve__PaymentSpecification__c> ps = new Map<ID, cve__PaymentSpecification__c>(
      [
        SELECT Id
        FROM cve__PaymentSpecification__c
      ]
    );
    return ps;
  }

  static void customAssert_assertConsolidatedPayableDate(Set<Id> ids, Id id) {
    cve__Payment__c consolidated = readNewPayment(ids, id);
    Assert.areEqual(
      consolidated.cve__Through__c,
      consolidated.cve__Payable__c,
      'Payable date should be today date'
    );
  }
  static void customAssert_assertConsolidatedIssueDate(Set<Id> ids, Id id) {
    cve__Payment__c consolidated = readNewPayment(ids, id);
    Assert.areEqual(
      consolidated.cve__Through__c,
      consolidated.cve__issue__c,
      'Issue date should be today date'
    );
  }
  static void customAssert_assertConsolidatedStatus(Set<Id> ids, Id id) {
    List<cve__Payment__c> consolidatedPayments = readConsolidatedPayment(
      ids,
      id
    );
    for (cve__Payment__c p : consolidatedPayments) {
      Assert.areEqual(
        'Consolidated',
        p.cve__Status__c,
        'Consolidated payments having status consolidated'
      );
    }
  }

  static cve__Payment__c readNewPayment(Set<Id> ids, Id id) {
    for (cve__Payment__c p : getpayments(new Set<Id>{ id })) {
      if (!ids.contains(p.Id)) {
        return p;
      }
    }
    System.assert(false, 'no new payment');
    return null;
  }
  static List<cve__Payment__c> readConsolidatedPayment(Set<Id> ids, Id id) {
    List<cve__Payment__c> consolidatedPayments = new List<cve__Payment__c>();
    for (cve__Payment__c p : getpayments(new Set<Id>{ id })) {
      if (ids.contains(p.Id)) {
        consolidatedPayments.add(p);
      }
    }
    return consolidatedPayments;
  }

  static List<Id> getIds(List<SObject> sobs) {
    List<Id> ids = new List<Id>();
    for (SObject sob : sobs) {
      ids.add(sob.Id);
    }
    return ids;
  }

  static Id getIdFromName(String t, String recordTypeName) {
    RecordType recordType = [
      SELECT Id, Name, SobjectType
      FROM RecordType
      WHERE
        SObjectType = :t
        AND (Name = :recordTypeName
        OR Name = :recordTypeName.deleteWhitespace())
      LIMIT 1
    ];

    return recordType.Id;
  }
}