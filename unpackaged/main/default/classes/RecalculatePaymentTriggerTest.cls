@isTest
public class RecalculatePaymentTriggerTest {
  @TestSetup
  public static void createData() {
    User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    System.runAs(u) {
      cve__PaymentCalculationOptions__c cs = new cve__PaymentCalculationOptions__c();
      cs.cve__PayableInclusionPatterns__c = '*,*,*,*';
      insert cs;

      List<String> psNames = new List<String>{
        'PaymentSpecificationRollup_WRITE',
        'PaymentApproval_WRITE'
      };

      User testUser = (User) new TestUserBuilder()
        .withLastName('recalculatepaymenttrigger')
        .buildAndInsert();

      TestUtils.assignPermissionSetsToUser(testUser, psNames);
    }

    SObject acc = new TestAccountBuilder().buildAndInsert();
    SObject customGroup = new TestGroupBuilder()
      .withMasterGroupId(acc.Id)
      .buildAndInsert();
    SObject con = new TestContactBuilder()
      .withAccountId(acc.Id)
      .withGroupId(customGroup.Id)
      .buildAndInsert();

    cve__Claim__c disability = new cve__Claim__c(
      cve__ClaimantInsured__c = con.Id,
      ExpressPaid__c = false
    );
    insert disability;

    cvab__Claim__c absence = new cvab__Claim__c(
      cvab__Employee__c = con.Id,
      ExpressPaid__c = false
    );
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

    insert new cve__Payment__c(
      cve__PaymentSpecification__c = ps.Id,
      cve__Claim__c = disability.Id,
      cve__Net__c = 3000.00,
      cve__Start__c = Date.newInstance(2010, 2, 14),
      cve__Through__c = Date.newInstance(2010, 2, 14),
      cve__Payable__c = Date.newInstance(2024, 3, 4)
    );
    cve__Payment__c pLumpSum;
    insert pLumpSum = new cve__Payment__c(
      RecordTypeId = getIdFromName('cve__Payment__c', 'Lump Sum'),
      cve__PaymentSpecification__c = ps.Id,
      cve__Claim__c = disability.Id,
      cve__Net__c = 3000.00,
      cve__Status__c = 'Pending',
      cve__Start__c = Date.newInstance(2010, 2, 18),
      cve__Through__c = Date.newInstance(2010, 2, 18),
      cve__Payable__c = Date.newInstance(2024, 3, 4)
    );

    insert new cve__ExplanationOfBenefit__c(
      cve__AdjustmentType__c = null,
      cve__Amount__c = pLumpSum.cve__Net__c,
      cve__AmountPeriod__c = 'Lump Sum',
      cve__Description__c = 'Manually entered lump sum',
      cve__Payment__c = pLumpSum.Id,
      cve__Start__c = pLumpSum.cve__Start__c,
      cve__Through__c = pLumpSum.cve__Through__c
    );

    cve__Allocation__c allocation = new cve__Allocation__c(
      cve__Contact__c = con.Id,
      cve__PaymentSpecification__c = ps.Id,
      cve__AllocatedNetPercentage__c = 100
    );
    insert allocation;

    cve__Product__c prod = new cve__Product__c(
      cve__Account__c = acc.Id,
      Name = 'STD Prod'
    );
    insert prod;

    cve__Benefit__c benefit = new cve__Benefit__c(
      Name = 'STD Bennie',
      cve__Product__c = prod.Id,
      cve__BenefitPercentage__c = 100
    );
    insert benefit;

    cve__BenefitClaimed__c bc = new cve__BenefitClaimed__c(
      RecordTypeId = getIdFromName(
        'cve__BenefitClaimed__c',
        'Short Term Disability'
      ),
      cve__Claim__c = disability.Id,
      cve__Benefit__c = benefit.Id
    );
    insert bc;

    cve__PaymentSpecification__c disabilityPs = new cve__PaymentSpecification__c(
      cve__BenefitClaimed__c = bc.Id,
      cve__Claim__c = disability.Id,
      cve__Amount__c = 800,
      cve__Start__c = Date.newInstance(2015, 1, 1),
      cve__Through__c = Date.newInstance(2015, 6, 31),
      cve__Period__c = 'Weekly',
      cve__AmountPeriod__c = 'Weekly',
      RecordTypeId = getIdFromName(
        'cve__PaymentSpecification__c',
        'Short Term Disability'
      )
    );
    insert disabilityPs;
  }

