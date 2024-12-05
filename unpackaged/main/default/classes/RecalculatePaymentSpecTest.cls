@isTest
public class RecalculatePaymentSpecTest {
  @testSetup
  public static void testSetup() {
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

    cve__Claim__c c = new cve__Claim__c(
      cve__ClaimantInsured__c = con.id,
      cve__OverpaymentNet__c = 0
    );
    insert c;

    TriggerHandler.bypass('BenefitClaimedTriggerHandler');
    cve__Product__c product = new cve__Product__c(
      Name = 'testProduct',
      cve__Status__c = 'Active',
      cve__Effective__c = Date.newInstance(2010, 1, 1)
    );
    insert product;

    Map<String, Schema.RecordTypeInfo> bRecordTypes = cve__Benefit__c.getSObjectType()
      .getDescribe()
      .getRecordTypeInfosByName();

    Id ciRecordTypeId = bRecordTypes.get('Critical Illness').getRecordTypeId();

    cve__Benefit__c benefit = new cve__Benefit__c(
      cve__Product__c = product.Id,
      cve__Product__r = product,
      RecordTypeId = ciRecordTypeId,
      cve__BenefitPercentage__c = 50.00
    );
    insert benefit;

    Map<String, Schema.RecordTypeInfo> bcRecordTypes = cve__BenefitClaimed__c.getSObjectType()
      .getDescribe()
      .getRecordTypeInfosByName();

    Id bcRecordTypeId = bcRecordTypes.get('Critical Illness').getRecordTypeId();

    cve__BenefitClaimed__c bc = new cve__BenefitClaimed__c(
      RecordTypeId = bcRecordTypeId,
      cve__Claim__c = c.id,
      cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
      cve__Benefit__c = benefit.id,
      cve__ClaimantInsured__c = con.id,
      IncurredDate__c = Date.newInstance(2024, 12, 10)
    );
    insert bc;

    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cve__Claim__c = c.id,
      cve__Amount__c = 800,
      cve__Start__c = Date.newInstance(2015, 1, 1),
      cve__Through__c = Date.newInstance(2015, 1, 31),
      cve__Period__c = 'Weekly',
      cve__AmountPeriod__c = 'Weekly',
      cve__BenefitClaimed__c = bc.id
    );
    insert ps;

    TriggerHandler.clearAllBypasses();
  }

  @isTest
  public static void testPaymentSpecRecalculation() {
    cve__PaymentSpecification__c ps = getPaymentSpecification();

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    RecalculatePaymentSpecHelper helper = RecalculatePaymentSpecHelper.getInstance();
    RecalculatePaymentSpecHandler handler = new RecalculatePaymentSpecHandler(
      helper,
      new List<RecalculatePaymentSpec__e>{
        new RecalculatePaymentSpec__e(PaymentSpecificationId__c = ps.Id)
      },
      eventPublisherDouble
    );

    Test.startTest();

    handler.afterInsert();

    Test.stopTest();

    ps = getPaymentSpecification();

    System.assertEquals(
      1,
      helper.result.size(),
      'Recalculation job was not successful'
    );
  }

  @isTest
  public static void testRecalculatePaymentEventPublishing() {
    cve__PaymentSpecification__c ps = getPaymentSpecification();

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    RecalculatePaymentSpecHelper helper = RecalculatePaymentSpecHelper.getInstance();
    RecalculatePaymentSpecHandler handler = new RecalculatePaymentSpecHandler(
      helper,
      new List<RecalculatePaymentSpec__e>{
        new RecalculatePaymentSpec__e(
          PaymentSpecificationId__c = ps.Id,
          RecalculatePaymentRequired__c = true
        )
      },
      eventPublisherDouble
    );

    Test.startTest();

    handler.afterInsert();

    Test.stopTest();

    ps = getPaymentSpecification();

    System.assertEquals(
      1,
      helper.result.size(),
      'Recalculation job was not successful'
    );

    List<RecalculatePayments__e> expectedResult = new List<RecalculatePayments__e>{
      new RecalculatePayments__e(PaymentSpecificationId__c = ps.id)
    };

    List<RecalculatePayments__e> actualOutcome = (List<RecalculatePayments__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      expectedResult,
      actualOutcome,
      'Published RecalculatePayments__e does not match expected RecalculatePayments__e'
    );
  }

  @isTest
  public static void testEventPublishingWithBenefitClaimedStatus() {
    cve__PaymentSpecification__c ps = getPaymentSpecification();

    TriggerHandler.bypass('BenefitClaimedTriggerHandler');
    cve__BenefitClaimed__c bc = new cve__BenefitClaimed__c(
      id = ps.cve__BenefitClaimed__c,
      ClaimBrainIntegrationStatus__c = 'Calculating'
    );
    update bc;
    TriggerHandler.clearAllBypasses();

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    RecalculatePaymentSpecHelper helper = RecalculatePaymentSpecHelper.getInstance();
    RecalculatePaymentSpecHandler handler = new RecalculatePaymentSpecHandler(
      helper,
      new List<RecalculatePaymentSpec__e>{
        new RecalculatePaymentSpec__e(
          PaymentSpecificationId__c = ps.Id,
          RecalculatePaymentRequired__c = true,
          ClaimBrainCalculation__c = true
        )
      },
      eventPublisherDouble
    );

    Test.startTest();

    handler.afterInsert();

    Test.stopTest();

    ps = getPaymentSpecification();

    System.assertEquals(
      1,
      helper.result.size(),
      'Recalculation job was not successful'
    );

    List<RecalculatePayments__e> expectedResult = new List<RecalculatePayments__e>{
      new RecalculatePayments__e(
        PaymentSpecificationId__c = ps.id,
        ClaimBrainCalculation__c = true
      )
    };

    List<RecalculatePayments__e> actualOutcome = (List<RecalculatePayments__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      expectedResult,
      actualOutcome,
      'Published RecalculatePayments__e does not match expected RecalculatePayments__e'
    );
  }

  @isTest
  public static void triggerTest() {
    cve__PaymentSpecification__c ps = getPaymentSpecification();
    EventPublisher event = EventPublisher.getInstance();
    Boolean errorOccured = false;
    List<RecalculatePaymentSpec__e> eventList = new List<RecalculatePaymentSpec__e>{
      new RecalculatePaymentSpec__e(PaymentSpecificationId__c = ps.Id)
    };
    try {
      Test.startTest();
      event.publish(eventList);
      Test.stopTest();
    } catch (Exception e) {
      errorOccured = true;
    }
    System.assertEquals(
      false,
      errorOccured,
      'Error occured while Recalculating PaymentSpec'
    );
  }

  private static cve__PaymentSpecification__c getPaymentSpecification() {
    return [
      SELECT id, cve__Amount__c, cve__BenefitClaimed__c
      FROM cve__PaymentSpecification__c
    ];
  }
}