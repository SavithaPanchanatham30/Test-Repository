@isTest
public class UpdateCoverageClaimedTest {
  @TestSetup
  static void makeData() {
    User u = [
      SELECT id, name, email
      FROM User
      WHERE id = :UserInfo.getUserId()
    ];
    System.runAs(u) {
      User testUser = (User) new TestUserBuilder()
        .withLastName('coverageuser')
        .buildAndInsert();

      assignPermissionSetsToUser(
        testUser,
        new List<String>{
          'CoverageLimitation_WRITE',
          'MemberBenefit_WRITE',
          'ClaimIncurredDate_WRITE'
        }
      );
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

    cve__Coverage__c per = (cve__Coverage__c) new TestCoverageBuilder()
      .withAmount(100)
      .withBenefitId(benefit.id)
      .buildAndInsert();

    new TestCoverageBuilder()
      .withPercentageOf(per.id)
      .withPercentage(100.00)
      .withAmountPerUnit(10)
      .withAmount(100)
      .withBenefitId(benefit.id)
      .buildAndInsert();

    cve__Claim__c c = new cve__Claim__c(
      cve__ClaimantInsured__c = con.id,
      cve__OverpaymentNet__c = 0
    );
    insert c;

    Map<String, Schema.RecordTypeInfo> bcRecordTypes = cve__BenefitClaimed__c.getSObjectType()
      .getDescribe()
      .getRecordTypeInfosByName();

    Id bcRecordTypeId = bcRecordTypes.get('Critical Illness').getRecordTypeId();

    TriggerHandler.bypass('BenefitClaimedTriggerHandler');
    cve__BenefitClaimed__c bc = new cve__BenefitClaimed__c(
      RecordTypeId = bcRecordTypeId,
      cve__Claim__c = c.id,
      cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
      cve__Benefit__c = benefit.id,
      cve__ClaimantInsured__c = con.id,
      IncurredDate__c = Date.newInstance(2024, 12, 10)
    );
    insert bc;
    TriggerHandler.clearBypass('BenefitClaimedTriggerHandler');
  }

  static BenefitCoverageClaimedSelector createTestData(String coverageType) {
    Id recordID = Schema.getGlobalDescribe()
      .get('cve__Coverage__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get(coverageType)
      .getRecordTypeId();
    cve__Coverage__c cov = getCoverage();
    cov.RecordTypeId = recordID;
    update cov;

    cve__BenefitClaimed__c bc = getBenefitClaimed();
    usal__CoverageLimitation__c climit = new usal__CoverageLimitation__c(
      usal__MaximumUnits__c = 200,
      usal__MaximumTimesClaimed__c = 2,
      usal__MaximumAmount__c = 1000,
      usal__Coverage__c = cov.id
    );

    TriggerHandler.bypass('CoverageClaimedTriggerHandler');
    cve__CoverageClaimed__c cc = (cve__CoverageClaimed__c) new TestCoverageClaimedBuilder()
      .withPayableAmount(100)
      .withCoverage(cov)
      .withUnits(20)
      .withAmount(100)
      .withPayableUnits(2)
      .buildAndInsert();

    new TestCoverageClaimedBuilder()
      .withAmount(100)
      .withBenefitClaimed(getBenefitClaimed())
      .withUnits(20)
      .withCoverage(getCoverage())
      .withPayableUnits(2)
      .withPayableAmount(100)
      .buildAndInsert();
    TriggerHandler.clearAllBypasses();

    Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>> filterMap = new Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>();
    filterMap.put(climit, new List<cve__CoverageClaimed__c>{ cc });

    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filterCC = new Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>>();
    filterCC.put(getCoverageClaimed(), filterMap);

    Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>> limitMap = new Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>>();
    limitMap.put(
      getCoverageClaimed(),
      new List<usal__CoverageLimitation__c>{ climit }
    );
    Contact con = [SELECT id FROM Contact];
    cve__Benefit__c b = [SELECT id FROM cve__Benefit__c];
    usal__MemberBenefit__c mb = new usal__MemberBenefit__c(
      usal__Amount__c = 1210,
      usal__StartDate__c = Date.newInstance(2024, 12, 1),
      usal__EndDate__c = Date.newInstance(2024, 12, 31),
      usal__BenefitId__c = b.id,
      usal__ContactId__c = con.Id
    );

    Map<Id, cve__BenefitClaimed__c> bcMap = new Map<Id, cve__BenefitClaimed__c>();
    bcMap.put(bc.id, bc);

    Map<Id, usal__MemberBenefit__c> mbMap = new Map<Id, usal__MemberBenefit__c>();
    mbMap.put(bc.id, mb);

    Amoss_Instance mockSelector = new Amoss_Instance(
      BenefitCoverageClaimedSelector.class
    );
    mockSelector.allowsAnyCall()
      .when('filterCoveragesClaimedByCoverageLimitations')
      .willReturn(filterCC)
      .also()
      .when('getBenefitsCoveragesClaimed')
      .willReturn(bcMap)
      .also()
      .when('getCoverageLimitations')
      .willReturn(limitMap)
      .also()
      .when('getMemberBenefits')
      .willReturn(mbMap);
    BenefitCoverageClaimedSelector selectorDouble = (BenefitCoverageClaimedSelector) mockSelector.generateDouble();
    return selectorDouble;
  }

  static cve__BenefitClaimed__c getBenefitClaimed() {
    return [
      SELECT
        id,
        cve__benefit__r.cve__CoverageAmount__c,
        RecordTypeId,
        cve__CoverageAmount__c,
        cve__Explanation2__c
      FROM cve__BenefitClaimed__c
    ];
  }

  static cve__CoverageClaimed__c getCoverageClaimed() {
    return [
      SELECT
        Id,
        Name,
        cve__BenefitClaimed__c,
        cve__BenefitName__c,
        cve__ClaimId__c,
        cve__Amount__c,
        cve__Units__c,
        cve__BenefitClaimed__r.RecordTypeId,
        cve__BenefitClaimed__r.IncurredDate__c,
        cve__BenefitClaimed__r.cve__DateOfDisability__c,
        cve__BenefitClaimed__r.cve__Benefit__r.cve__CoverageAmount__c,
        cve__BenefitClaimed__r.cve__Benefit__c,
        cve__BenefitClaimed__r.cve__Claim__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__Policy__r.cve__Effective__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__c,
        cve__BenefitClaimed__r.cve__Claim__r.IncurredDate__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__ClaimantInsured__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Policy__c,
        cve__BenefitClaimed__r.cve__ClaimantInsured__c,
        cve__Coverage__r.cve__Category__c,
        cve__Coverage__c,
        cve__Coverage__r.RecordTypeId,
        cve__Coverage__r.cve__Amount__c,
        cve__Coverage__r.cve__AmountPerUnit__c,
        cve__Coverage__r.cve__Percentage__c,
        cve__Coverage__r.cve__PercentageOf__c,
        cve__Coverage__r.cve__PercentageOf__r.cve__Amount__c,
        cve__CoverageAmount__c,
        cve__CoverageRelationshipToPolicyholder__c,
        cve__EffectiveDateOfCoverage__c,
        cve__InvoiceLineItem__c,
        cve__PayableAmount__c,
        cve__PayableUnits__c,
        cve__Start__c
      FROM cve__CoverageClaimed__c
      WHERE cve__BenefitClaimed__c = :getBenefitClaimed().id
      LIMIT 1
    ];
  }

  static cve__Coverage__c getCoverage() {
    return [
      SELECT
        id,
        RecordTypeID,
        cve__AmountPerUnit__c,
        cve__Percentage__c,
        cve__Amount__c,
        cve__PercentageOf__r.cve__Amount__c
      FROM cve__Coverage__c
      WHERE cve__AmountPerUnit__c = 10
    ];
  }

  static User getTestUser() {
    return [
      SELECT Id
      FROM User
      WHERE LastName = 'coverageuser'
      LIMIT 1
    ];
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

  @isTest
  static void testIfCoverageTypeIsAmount() {
    User u = getTestUser();
    System.runAs(u) {
      BenefitCoverageClaimedSelector selector = createTestData('Amount');
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      List<UpdateCoverageClaimed__e> eventList = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };
      UpdateCoverageClaimedHelper helper = UpdateCoverageClaimedHelper.getInstance(
        selector
      );
      UpdateCoverageClaimedHandler handler = new UpdateCoverageClaimedHandler(
        helper,
        eventList,
        null
      );

      Test.startTest();
      handler.afterInsert();
      Test.stopTest();
      cc = getCoverageClaimed();
      Assert.areEqual(
        100,
        cc.cve__Amount__c,
        'Amount not calculated correctly'
      );
      Assert.areEqual(
        100,
        cc.cve__PayableAmount__c,
        'Payable Amount not calculated correctly'
      );
    }
  }

  @isTest
  static void testIfCoverageTypeIsAmountAutoNamed() {
    User u = getTestUser();
    System.runAs(u) {
      BenefitCoverageClaimedSelector selector = createTestData(
        'Amount Auto Named'
      );
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      List<UpdateCoverageClaimed__e> eventList = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };
      UpdateCoverageClaimedHelper helper = UpdateCoverageClaimedHelper.getInstance(
        selector
      );
      UpdateCoverageClaimedHandler handler = new UpdateCoverageClaimedHandler(
        helper,
        eventList,
        null
      );

      Test.startTest();
      handler.afterInsert();
      Test.stopTest();
      cc = getCoverageClaimed();
      Assert.areEqual(
        100,
        cc.cve__Amount__c,
        'Amount not calculated correctly'
      );
      Assert.areEqual(
        100,
        cc.cve__PayableAmount__c,
        'Payable Amount not calculated correctly'
      );
    }
  }

  @isTest
  static void testIfCoverageTypeIsPercentageOfBaseCoverage() {
    User u = getTestUser();
    System.runAs(u) {
      BenefitCoverageClaimedSelector selector = createTestData(
        'Percentage of Base Coverage'
      );
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      List<UpdateCoverageClaimed__e> eventList = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };
      UpdateCoverageClaimedHelper helper = UpdateCoverageClaimedHelper.getInstance(
        selector
      );
      UpdateCoverageClaimedHandler handler = new UpdateCoverageClaimedHandler(
        helper,
        eventList,
        null
      );

      Test.startTest();
      handler.afterInsert();
      Test.stopTest();
      cc = getCoverageClaimed();
      Assert.areEqual(
        1210,
        cc.cve__Amount__c,
        'Amount not calculated correctly'
      );
      Assert.areEqual(
        900,
        cc.cve__PayableAmount__c,
        'Payable Amount not calculated correctly'
      );
    }
  }