  @isTest
  public static void insert_recalculatepayments_for_expresspay_absence_claim() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      cve__PaymentSpecification__c ps = getPaymentSpec();

      cvab__Claim__c cvabClaim = [
        SELECT Id, ExpressPaid__c
        FROM cvab__Claim__c
      ];
      cvabClaim.ExpressPaid__c = true;
      update cvabClaim;

      RecalculatePayments__e recalculatePayment = new RecalculatePayments__e(
        PaymentSpecificationId__c = ps.Id
      );

      RecalculatePaymentTriggerHandler testHandler = new RecalculatePaymentTriggerHandler(
        RecalculatePaymentTriggerHelper.getHelperInstance(),
        new List<RecalculatePayments__e>{ recalculatePayment },
        EventPublisher.getInstance()
      );

      Test.startTest();
      testHandler.afterInsert();
      Test.stopTest();

      for (String result : testHandler.results) {
        Assert.areEqual(
          'success',
          result,
          'Unexpected result of attempt to calculate payments'
        );
      }

      List<cve__Payment__c> actualPayments = getPayments();
      Assert.isTrue(actualPayments.size() > 0, 'Payments not calculated');

      Assert.isTrue(
        testHandler.consolidatedPayments.size() > 0,
        'Payments not consolidated'
      );

      Integer approvedCount = 0;
      for (cve__Payment__c payment : testHandler.consolidatedPayments) {
        Assert.isTrue(
          payment.cve__Status__c == 'Consolidated' ||
            payment.cve__Status__c == 'Approved',
          'Payment neither Approved nor Consolidated'
        );
        if (payment.cve__Status__c == 'Approved') {
          approvedCount += 1;
        }
      }

