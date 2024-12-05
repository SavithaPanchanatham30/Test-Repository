@isTest
public class CoverageClaimedTriggerTest {
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

    cve__Product__c product = new cve__Product__c(
      Name = 'testProduct',
      cve__Status__c = 'Active',
      cve__Effective__c = Date.newInstance(2010, 1, 1)
    );
    insert product;

    cve__Benefit__c benefit = new cve__Benefit__c(
      cve__CoverageAmount__c = 100,
      cve__BenefitPercentage__c = 100,
      cve__CoverageType__c = 'Amount',
      cve__Product__c = product.id
    );
    insert benefit;

    cve__Coverage__c per = (cve__Coverage__c) new TestCoverageBuilder()
      .withAmount(100)
      .withBenefitId(benefit.id)
      .buildAndInsert();

    new TestCoverageBuilder()
      .withPercentageOf(per.id)
      .withPercentage(100)
      .withAmountPerUnit(100)
      .withAmount(100)
      .withBenefitId(benefit.id)
      .buildAndInsert();

    cve__Claim__c c = new cve__Claim__c();
    insert c;

    TriggerHandler.bypass('BenefitClaimedTriggerHandler');
    cve__BenefitClaimed__c bc = new cve__BenefitClaimed__c(
      cve__Claim__c = c.id,
      cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
      cve__Benefit__c = benefit.id
    );
    insert bc;
    TriggerHandler.clearBypass('BenefitClaimedTriggerHandler');
  }

  static void createTestData(String coverageType) {
    Id recordID = Schema.getGlobalDescribe()
      .get('cve__Coverage__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get(coverageType)
      .getRecordTypeId();
    cve__Coverage__c cov = getCoverage();
    cov.RecordTypeId = recordID;
    update cov;

    TriggerHandler.bypass('CoverageClaimedTriggerHandler');
    new TestCoverageClaimedBuilder()
      .withAmount(0)
      .withBenefitClaimed(getBenefitClaimed())
      .withUnits(20)
      .withCoverage(getCoverage())
      .withPayableUnits(2)
      .withPayableAmount(10)
      .buildAndInsert();
    TriggerHandler.clearAllBypasses();
  }

  private static cve__BenefitClaimed__c getBenefitCoverageClaimed(
    Id benefitId
  ) {
    return [
      SELECT
        Id,
        Name,
        CreatedById,
        cve__BaseCoverageAmount__c,
        cve__Benefit__c,
        IncurredDate__c,
        cve__DateOfDisability__c,
        cve__Benefit__r.cve__CoverageAmount__c,
        cve__Claim__c,
        cve__Claim__r.IncurredDate__c,
        cve__Claim__r.cve__ClaimantInsured__c,
        cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
        cve__Claim__r.cve__PolicyRelationship__r.cve__Policy__c,
        cve__ClaimantInsured__c,
        cve__ClaimantInsuredAccount__c,
        cve__ClaimantInsuredName__c,
        cve__CoverageAmount__c,
        cve__CoverageAmountRemaining__c,
        cve__CriticalBurnMaximum__c,
        cve__CurrentAccountValue__c,
        cve__FeloniousAssaultMaximum__c,
        cve__FirstNotified__c,
        cve__HasReinsurance__c,
        cve__Hemiplegia__c,
        cve__HigherEducationMaximum__c,
        cve__IncurredBeforeTax__c,
        cve__Policy__c,
        RecordTypeId,
        (
          SELECT
            Id,
            Name,
            cve__BenefitClaimed__c,
            cve__BenefitName__c,
            cve__ClaimId__c,
            cve__Amount__c,
            cve__Units__c,
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
          FROM cve__CoveragesClaimed__r
        )
      FROM cve__BenefitClaimed__c
      WHERE Id = :benefitId
    ];
  }

  @isTest
  static void testIfCoverageTypeIsAmount() {
    User u = getTestUser();
    System.runAs(u) {
      createTestData('Amount');
      cve__CoverageClaimed__c cc = getCoverageClaimed();
      Amoss_Instance mockEventPublisher = new Amoss_Instance(
        EventPublisher.class
      );
      mockEventPublisher.byDefaultMethodsReturn(
        new List<Database.SaveResult>()
      );
      EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();
      CoverageClaimedTriggerHandler.ContextVariable cv = new CoverageClaimedTriggerHandler.ContextVariable(
        null,
        new List<cve__CoverageClaimed__c>{ cc },
        null,
        null
      );
      CoverageClaimedTriggerHandler handler = new CoverageClaimedTriggerHandler(
        CoverageClaimedTriggerHelper.getInstance(),
        cv,
        eventPublisherDouble
      );

      Test.startTest();
      handler.afterUpdate();
      Test.stopTest();

      List<UpdateCoverageClaimed__e> expectedResult = new List<UpdateCoverageClaimed__e>{
        new UpdateCoverageClaimed__e(CoverageClaimedId__c = cc.id)
      };

      List<UpdateCoverageClaimed__e> actualOutcome = (List<UpdateCoverageClaimed__e>) mockEventPublisher.call(
          0
        )
        .of('publish')
        .parameter('events');

      Assert.areEqual(
        expectedResult,
        actualOutcome,
        'Published AdditionalIncomeOffset__e does not match expected UpdateCoverageClaimed__e'
      );
    }
  }

  static cve__BenefitClaimed__c getBenefitClaimed() {
    return [
      SELECT id, cve__benefit__r.cve__CoverageAmount__c, RecordTypeId
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
      WHERE cve__AmountPerUnit__c = 100
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
}