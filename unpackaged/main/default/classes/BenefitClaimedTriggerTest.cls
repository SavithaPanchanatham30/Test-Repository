@isTest
public class BenefitClaimedTriggerTest {
  @TestSetup
  public static void setupData() {
    User u = [
      SELECT id, name, email
      FROM User
      WHERE id = :UserInfo.getUserId()
    ];

    System.runAs(u) {
      User testUser = (User) new TestUserBuilder()
        .withLastName('benefitclaimedtriggeruser')
        .buildAndInsert();

      TestUtils.assignPermissionSetsToUser(
        testUser,
        new List<String>{
          'PaymentSpecificationRollup_WRITE',
          'ClaimIncurredDate_WRITE',
          'MemberBenefit_WRITE'
        }
      );

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

      cve__Policy__c policy = new cve__Policy__c(
        Name = 'testPolicy',
        cve__Effective__c = Date.newInstance(2010, 1, 1),
        cve__Status__c = 'Active',
        cve__Product__c = product.id,
        cve__Version__c = '1'
      );
      insert policy;

      Map<String, Schema.RecordTypeInfo> bRecordTypes = cve__Benefit__c.getSObjectType()
        .getDescribe()
        .getRecordTypeInfosByName();
      Id stdRecordTypeId = bRecordTypes.get('Short Term Disability')
        .getRecordTypeId();
      Id ciRecordTypeId = bRecordTypes.get('Critical Illness')
        .getRecordTypeId();

      cve__Benefit__c stdBenefit = new cve__Benefit__c(
        cve__Product__c = product.Id,
        cve__Product__r = product,
        RecordTypeId = stdRecordTypeId,
        cve__BenefitPercentage__c = 50.00
      );

      cve__Benefit__c ciBenefit = new cve__Benefit__c(
        cve__Product__c = product.Id,
        cve__Product__r = product,
        RecordTypeId = ciRecordTypeId,
        cve__BenefitPercentage__c = 50.00
      );
      insert new List<cve__Benefit__c>{ stdBenefit, ciBenefit };

      cve__Claim__c c = new cve__Claim__c(cve__ClaimantInsured__c = con.Id);
      insert c;

      cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
        cve__Claim__c = c.id,
        cve__Period__c = 'Weekly',
        cve__Start__c = Date.newInstance(2024, 1, 1),
        cve__OverpaymentBeforeTax__c = 180.00
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

      repaymentRecordTypeId = Schema.getGlobalDescribe()
        .get('cve__Payment__c')
        .getDescribe()
        .getRecordTypeInfosByName()
        .get('Lump Sum Repayment')
        .getRecordTypeId();
      cve__Payment__c p = new cve__Payment__c(
        RecordTypeId = repaymentRecordTypeId,
        cve__UnallocatedPayment__c = up.Id,
        cve__PaymentSpecification__c = up.cve__PaymentSpecification__c,
        cve__Start__c = up.cve__Start__c,
        cve__Through__c = (null != up.cve__Through__c)
          ? up.cve__Through__c
          : up.cve__Start__c,
        cve__Payable__c = up.cve__Start__c,
        cve__Status__c = 'Processed',
        cve__NetBeforeTaxes__c = up.cve__LumpSumBeforeTaxes__c,
        cve__NetAfterTaxes__c = up.cve__LumpSum__c,
        cve__Net__c = up.cve__LumpSum__c
      );
      insert p;

      repaymentRecordTypeId = Schema.getGlobalDescribe()
        .get('cve__ExplanationOfBenefit__c')
        .getDescribe()
        .getRecordTypeInfosByName()
        .get('Explanation')
        .getRecordTypeId();
      cve__ExplanationOfBenefit__c eob = new cve__ExplanationOfBenefit__c(
        cve__Description__c = 'Lump Sum EOB',
        cve__Start__c = p.cve__Start__c,
        cve__Through__c = p.cve__Through__c,
        cve__Amount__c = p.cve__NetAfterTaxes__c,
        cve__Payment__c = p.Id,
        RecordTypeId = repaymentRecordTypeId
      );
      insert eob;
    }
  }
  @IsTest
  static void cancelBenefitClaimed() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');
      TriggerHandler.bypass('TaskTriggerHandler');
      TriggerHandler.clearAllBypasses();
      Test.startTest();
      cve__Claim__c c = [SELECT id FROM cve__Claim__c LIMIT 1];
      cve__Policy__c policy = [SELECT id FROM cve__Policy__c LIMIT 1];
      cve__Benefit__c ciBenefit = [SELECT id FROM cve__Benefit__c LIMIT 1];
      cve__BenefitClaimed__c benefitClaim = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id, //disability.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Policy__c = policy.id,
        cve__Benefit__c = ciBenefit.id, // benefit.id,
        cve__status__c = 'Pending'
      );
      insert benefitClaim;

      task tt = new task();
      tt.whatid = benefitClaim.id;
      tt.subject = 'Testing Task Created.';
      tt.priority = 'Normal';
      tt.Status = 'In Progress';
      insert tt;

      cve__BenefitClaimed__c bc = [
        SELECT id, cve__status__c
        FROM cve__BenefitClaimed__c
        LIMIT 1
      ];

      bc.cve__Status__c = 'Cancelled';
      if (bc != null)
        update bc;

      Test.stopTest();

      task t = [SELECT id, status FROM task WHERE whatid = :bc.id];
      System.assertEquals(
        t.Status,
        'Cancelled',
        'Task not canceled when BenefitClaimed canceled.'
      );
    }
  }

  @IsTest
  static void approveBenefitClaimed() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');
      TriggerHandler.bypass('TaskTriggerHandler');
      TriggerHandler.clearAllBypasses();
      Test.startTest();
      cve__Claim__c c = [SELECT id FROM cve__Claim__c LIMIT 1];
      cve__Policy__c policy = [SELECT id FROM cve__Policy__c LIMIT 1];
      cve__Benefit__c ciBenefit = [SELECT id FROM cve__Benefit__c LIMIT 1];
      cve__BenefitClaimed__c benefitClaim = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id, //disability.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Policy__c = policy.id,
        cve__Benefit__c = ciBenefit.id, // benefit.id,
        cve__status__c = 'Pending'
      );
      insert benefitClaim;

      task tt = new task();
      tt.whatid = benefitClaim.id;
      tt.subject = 'Testing Task Created.';
      tt.priority = 'Normal';
      tt.Status = 'In Progress';
      insert tt;

      cve__BenefitClaimed__c bc = [
        SELECT id, cve__status__c
        FROM cve__BenefitClaimed__c
        LIMIT 1
      ];

      bc.cve__Status__c = 'Approved';
      if (bc != null)
        update bc;

      Test.stopTest();

      task t = [SELECT id, status FROM task WHERE whatid = :bc.id];
      System.assertEquals(
        t.Status,
        'In Progress',
        'Task Should not canceled when BenefitClaimed Approved.'
      );
    }
  }

  @isTest
  static void beforeInsertBenefitClaimedAmountUpdate() {
    User testUser = getTestUser();
    testUser.Alias = 'EDI';
    update testUser;

    System.runAs(testUser) {
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');

      Contact con = [SELECT Id FROM Contact LIMIT 1];

      List<cve__BenefitClaimed__c> bcList = new List<cve__BenefitClaimed__c>();
      Map<String, Schema.RecordTypeInfo> bcRecordTypes = cve__BenefitClaimed__c.getSObjectType()
        .getDescribe()
        .getRecordTypeInfosByName();
      Id stdRecordTypeId = bcRecordTypes.get('Short Term Disability')
        .getRecordTypeId();

      cve__Claim__c c = new cve__Claim__c();
      insert c;

      cve__BenefitClaimed__c stdBc = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        RecordTypeId = stdRecordTypeId,
        cve__DateOfDisability__c = Date.newInstance(2024, 12, 25),
        cve__Policy__c = getPolicyId(),
        cve__Benefit__c = getBenefitId('Short Term Disability'),
        cve__ClaimantInsured__c = con.Id
      );
      bcList.add(stdBc);

      List<usal__MemberBenefit__c> mbList = new List<usal__MemberBenefit__c>();
      usal__MemberBenefit__c ciMb = new usal__MemberBenefit__c(
        usal__Amount__c = 1210,
        usal__StartDate__c = Date.newInstance(2023, 12, 1),
        usal__EndDate__c = Date.newInstance(2023, 12, 31),
        usal__BenefitId__c = getBenefitId('Short Term Disability'),
        usal__ContactId__c = con.Id
      );
      mbList.add(ciMb);

      usal__MemberBenefit__c stdMb = new usal__MemberBenefit__c(
        usal__Amount__c = 1225,
        usal__StartDate__c = Date.newInstance(2024, 12, 1),
        usal__EndDate__c = Date.newInstance(2024, 12, 30),
        usal__BenefitId__c = getBenefitId('Short Term Disability'),
        usal__ContactId__c = con.Id
      );
      mbList.add(stdMb);
      insert mbList;
      TriggerHandler.clearAllBypasses();

      Test.startTest();

      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        null,
        bcList,
        null,
        null,
        EventPublisher.getInstance()
      );
      handler.beforeInsert();

      Test.stopTest();

      Map<String, List<cve__BenefitClaimed__c>> bcMap = mapBCsByRecordTypeName(
        bcList
      );
      cve__BenefitClaimed__c result = bcMap.get('Short Term Disability')[0];

      Assert.areEqual(
        1225,
        result.cve__BenefitAmount__c,
        'Benefit Amount does not match with the Amount from Member Benefit'
      );
    }
  }

  @isTest
  static void beforeUpdateBenefitClaimedAmountUpdate() {
    User testUser = getTestUser();
    testUser.Alias = 'EDI';
    update testUser;

    System.runAs(testUser) {
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');

      Contact con = [SELECT Id FROM Contact LIMIT 1];

      Map<String, Schema.RecordTypeInfo> bcRecordTypes = cve__BenefitClaimed__c.getSObjectType()
        .getDescribe()
        .getRecordTypeInfosByName();
      Id ciRecordTypeId = bcRecordTypes.get('Critical Illness')
        .getRecordTypeId();

      cve__Claim__c c = new cve__Claim__c();
      c.cve__ClaimantInsured__c = con.Id;
      insert c;

      cve__BenefitClaimed__c ciBc = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        RecordTypeId = ciRecordTypeId,
        IncurredDate__c = Date.newInstance(2024, 12, 10),
        cve__Policy__c = getPolicyId(),
        cve__Benefit__c = getBenefitId('Critical Illness'),
        cve__ClaimantInsured__c = con.Id
      );
      insert ciBc;

      ciBc = [
        SELECT
          Id,
          cve__Status__c,
          IncurredDate__c,
          cve__BenefitAmount__c,
          RecordTypeId,
          cve__DateOfDisability__c,
          cve__ClaimantInsured__c,
          cve__Benefit__c
        FROM cve__BenefitClaimed__c
        WHERE RecordTypeId = :ciRecordTypeId
        LIMIT 1
      ];
      ciBc.IncurredDate__c = Date.newInstance(2024, 12, 10);

      List<usal__MemberBenefit__c> mbList = new List<usal__MemberBenefit__c>();
      usal__MemberBenefit__c ciMb = new usal__MemberBenefit__c(
        usal__Amount__c = 1210,
        usal__StartDate__c = Date.newInstance(2024, 12, 1),
        usal__EndDate__c = Date.newInstance(2024, 12, 31),
        usal__BenefitId__c = getBenefitId('Critical Illness'),
        usal__ContactId__c = con.Id
      );
      mbList.add(ciMb);

      usal__MemberBenefit__c stdMb = new usal__MemberBenefit__c(
        usal__Amount__c = 1225,
        usal__StartDate__c = Date.newInstance(2024, 12, 1),
        usal__EndDate__c = Date.newInstance(2024, 12, 31),
        usal__BenefitId__c = getBenefitId('Short Term Disability'),
        usal__ContactId__c = con.Id
      );
      mbList.add(stdMb);

      insert mbList;
      TriggerHandler.clearAllBypasses();

      Test.startTest();

      List<cve__BenefitClaimed__c> bcList = new List<cve__BenefitClaimed__c>{
        ciBc
      };
      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        null,
        bcList,
        null,
        new Map<Id, cve__BenefitClaimed__c>(bcList),
        EventPublisher.getInstance()
      );
      handler.beforeUpdate();

      Test.stopTest();

      cve__BenefitClaimed__c result = bcList[0];
      Assert.areEqual(
        1210,
        result.cve__BaseCoverageAmount__c,
        'Base Coverage Amount does not match with the Amount from Member Benefit'
      );
    }
  }

  @isTest
  public static void checkBenefitClaimedUpdate() {
    User testUser = getTestUser();

    System.runAs(testUser) {
      TriggerHandler.bypass('CoverageClaimedTriggerHandler');
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');
      cve__Claim__c c = new cve__Claim__c();
      c.cve__ClaimantInsured__c = getContactId();
      insert c;
      cve__BenefitClaimed__c benefitclaimed = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Policy__c = getPolicyId(),
        cve__Benefit__c = getBenefitId('Short Term Disability'),
        cve__ClaimantInsured__c = getContactId(),
        IncurredDate__c = System.today()
      );
      insert benefitclaimed;
      usal__MemberBenefit__c mb = new usal__MemberBenefit__c();
      mb.usal__Amount__c = 1000;
      mb.usal__BenefitId__c = getBenefitId('Short Term Disability');
      mb.usal__ContactId__c = getContactId();
      mb.usal__StartDate__c = System.today() - 1;
      mb.usal__EndDate__c = System.today() + 1;
      insert mb;

      TriggerHandler.clearAllBypasses();
      TriggerHandler.bypass('CoverageClaimedTriggerHandler');
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');
      TriggerHandler.bypass('CveClaimTriggerHandler');
      cve__Coverage__c cv = new cve__Coverage__c();
      cv.cve__Benefit__c = getBenefitId('Short Term Disability');
      insert cv;

      cve__CoverageClaimed__c cclaimed = new cve__CoverageClaimed__c();
      cclaimed.cve__BenefitClaimed__c = benefitclaimed.Id;
      cclaimed.cve__PayableAmount__c = 100;
      cclaimed.cve__Coverage__c = cv.Id;
      insert cclaimed;

      cve__CoverageClaimed__c cclaimed1 = new cve__CoverageClaimed__c();
      cclaimed1.cve__BenefitClaimed__c = benefitclaimed.Id;
      cclaimed1.cve__PayableAmount__c = 200;
      cclaimed1.cve__Coverage__c = cv.Id;
      insert cclaimed1;

      TriggerHandler.clearAllBypasses();

      Test.startTest();

      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        null,
        new List<cve__BenefitClaimed__c>{ benefitclaimed },
        null,
        new Map<Id, cve__BenefitClaimed__c>(
          new List<cve__BenefitClaimed__c>{ benefitclaimed }
        ),
        EventPublisher.getInstance()
      );
      handler.beforeUpdate();

      Test.stopTest();

      Assert.areEqual(
        300,
        benefitclaimed.cve__CoverageAmount__c,
        'Benefir claimed coverage amount not equal to sum all coverage claimed amount related to Benefit claimed'
      );

      /*    Assert.areEqual(
mb.Amount__c,
benefitclaimed.cve__BaseCoverageAmount__c,
'Base Coverage amount not equal to member benefit amount'
); */
    }
  }

  @isTest
  public static void checkBenefitClaimedInsert() {
    User testUser = getTestUser();

    System.runAs(testUser) {
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');
      cve__Claim__c c = new cve__Claim__c();
      c.cve__ClaimantInsured__c = getContactId();

      insert c;

      cve__BenefitClaimed__c benefitclaimed = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Policy__c = getPolicyId(),
        cve__Benefit__c = getBenefitId('Short Term Disability'),
        IncurredDate__c = System.today()
      );
      usal__MemberBenefit__c mb = new usal__MemberBenefit__c();
      mb.usal__Amount__c = 1000;
      mb.usal__BenefitId__c = getBenefitId('Short Term Disability');
      mb.usal__ContactId__c = benefitClaimed.cve__Claim__r.cve__ClaimantInsured__c;
      mb.usal__StartDate__c = System.today() - 1;
      mb.usal__EndDate__c = System.today() + 1;
      insert mb;

      TriggerHandler.clearAllBypasses();
      TriggerHandler.bypass('CoverageClaimedTriggerHandler');
      cve__Coverage__c cv = new cve__Coverage__c();
      cv.cve__Benefit__c = getBenefitId('Short Term Disability');
      insert cv;

      cve__Coverage__c cv1 = new cve__Coverage__c();
      cv1.cve__Benefit__c = getBenefitId('Short Term Disability');
      insert cv1;

      cve__CoverageClaimed__c cclaimed = new cve__CoverageClaimed__c();
      cclaimed.cve__BenefitClaimed__c = benefitclaimed.Id;
      cclaimed.cve__PayableAmount__c = 100;
      cclaimed.cve__Coverage__c = cv.Id;
      insert cclaimed;

      cve__CoverageClaimed__c cclaimed1 = new cve__CoverageClaimed__c();
      cclaimed1.cve__BenefitClaimed__c = benefitclaimed.Id;
      cclaimed1.cve__PayableAmount__c = 200;
      cclaimed1.cve__Coverage__c = cv1.Id;
      insert cclaimed1;

      TriggerHandler.clearAllBypasses();

      Test.startTest();

      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        null,
        new List<cve__BenefitClaimed__c>{ benefitclaimed },
        null,
        null,
        EventPublisher.getInstance()
      );
      handler.beforeInsert();

      Test.stopTest();

      // getting null coverage amount because at the time insertion coverage claimed not associated with BC
      Assert.areEqual(
        null,
        benefitclaimed.cve__CoverageAmount__c,
        'Benefir claimed coverage amount not null'
      );

      cve__Benefit__c b = [
        SELECT Id, cve__CoverageAmount__c
        FROM cve__Benefit__c
        WHERE id = :benefitclaimed.cve__Benefit__c
      ];

      Assert.areEqual(
        b.cve__CoverageAmount__c,
        benefitclaimed.cve__BaseCoverageAmount__c,
        'Base Coverage amount not equal to member benefit amount'
      );
    }
  }

  @isTest
  public static void checkBenefitClaimedUpdateforamountnull() {
    User testUser = getTestUser();

    System.runAs(testUser) {
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');
      TriggerHandler.bypass('CveClaimTriggerHandler');
      cve__Claim__c c = new cve__Claim__c();
      c.cve__ClaimantInsured__c = getContactId();
      insert c;

      cve__BenefitClaimed__c benefitclaimed = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Policy__c = getPolicyId(),
        cve__Benefit__c = getBenefitId('Short Term Disability'),
        IncurredDate__c = System.today()
      );
      insert benefitclaimed;
      usal__MemberBenefit__c mb = new usal__MemberBenefit__c();
      mb.usal__BenefitId__c = getBenefitId('Short Term Disability');
      mb.usal__ContactId__c = benefitClaimed.cve__Claim__r.cve__ClaimantInsured__c;
      mb.usal__StartDate__c = System.today() - 1;
      mb.usal__EndDate__c = System.today() + 1;
      insert mb;
      TriggerHandler.clearAllBypasses();
      TriggerHandler.bypass('CoverageClaimedTriggerHandler');
      TriggerHandler.bypass('CveClaimTriggerHandler');
      cve__Coverage__c cv = new cve__Coverage__c();
      cv.cve__Benefit__c = getBenefitId('Short Term Disability');
      insert cv;

      cve__CoverageClaimed__c cclaimed = new cve__CoverageClaimed__c();
      cclaimed.cve__BenefitClaimed__c = benefitclaimed.Id;
      cclaimed.cve__PayableAmount__c = 500;
      cclaimed.cve__Coverage__c = cv.Id;
      insert cclaimed;

      cve__CoverageClaimed__c cclaimed1 = new cve__CoverageClaimed__c();
      cclaimed1.cve__BenefitClaimed__c = benefitclaimed.Id;
      cclaimed1.cve__PayableAmount__c = 200;
      cclaimed1.cve__Coverage__c = cv.Id;
      insert cclaimed1;

      TriggerHandler.clearAllBypasses();

      Test.startTest();

      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        null,
        new List<cve__BenefitClaimed__c>{ benefitclaimed },
        null,
        new Map<Id, cve__BenefitClaimed__c>(
          new List<cve__BenefitClaimed__c>{ benefitclaimed }
        ),
        EventPublisher.getInstance()
      );
      handler.beforeUpdate();

      Test.stopTest();

      cve__Benefit__c b = [
        SELECT Id, cve__CoverageAmount__c
        FROM cve__Benefit__c
        WHERE id = :benefitclaimed.cve__Benefit__c
      ];
      Assert.areEqual(
        b.cve__CoverageAmount__c,
        benefitclaimed.cve__BaseCoverageAmount__c,
        'Base Coverage amount not equal to benefit coverage amount'
      );

      Assert.areEqual(
        700,
        benefitclaimed.cve__CoverageAmount__c,
        'Benefit claimed coverage amount not equal to sum all coverage claimed amount related to Benefit claimed'
      );
    }
  }

  /* public static id getBenefitId() {
return [SELECT id FROM cve__Benefit__c][0].id;
}*/

  public static id getBenefitId(String benefitTypeName) {
    Map<String, Schema.RecordTypeInfo> benefitRecordTypes = cve__Benefit__c.getSObjectType()
      .getDescribe()
      .getRecordTypeInfosByName();
    return [
      SELECT Id
      FROM cve__Benefit__c
      WHERE
        RecordTypeId = :benefitRecordTypes.get(benefitTypeName)
          .getRecordTypeId()
    ]
    .Id;
  }

  public static cve__UnallocatedPayment__c getUnallocatedPayment() {
    return [
      SELECT id, cve__PaymentSpecification__c, cve__LumpSum__c
      FROM cve__UnallocatedPayment__c
    ];
  }

  public static id getPolicyId() {
    return [SELECT id FROM cve__Policy__c][0].id;
  }

  public static id getContactId() {
    return [SELECT id FROM Contact][0].id;
  }

  static User getTestUser() {
    return [
      SELECT Id
      FROM User
      WHERE LastName = 'benefitclaimedtriggeruser'
      LIMIT 1
    ];
  }
  static Map<String, List<cve__BenefitClaimed__c>> mapBCsByRecordTypeName(
    List<cve__BenefitClaimed__c> bcList
  ) {
    Map<String, List<cve__BenefitClaimed__c>> bcMap = new Map<String, List<cve__BenefitClaimed__c>>();
    Map<Id, Schema.RecordTypeInfo> recordTypeIds = cve__BenefitClaimed__c.getSObjectType()
      .getDescribe()
      .getRecordTypeInfosById();
    for (cve__BenefitClaimed__c bc : bcList) {
      String recordTypeName = recordTypeIds.get(bc.RecordTypeId).name;
      if (bcMap.get(recordTypeIds.get(bc.RecordTypeId).name) == null) {
        bcMap.put(recordTypeName, new List<cve__BenefitClaimed__c>{ bc });
      } else {
        bcMap.get(recordTypeName).add(bc);
      }
    }
    return bcMap;
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
  static void submitAndProcessApprovalRequest() {
    TriggerHandler.bypass('CveClaimTriggerHandler');
    TriggerHandler.bypass('BenefitClaimedTriggerHandler');
    cve__Claim__c c = new cve__Claim__c();
    c.cve__ClaimantInsured__c = getContactId();
    insert c;

    cve__BenefitClaimed__c benefitclaimed = new cve__BenefitClaimed__c(
      cve__Claim__c = c.id,
      cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
      cve__Policy__c = getPolicyId(),
      cve__Benefit__c = getBenefitId('Short Term Disability'),
      IncurredDate__c = System.today()
    );
    insert benefitclaimed;
    TriggerHandler.clearAllBypasses();

    Test.startTest();
    User testUser = getTestUser();

    // Create an approval request for the benefit claimed
    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
    req1.setProcessDefinitionNameOrId('Benefit_Claimed_Approval_Process');
    req1.setComments('Submitting request for approval.');
    req1.setObjectId(benefitclaimed.id);

    // Submit on behalf of a specific submitter
    req1.setSubmitterId(testUser.Id);

    // Skip the criteria evaluation for the specified process
    req1.setSkipEntryCriteria(true);
    req1.setNextApproverIds(new List<Id>{ UserInfo.getUserId() });

    // Submit the approval request for the account
    Approval.ProcessResult result = Approval.process(req1);

    // Verify the result
    System.assert(result.isSuccess(), true);

    System.assertEquals(
      'Pending',
      result.getInstanceStatus(),
      'Instance Status' + result.getInstanceStatus()
    );

    // Approve the submitted request
    // First, get the ID of the newly created item
    List<Id> newWorkItemIds = result.getNewWorkitemIds();

    // Instantiate the new ProcessWorkitemRequest object and populate it
    Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
    req2.setComments('Rejecting request.');
    req2.setAction('Reject');
    req2.setNextApproverIds(new List<Id>{ UserInfo.getUserId() });

    // Use the ID from the newly created item to specify the item to be worked
    req2.setWorkitemId(newWorkItemIds.get(0));

    // Submit the request for approval
    Approval.ProcessResult result2 = Approval.process(req2);

    Test.stopTest();

    // Verify the results
    System.assert(result2.isSuccess(), 'Result Status:' + result2.isSuccess());

    System.assertEquals(
      'Rejected',
      result2.getInstanceStatus(),
      'Instance Status' + result2.getInstanceStatus()
    );
  }
  @isTest
  static void bcInitialAndFinalTAT() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      TriggerHandler.bypass('CveClaimTriggerHandler');
      cve__Claim__c c = [SELECT id FROM cve__Claim__c LIMIT 1];
      cve__Policy__c policy = [SELECT id FROM cve__Policy__c LIMIT 1];
      cve__Benefit__c ciBenefit = [SELECT id FROM cve__Benefit__c LIMIT 1];
      cve__BenefitClaimed__c benefitClaim = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Policy__c = policy.id,
        cve__Benefit__c = ciBenefit.id,
        cve__status__c = 'Open'
      );
      insert benefitClaim;

      Map<Id, cve__BenefitClaimed__c> oldMap = new Map<Id, cve__BenefitClaimed__c>(
        new List<cve__BenefitClaimed__c>{ benefitClaim }
      );
      benefitClaim.cve__Status__c = 'Approved';
      update benefitClaim;
      Map<Id, cve__BenefitClaimed__c> newMap = new Map<Id, cve__BenefitClaimed__c>(
        new List<cve__BenefitClaimed__c>{ benefitClaim }
      );
      TriggerHandler.clearAllBypasses();

      test.startTest();
      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        null,
        new List<cve__BenefitClaimed__c>{ benefitClaim },
        oldMap,
        newMap,
        EventPublisher.getInstance()
      );
      handler.afterUpdate();
      test.stopTest();

      cve__Claim__c result = [
        SELECT Id, BCInitialDecisionDate__c, BCFinalDecisionDate__c
        FROM cve__Claim__c
        LIMIT 1
      ];

      Assert.areEqual(
        system.today(),
        result.BCInitialDecisionDate__c,
        'Initial Decision date was not populated correctly'
      );
      Assert.areEqual(
        system.today(),
        result.BCFinalDecisionDate__c,
        'Final Decision date was not populated correctly'
      );
    }
  }

  @isTest
  static void bcInitialTAT() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      TriggerHandler.bypass('CveClaimTriggerHandler');
      cve__Claim__c c = [SELECT id FROM cve__Claim__c LIMIT 1];
      cve__Policy__c policy = [SELECT id FROM cve__Policy__c LIMIT 1];
      cve__Benefit__c ciBenefit = [SELECT id FROM cve__Benefit__c LIMIT 1];
      cve__BenefitClaimed__c benefitClaim = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Policy__c = policy.id,
        cve__Benefit__c = ciBenefit.id,
        cve__status__c = 'Pending'
      );
      insert benefitClaim;
      Map<Id, cve__BenefitClaimed__c> oldMap = new Map<Id, cve__BenefitClaimed__c>(
        new List<cve__BenefitClaimed__c>{ benefitClaim }
      );

      benefitClaim.cve__Status__c = 'Suspended';
      update benefitClaim;

      Map<Id, cve__BenefitClaimed__c> newMap = new Map<Id, cve__BenefitClaimed__c>(
        new List<cve__BenefitClaimed__c>{ benefitClaim }
      );
      TriggerHandler.clearAllBypasses();

      test.startTest();
      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        null,
        new List<cve__BenefitClaimed__c>{ benefitClaim },
        oldMap,
        newMap,
        EventPublisher.getInstance()
      );
      handler.afterUpdate();
      test.stopTest();

      cve__Claim__c result = [
        SELECT Id, BCInitialDecisionDate__c
        FROM cve__Claim__c
        LIMIT 1
      ];
      Assert.areEqual(
        system.today(),
        result.BCInitialDecisionDate__c,
        'Initial Decision date was not populated correctly'
      );
    }
  }
  @isTest
  static void bcFinalDecisionTAT() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      TriggerHandler.bypass('CveClaimTriggerHandler');

      cve__Claim__c c = [SELECT id FROM cve__Claim__c LIMIT 1];
      c.FinalStatusChangedDate__c = null;
      update c;
      cve__Policy__c policy = [SELECT id FROM cve__Policy__c LIMIT 1];
      cve__Benefit__c ciBenefit = [SELECT id FROM cve__Benefit__c LIMIT 1];
      cve__BenefitClaimed__c benefitClaim = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        cve__Policy__c = policy.id,
        cve__Benefit__c = ciBenefit.id,
        cve__status__c = 'Suspended'
      );
      insert benefitClaim;
      Map<Id, cve__BenefitClaimed__c> oldMap = new Map<Id, cve__BenefitClaimed__c>(
        new List<cve__BenefitClaimed__c>{ benefitClaim }
      );

      benefitClaim.cve__Status__c = 'Approved';
      update benefitClaim;

      Map<Id, cve__BenefitClaimed__c> newMap = new Map<Id, cve__BenefitClaimed__c>(
        new List<cve__BenefitClaimed__c>{ benefitClaim }
      );
      TriggerHandler.clearAllBypasses();

      test.startTest();
      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        null,
        new List<cve__BenefitClaimed__c>{ benefitClaim },
        oldMap,
        newMap,
        EventPublisher.getInstance()
      );
      handler.afterUpdate();
      test.stopTest();

      cve__Claim__c result = [
        SELECT Id, cve__Status__c, BCFinalDecisionDate__c
        FROM cve__Claim__c
        LIMIT 1
      ];

      Assert.areEqual(
        system.today(),
        result.BCFinalDecisionDate__c,
        'Final Decision date was not populated correctly'
      );
    }
  }

  @isTest
  static void testBenefitClaimedWhenDenied() {
    Contact con = [SELECT id FROM Contact];
    User testUser = getTestUser();
    System.runAs(testUser) {
      TriggerHandler.bypass('CveClaimTriggerHandler');
      TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
      TriggerHandler.bypass('AdjustmentTriggerHandler');
      TriggerHandler.bypass('BenefitClaimedTriggerHandler');
      cve__Claim__c c = new cve__Claim__c(cve__ClaimantInsured__c = con.Id);
      insert c;

      cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
        cve__Claim__c = c.id,
        cve__Period__c = 'Weekly',
        cve__Start__c = Date.newInstance(2024, 1, 1)
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

      cve__Claim__c c1 = new cve__Claim__c(cve__ClaimantInsured__c = con.Id);
      insert c1;

      cve__Policy__c policy = [SELECT id FROM cve__Policy__c LIMIT 1];
      cve__Benefit__c ciBenefit = [SELECT id FROM cve__Benefit__c LIMIT 1];
      cve__BenefitClaimed__c benefitClaim = new cve__BenefitClaimed__c(
        cve__Claim__c = c1.id,
        cve__Policy__c = policy.id,
        cve__Benefit__c = ciBenefit.id,
        cve__status__c = 'Pending',
        cve__BenefitStart__c = Date.newInstance(2024, 1, 1),
        cve__BenefitThrough__c = Date.newInstance(2024, 1, 1)
      );
      insert benefitClaim;

      cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
        cve__BenefitClaimed__c = benefitClaim.id,
        cve__Claim__c = c1.id,
        cve__Period__c = 'Weekly',
        cve__Start__c = Date.newInstance(2024, 1, 1)
      );
      insert ps1;

      cve__Adjustment__c adj = new cve__Adjustment__c(
        cve__Amount__c = 100,
        cve__Period__c = 'Weekly',
        cve__Type__c = 'Recoup Overpayment (Pre-Tax)',
        UnallocatedPayment__c = up.id,
        cve__PaymentSpecification__c = ps1.id,
        PriorPaymentSpecs__c = ps.id
      );
      insert adj;

      cve__BenefitClaimed__c oldBc = [
        SELECT id, cve__Status__c, cve__BenefitStart__c, cve__BenefitThrough__c
        FROM cve__BenefitClaimed__c
        WHERE id = :benefitClaim.id
      ];
      benefitClaim.cve__Status__c = 'Denied';

      TriggerHandler.clearAllBypasses();

      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        new List<cve__BenefitClaimed__c>{ oldBc },
        new List<cve__BenefitClaimed__c>{ benefitClaim },
        new Map<Id, cve__BenefitClaimed__c>{ oldBc.id => oldBc },
        new Map<Id, cve__BenefitClaimed__c>{ benefitClaim.id => benefitClaim },
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
  }
  @isTest
  static void statusWhenPendingOrSuspended() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      TriggerHandler.bypass('CveClaimTriggerHandler');
      cve__Claim__c c = [SELECT id FROM cve__Claim__c LIMIT 1];
      cve__Policy__c policy = [SELECT id FROM cve__Policy__c LIMIT 1];
      cve__Benefit__c ciBenefit = [SELECT id FROM cve__Benefit__c LIMIT 1];
      cve__BenefitClaimed__c benefitClaim = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Policy__c = policy.id,
        cve__Benefit__c = ciBenefit.id,
        cve__status__c = 'Pending'
      );
      insert benefitClaim;

      Map<Id, cve__BenefitClaimed__c> oldMap = new Map<Id, cve__BenefitClaimed__c>(
        new List<cve__BenefitClaimed__c>{ benefitClaim }
      );

      benefitClaim.cve__Status__c = 'Suspended';
      update benefitClaim;

      Map<Id, cve__BenefitClaimed__c> newMap = new Map<Id, cve__BenefitClaimed__c>(
        new List<cve__BenefitClaimed__c>{ benefitClaim }
      );
      TriggerHandler.clearAllBypasses();

      test.startTest();
      BenefitClaimedTriggerHandler handler = new BenefitClaimedTriggerHandler(
        BenefitClaimedTriggerHelper.getInstance(),
        null,
        new List<cve__BenefitClaimed__c>{ benefitClaim },
        oldMap,
        newMap,
        EventPublisher.getInstance()
      );
      handler.afterUpdate();
      test.stopTest();

      cve__BenefitClaimed__c result = [
        SELECT Id, cve__StatusReason__c
        FROM cve__BenefitClaimed__c
        LIMIT 1
      ];
      Assert.areEqual(
        'Additional Information Needed',
        result.cve__StatusReason__c,
        'Status reason not change successfully.'
      );
    }

  }
}