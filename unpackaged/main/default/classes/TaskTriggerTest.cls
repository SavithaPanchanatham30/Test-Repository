@isTest
public class TaskTriggerTest {
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
      Id ciRecordTypeId = bRecordTypes.get('Critical Illness')
        .getRecordTypeId();
      Id stdbRecordTypeId = bRecordTypes.get('Short Term Disability')
        .getRecordTypeId();

      cve__Benefit__c ciBenefit = new cve__Benefit__c(
        cve__Product__c = product.Id,
        cve__Product__r = product,
        RecordTypeId = stdbRecordTypeId,
        cve__BenefitPercentage__c = 50.00
      );
      insert ciBenefit;

      cve__Benefit__c ciBenefit1 = new cve__Benefit__c(
        cve__Product__c = product.Id,
        cve__Product__r = product,
        RecordTypeId = ciRecordTypeId,
        cve__BenefitPercentage__c = 50.00
      );
      insert ciBenefit1;
      cve__Claim__c c = new cve__Claim__c();
      insert c;

      Map<String, Schema.RecordTypeInfo> bRecordType1s = cve__BenefitClaimed__c.getSObjectType()
        .getDescribe()
        .getRecordTypeInfosByName();
      Id ciRecordType = bRecordType1s.get('Critical Illness').getRecordTypeId();
      cve__BenefitClaimed__c benefitclaimed = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Benefit__c = getBenefitId('Critical Illness'),
        RecordTypeId = ciRecordType,
        IncurredDate__c = System.today()
      );
      insert benefitclaimed;

      cve__BenefitClaimed__c benefitclaimed1 = new cve__BenefitClaimed__c(
        cve__Claim__c = c.id,
        cve__DateOfDisability__c = Date.newInstance(2024, 1, 1),
        cve__Benefit__c = getBenefitId('Short Term Disability'),
        RecordTypeId = bRecordType1s.get('Short Term Disability')
          .getRecordTypeId(),
        IncurredDate__c = System.today()
      );
      insert benefitclaimed1;
    }
  }

  @isTest
  public static void checkTaskInsert() {
    User testUser = getTestUser();

    System.runAs(testUser) {
      cve__BenefitClaimed__c bc = [
        SELECT Id
        FROM cve__BenefitClaimed__c
        WHERE cve__RecordTypeName__c = 'CriticalIllness'
      ];

      TriggerHandler.bypass('TaskTriggerHandler');
      Task tsk = new Task();
      tsk.Subject = 'Requesting to review Benefit Claimed';
      tsk.Status = 'Open';
      tsk.Priority = 'Normal';
      tsk.WhatId = bc.ID;
      tsk.OwnerId = testUser.Id;
      insert tsk;

      TriggerHandler.clearAllBypasses();

      Test.startTest();

      TaskTriggerHandler handler = new TaskTriggerHandler(
        TaskTriggerHelper.getHelperInstance(),
        new List<Task>{ tsk }
      );
      handler.beforeInsert();
      Test.stopTest();
      TaskTriggerHelper t = new TaskTriggerHelper();
      Id id = t.getQueueId('Supplemental Claims Review');
      Assert.areEqual(id, tsk.OwnerId, 'Ids not matching');
    }
  }

  @isTest
  public static void checkTaskTrigger() {
    User testUser = getTestUser();

    System.runAs(testUser) {
      cve__BenefitClaimed__c bc = [
        SELECT Id
        FROM cve__BenefitClaimed__c
        WHERE cve__RecordTypeName__c != 'CriticalIllness'
      ];

      Task tsk = new Task();
      tsk.Subject = 'Requesting to review Benefit Claimed';
      tsk.Status = 'Open';
      tsk.Priority = 'Normal';
      tsk.WhatId = bc.ID;
      tsk.OwnerId = testUser.Id;

      Boolean errorsEncountered = false;
      Test.StartTest();
      try {
        insert tsk;
      } catch (Exception e) {
        errorsEncountered = true;
      }
      Test.StopTest();
      Assert.isFalse(
        errorsEncountered,
        'Error encountered during Trigger operation'
      );
    }
  }
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
  static User getTestUser() {
    return [
      SELECT Id
      FROM User
      WHERE LastName = 'benefitclaimedtriggeruser'
      LIMIT 1
    ];
  }
  public static id getPolicyId() {
    return [SELECT id FROM cve__Policy__c][0].id;
  }
}