  @isTest
  static void testIfCoverageTypeIsPercentageOfOtherCoverage() {
    User u = getTestUser();
    System.runAs(u) {
      BenefitCoverageClaimedSelector selector = createTestData(
        'Percentage of Other Coverage'
      );
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      List<UpdateCoverageClaimed__e> eventList = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };
      UpdateCoverageClaimedHelper helper = UpdateCoverageClaimedHelper.getInstance(
        selector
      );
      UpdateCoverageClaimedHandler handler = new UpdateCoverageClaimedHandler(
        helper,
        eventList,
        null
      );

      Test.startTest();
      handler.afterInsert();
      Test.stopTest();
      cc = getCoverageClaimed();
      Assert.areEqual(
        100,
        cc.cve__Amount__c,
        'Amount not calculated correctly'
      );
      Assert.areEqual(
        100,
        cc.cve__PayableAmount__c,
        'Payable Amount not calculated correctly'
      );
    }
  }

  @isTest
  static void testIfCoverageTypeIsVariableAmount() {
    User u = getTestUser();
    System.runAs(u) {
      BenefitCoverageClaimedSelector selector = createTestData(
        'Variable Amount'
      );
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      List<UpdateCoverageClaimed__e> eventList = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };
      UpdateCoverageClaimedHelper helper = UpdateCoverageClaimedHelper.getInstance(
        selector
      );
      UpdateCoverageClaimedHandler handler = new UpdateCoverageClaimedHandler(
        helper,
        eventList,
        null
      );

      Test.startTest();
      handler.afterInsert();
      Test.stopTest();
      cc = getCoverageClaimed();
      Assert.areEqual(
        100,
        cc.cve__Amount__c,
        'Amount not calculated correctly'
      );
      Assert.areEqual(
        100,
        cc.cve__PayableAmount__c,
        'Payable Amount not calculated correctly'
      );
    }
  }

  @isTest
  static void testIfCoverageTypeIsVariableUnits() {
    User u = getTestUser();
    System.runAs(u) {
      BenefitCoverageClaimedSelector selector = createTestData(
        'Variable Units'
      );
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      List<UpdateCoverageClaimed__e> eventList = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };
      UpdateCoverageClaimedHelper helper = UpdateCoverageClaimedHelper.getInstance(
        selector
      );
      UpdateCoverageClaimedHandler handler = new UpdateCoverageClaimedHandler(
        helper,
        eventList,
        null
      );

      Test.startTest();
      handler.afterInsert();
      Test.stopTest();
      cc = getCoverageClaimed();
      Assert.areEqual(
        200,
        cc.cve__PayableAmount__c,
        'Payable Amount not calculated correctly'
      );
      Assert.areEqual(
        20,
        cc.cve__PayableUnits__c,
        'Payable Units not calculated correctly'
      );
      Assert.areEqual(
        200,
        cc.cve__Amount__c,
        'Amount not calculated correctly'
      );
    }
  }

  @isTest
  static void triggerTest() {
    User u = getTestUser();
    System.runAs(u) {
      createTestData('Variable Units');
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      List<UpdateCoverageClaimed__e> eventList = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };
      EventPublisher event = EventPublisher.getInstance();
      Test.startTest();
      event.publish(eventList);
      Test.stopTest();
      cc = getCoverageClaimed();
      Assert.areEqual(
        200,
        cc.cve__PayableAmount__c,
        'Payable Amount not calculated correctly'
      );
      Assert.areEqual(
        20,
        cc.cve__PayableUnits__c,
        'Payable Units not calculated correctly'
      );
      Assert.areEqual(
        200,
        cc.cve__Amount__c,
        'Amount not calculated correctly'
      );
    }
  }

  @isTest
  static void testEventGenerationWithoutStatus() {
    User u = getTestUser();
    System.runAs(u) {
      Amoss_Instance mockEventPublisher = new Amoss_Instance(
        EventPublisher.class
      );
      mockEventPublisher.byDefaultMethodsReturn(
        new List<Database.SaveResult>()
      );
      EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

      BenefitCoverageClaimedSelector selector = createTestData('Amount');
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      TriggerHandler.bypass('CveClaimTriggerHandler');
      TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
      cve__Claim__c c1 = new cve__Claim__c();
      insert c1;

      cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
        cve__Claim__c = c1.id,
        cve__Period__c = 'Weekly',
        cve__Start__c = Date.newInstance(2024, 1, 1),
        cve__BenefitClaimed__c = cc.cve__BenefitClaimed__c
      );
      insert ps1;
      TriggerHandler.clearAllBypasses();
      List<UpdateCoverageClaimed__e> eventList = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };
      UpdateCoverageClaimedHelper helper = UpdateCoverageClaimedHelper.getInstance(
        selector
      );
      UpdateCoverageClaimedHandler handler = new UpdateCoverageClaimedHandler(
        helper,
        eventList,
        eventPublisherDouble
      );

      Test.startTest();
      handler.afterInsert();
      Test.stopTest();
      cc = getCoverageClaimed();
      Assert.areEqual(
        100,
        cc.cve__Amount__c,
        'Amount not calculated correctly'
      );
      Assert.areEqual(
        100,
        cc.cve__PayableAmount__c,
        'Payable Amount not calculated correctly'
      );

      List<RecalculatePaymentSpec__e> expectedResult = new List<RecalculatePaymentSpec__e>{
        new RecalculatePaymentSpec__e(
          PaymentSpecificationId__c = ps1.id,
          RecalculatePaymentRequired__c = true
        )
      };
      List<RecalculatePaymentSpec__e> actualOutcome = (List<RecalculatePaymentSpec__e>) mockEventPublisher.call(
          0
        )
        .of('publish')
        .parameter('events');

      Assert.areEqual(
        expectedResult,
        actualOutcome,
        'Events were not published as accepted'
      );
    }
  }

  @isTest
  static void testEventGenerationWithStatus() {
    User u = getTestUser();
    System.runAs(u) {
      Amoss_Instance mockEventPublisher = new Amoss_Instance(
        EventPublisher.class
      );
      mockEventPublisher.byDefaultMethodsReturn(
        new List<Database.SaveResult>()
      );
      EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

      BenefitCoverageClaimedSelector selector = createTestData('Amount');
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      TriggerHandler.bypass('CveClaimTriggerHandler');
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');
      TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
      cve__Claim__c c1 = new cve__Claim__c();
      insert c1;

      cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
        cve__Claim__c = c1.id,
        cve__Period__c = 'Weekly',
        cve__Start__c = Date.newInstance(2024, 1, 1),
        cve__BenefitClaimed__c = cc.cve__BenefitClaimed__c
      );
      insert ps1;
      cve__BenefitClaimed__c bc = new cve__BenefitClaimed__c(
        id = cc.cve__BenefitClaimed__c,
        ClaimBrainIntegrationStatus__c = 'Calculating'
      );
      update bc;
      TriggerHandler.clearAllBypasses();
      List<UpdateCoverageClaimed__e> eventList = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };
      UpdateCoverageClaimedHelper helper = UpdateCoverageClaimedHelper.getInstance(
        selector
      );
      UpdateCoverageClaimedHandler handler = new UpdateCoverageClaimedHandler(
        helper,
        eventList,
        eventPublisherDouble
      );

      Test.startTest();
      handler.afterInsert();
      Test.stopTest();
      cc = getCoverageClaimed();
      Assert.areEqual(
        100,
        cc.cve__Amount__c,
        'Amount not calculated correctly'
      );
      Assert.areEqual(
        100,
        cc.cve__PayableAmount__c,
        'Payable Amount not calculated correctly'
      );

      List<RecalculatePaymentSpec__e> expectedResult = new List<RecalculatePaymentSpec__e>{
        new RecalculatePaymentSpec__e(
          PaymentSpecificationId__c = ps1.id,
          RecalculatePaymentRequired__c = true,
          ClaimBrainCalculation__c = true
        )
      };
      List<RecalculatePaymentSpec__e> actualOutcome = (List<RecalculatePaymentSpec__e>) mockEventPublisher.call(
          0
        )
        .of('publish')
        .parameter('events');

      Assert.areEqual(
        expectedResult,
        actualOutcome,
        'Events were not published as accepted'
      );
    }
  }
}