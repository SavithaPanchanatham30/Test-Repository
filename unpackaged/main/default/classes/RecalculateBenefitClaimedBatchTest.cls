@isTest
public class RecalculateBenefitClaimedBatchTest {
  @testSetup
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
      cve__Benefit__c = benefit.id,
      cve__CoverageAmount__c = 10,
      ClaimBrainIntegrationStatus__c = 'Complete'
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
      .withPayableAmount(100)
      .buildAndInsert();
    TriggerHandler.clearAllBypasses();
  }

  static cve__BenefitClaimed__c getBenefitClaimed() {
    return [
      SELECT
        id,
        cve__benefit__r.cve__CoverageAmount__c,
        RecordTypeId,
        cve__CoverageAmount__c
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

  @isTest
  static void testBatchJob() {
    User u = getTestUser();
    System.runAs(u) {
      createTestData('Amount');

      RecalculateBenefitClaimedBatch job = new RecalculateBenefitClaimedBatch();
      Test.startTest();
      Database.executeBatch(job);
      Test.stopTest();

      cve__BenefitClaimed__c bc = getBenefitClaimed();

      Assert.areEqual(
        100,
        bc.cve__CoverageAmount__c,
        'Coverage Amount was not calculated properly'
      );
    }
  }

  // purpose of this test is to provide code coverage to CoverageAmountCorrectionHandler
  @isTest
  static void testPlatformEvent() {
    User u = getTestUser();
    System.runAs(u) {
      createTestData('Amount');
      Test.startTest();
      CoverageAmountCorrection__e event = new CoverageAmountCorrection__e();
      EventPublisher pub = EventPublisher.getInstance();
      List<Database.SaveResult> result = pub.publish(
        new List<CoverageAmountCorrection__e>{ event }
      );
      Test.stopTest();
      Assert.areEqual(
        false,
        checkForErrors(result),
        'Event was not published successfully'
      );
    }
  }

  private static Boolean checkForErrors(List<Database.SaveResult> results) {
    for (Database.SaveResult result : results) {
      if (!result.isSuccess()) {
        return true;
      }
    }
    return false;
  }
}