      Assert.areEqual(
        1,
        approvedCount,
        'Unexpected number of approved payments'
      );
    }
  }

  @isTest
  public static void insert_recalculatepayments_for_nonexpresspay_absence_claim() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      cve__PaymentSpecification__c ps = getPaymentSpec();

      RecalculatePayments__e recalculatePayment = new RecalculatePayments__e(
        PaymentSpecificationId__c = ps.id
      );

      RecalculatePaymentTriggerHandler testHandler = new RecalculatePaymentTriggerHandler(
        RecalculatePaymentTriggerHelper.getHelperInstance(),
        new List<RecalculatePayments__e>{ recalculatePayment },
        EventPublisher.getInstance()
      );

      Test.startTest();
      testHandler.afterInsert();
      Test.stopTest();

      for (String result : testHandler.results) {
        Assert.areEqual(
          'success',
          result,
          'Unexpected result of attempt to calculate payments'
        );
      }

      List<cve__Payment__c> actualPayments = getPayments();
      Assert.isTrue(actualPayments.size() > 0, 'Payments not calculated');

      Assert.isTrue(
        testHandler?.consolidatedPayments == null,
        'Payments erroneously consolidated'
      );
    }
  }

  @isTest
  public static void triggerTest() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      Boolean errorOccurred = false;
      cve__PaymentSpecification__c ps = getPaymentSpec();
      RecalculatePayments__e recalculatePayment = new RecalculatePayments__e(
        PaymentSpecificationId__c = ps.id
      );
      List<RecalculatePayments__e> eventList = new List<RecalculatePayments__e>();
      eventList.add(recalculatePayment);

      List<Database.SaveResult> results;

      Test.startTest();
      try {
        EventPublisher eventp = EventPublisher.getInstance();
        results = eventp.publish(eventList);
      } catch (Exception e) {
        errorOccurred = true;
      }
      Test.stopTest();

      Assert.isFalse(errorOccurred, 'Exception thrown during trigger');
      for (Database.SaveResult sr : results) {
        Assert.isTrue(sr.isSuccess(), 'Event failed to publish');
      }
    }
  }

  @isTest
  public static void testRecoupOverpaymentEventGeneration() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      Amoss_Instance mockEventPublisher = new Amoss_Instance(
        EventPublisher.class
      );
      mockEventPublisher.byDefaultMethodsReturn(
        new List<Database.SaveResult>()
      );
      EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

      cve__PaymentSpecification__c ps = getPaymentSpec();
      TriggerHandler.clearAllBypasses();

      RecalculatePayments__e recalculatePayment = new RecalculatePayments__e(
        PaymentSpecificationId__c = ps.id,
        RunOverpaymentCheck__c = true
      );

      RecalculatePaymentTriggerHandler testHandler = new RecalculatePaymentTriggerHandler(
        RecalculatePaymentTriggerHelper.getHelperInstance(),
        new List<RecalculatePayments__e>{ recalculatePayment },
        eventPublisherDouble
      );

      Test.startTest();
      testHandler.afterInsert();
      Test.stopTest();

      List<RecoupOverpayment__e> expectedResult = new List<RecoupOverpayment__e>{
        new RecoupOverpayment__e(PaymentSpecificationId__c = ps.id)
      };

      List<RecoupOverpayment__e> actualOutcome = (List<RecoupOverpayment__e>) mockEventPublisher.call(
          0
        )
        .of('publish')
        .parameter('events');

      Assert.areEqual(
        expectedResult,
        actualOutcome,
        'Published RecoupOverpayment__e does not match expected RecoupOverpayment__e'
      );
    }
  }

  @isTest
  public static void testBenefitClaimedUpdate() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      Amoss_Instance mockEventPublisher = new Amoss_Instance(
        EventPublisher.class
      );
      mockEventPublisher.byDefaultMethodsReturn(
        new List<Database.SaveResult>()
      );
      EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

      cve__PaymentSpecification__c ps = getDisabilitySpec();
      TriggerHandler.clearAllBypasses();

      RecalculatePayments__e recalculatePayment = new RecalculatePayments__e(
        PaymentSpecificationId__c = ps.id,
        RunOverpaymentCheck__c = true,
        ClaimBrainCalculation__c = true
      );

      RecalculatePaymentTriggerHandler testHandler = new RecalculatePaymentTriggerHandler(
        RecalculatePaymentTriggerHelper.getHelperInstance(),
        new List<RecalculatePayments__e>{ recalculatePayment },
        eventPublisherDouble
      );

      Test.startTest();
      testHandler.afterInsert();
      Test.stopTest();

      List<RecoupOverpayment__e> expectedResult = new List<RecoupOverpayment__e>{
        new RecoupOverpayment__e(PaymentSpecificationId__c = ps.id)
      };

      List<RecoupOverpayment__e> actualOutcome = (List<RecoupOverpayment__e>) mockEventPublisher.call(
          0
        )
        .of('publish')
        .parameter('events');

      Assert.areEqual(
        expectedResult,
        actualOutcome,
        'Published RecoupOverpayment__e does not match expected RecoupOverpayment__e'
      );

      cve__BenefitClaimed__c bc = getBenefitClaimed();
      Assert.areEqual(
        'Complete',
        bc.ClaimBrainIntegrationStatus__c,
        'Benefit Claimed Status was not updated'
      );
    }
  }

  public static cve__PaymentSpecification__c getDisabilitySpec() {
    cve__PaymentSpecification__c ps = [
      SELECT Id
      FROM cve__PaymentSpecification__c
      WHERE cve__BenefitClaimed__c != NULL
      LIMIT 1
    ];
    return ps;
  }

  public static cve__PaymentSpecification__c getPaymentSpec() {
    cve__PaymentSpecification__c ps = [
      SELECT Id
      FROM cve__PaymentSpecification__c
      LIMIT 1
    ];
    return ps;
  }

  public static List<cve__Payment__c> getPayments() {
    cve__PaymentSpecification__c ps = getPaymentSpec();
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
      WHERE cve__PaymentSpecification__c = :ps.Id
    ];

    return payments;
  }

  static Id getIdFromName(String sObjectTypeName, String recordTypeName) {
    RecordType recordType = [
      SELECT Id, Name, SobjectType
      FROM RecordType
      WHERE SObjectType = :sObjectTypeName AND Name = :recordTypeName
      LIMIT 1
    ];

    return recordType.Id;
  }

  static User getTestUser() {
    return [
      SELECT Id
      FROM User
      WHERE LastName = 'recalculatepaymenttrigger'
      LIMIT 1
    ];
  }

  static cve__BenefitClaimed__c getBenefitClaimed() {
    return [
      SELECT
        Id,
        ClaimBrainIntegrationStatus__c,
        cve__Status__c,
        cve__Claim__c,
        cve__Claim__r.ExpressPaid__c
      FROM cve__BenefitClaimed__c
      LIMIT 1
    ];
  }
}