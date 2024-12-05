@isTest
public class HandlePaymentApprovalTest {
  @TestSetup
  static void makeData() {
    User currentUser = [
      SELECT id, name, email
      FROM User
      WHERE id = :UserInfo.getUserId()
    ];
    System.runAs(currentUser) {
      List<String> psNames = new List<String>{
        'ExpressPay_WRITE',
        'AutoPay_WRITE'
      };

      User testUser = (User) new TestUserBuilder()
        .withLastName('PaymentApproval')
        .withAbsenceLOARole('Absence Examiner 1')
        .withDisabilityLOARole('Group Disability Claims Examiner 1')
        .withSupplementalLOARole('Supplemental Claims Examiner 1')
        .buildAndInsert();

      User testUser2 = (User) new TestUserBuilder()
        .withLastName('PaymentApprovalWithoutRoles')
        .withAbsenceLOARole('')
        .withDisabilityLOARole('')
        .withSupplementalLOARole('')
        .buildAndInsert();

      TestUtils.assignPermissionSetsToUser(testUser, psNames);
      TestUtils.assignPermissionSetsToUser(testUser2, psNames);
    }

    cvab__Claim__c absenceClaim = new cvab__Claim__c();
    insert absenceClaim;
    cve__Claim__c disabilityClaim = new cve__Claim__c();
    insert disabilityClaim;
  }

  static User getUserWithRole() {
    return [
      SELECT
        id,
        AbsenceClaimsLOARole__c,
        DisabilityClaimsLOARole__c,
        SupplementalClaimsLOARole__c
      FROM User
      WHERE LastName = 'PaymentApproval'
    ];
  }

  static User getUserWithoutRole() {
    return [
      SELECT
        id,
        AbsenceClaimsLOARole__c,
        DisabilityClaimsLOARole__c,
        SupplementalClaimsLOARole__c
      FROM User
      WHERE LastName = 'PaymentApprovalWithoutRoles'
    ];
  }

  static cvab__Claim__c getCvabClaim() {
    return [SELECT id FROM cvab__Claim__c];
  }

  static cve__Claim__c getCveClaim() {
    return [SELECT id FROM cve__Claim__c];
  }

  static List<cve__Payment__c> createTestData(
    String psType,
    Decimal amount,
    Boolean isCveClaim
  ) {
    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;
    cve__Claim__c cveClaim = new cve__Claim__c();
    insert cveClaim;
    Id typeID = Schema.getGlobalDescribe()
      .get('cve__PaymentSpecification__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get(psType)
      .getRecordTypeId();
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      RecordTypeId = typeId,
      cvint__AbsenceClaim__c = !isCveClaim ? cvabClaim.id : null,
      cve__Claim__c = isCveClaim ? cveClaim.id : null
    );
    insert ps;
    typeID = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Calculated')
      .getRecordTypeId();
    cve__Payment__c pay1 = new cve__Payment__c(
      cve__Start__c = Date.newInstance(2024, 1, 1),
      cve__Through__c = Date.newInstance(2024, 1, 7),
      RecordTypeId = typeId,
      cve__Net__c = amount,
      cve__PaymentSpecification__c = ps.id,
      cve__Status__c = 'Pending'
    );
    insert pay1;
    cve__Payment__c pay2 = new cve__Payment__c(
      cve__Start__c = Date.newInstance(2024, 1, 8),
      cve__Through__c = Date.newInstance(2024, 1, 15),
      RecordTypeId = typeId,
      cve__Net__c = amount,
      cve__PaymentSpecification__c = ps.id,
      cve__Status__c = 'Pending'
    );
    insert pay2;
    return new List<cve__Payment__c>{ pay1, pay2 };
  }

  static List<cve__PaymentSpecification__c> createTestDataForPaymentStatusCheck() {
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    cve__Claim__c c = new cve__Claim__c();
    insert c;
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cve__Claim__c = c.id,
      PaymentApprovalStatus__c = 'Submitted for Approval'
    );
    insert ps;
    Id typeID = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Calculated')
      .getRecordTypeId();
    cve__Payment__c pay1 = new cve__Payment__c(
      cve__Start__c = Date.newInstance(2022, 1, 1),
      cve__Through__c = Date.newInstance(2022, 1, 7),
      RecordTypeId = typeId,
      cve__Net__c = 180.00,
      cve__PaymentSpecification__c = ps.id,
      cve__Status__c = 'Pending'
    );
    insert pay1;
    TriggerHandler.clearAllBypasses();

    return new List<cve__PaymentSpecification__c>{ ps };
  }

  @isTest
  static void testAbsencePayment() {
    User testUser = getUserWithRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData('Generic', 100, false);
      List<cve__Payment__c> newList = [
        SELECT
          id,
          RecordTypeId,
          cve__Net__c,
          cve__Through__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Approved',
        newList[0].cve__Status__c,
        'Status is not approved'
      );
      Assert.areEqual(
        'Approved',
        newList[1].cve__Status__c,
        'Status is not approved'
      );
    }
  }

  @isTest
  static void testSupplementalAccidentPayment() {
    User testUser = getUserWithRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData('Accident', 100, true);
      List<cve__Payment__c> newList = [
        SELECT
          id,
          cve__Start__c,
          cve__Through__c,
          RecordTypeId,
          cve__Net__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Approved',
        newList[0].cve__Status__c,
        'Status is not approved'
      );
      Assert.areEqual(
        'Approved',
        newList[1].cve__Status__c,
        'Status is not approved'
      );
    }
  }

  @isTest
  static void testSupplementalCriticalPayment() {
    User testUser = getUserWithRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData(
        'Critical Illness',
        100,
        true
      );
      List<cve__Payment__c> newList = [
        SELECT
          id,
          cve__Start__c,
          cve__Through__c,
          RecordTypeId,
          cve__Net__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Approved',
        newList[0].cve__Status__c,
        'Status is not approved'
      );
      Assert.areEqual(
        'Approved',
        newList[1].cve__Status__c,
        'Status is not approved'
      );
    }
  }

  @isTest
  static void testDisabilityPayment() {
    User testUser = getUserWithRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData(
        'Short Term Disability',
        100,
        true
      );
      List<cve__Payment__c> newList = [
        SELECT
          id,
          cve__Start__c,
          cve__Through__c,
          RecordTypeId,
          cve__Net__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Approved',
        newList[0].cve__Status__c,
        'Status is not approved'
      );
      Assert.areEqual(
        'Approved',
        newList[1].cve__Status__c,
        'Status is not approved'
      );
    }
  }

  @isTest
  static void testAbsencePaymentWithGreaterAmount() {
    User testUser = getUserWithRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData(
        'Short Term Disability',
        900,
        false
      );
      List<cve__Payment__c> newList = [
        SELECT
          id,
          RecordTypeId,
          cve__Net__c,
          cve__Through__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Submitted for Approval',
        newList[0].cve__Status__c,
        'Status is not Submitted for Approval'
      );
      Assert.areEqual(
        'Submitted for Approval',
        newList[1].cve__Status__c,
        'Status is not Submitted for Approval'
      );
    }
  }

  @isTest
  static void testSupplementalAccidentPaymentWithGreaterAmount() {
    User testUser = getUserWithRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData('Accident', 6000, true);
      List<cve__Payment__c> newList = [
        SELECT
          id,
          cve__Start__c,
          cve__Through__c,
          RecordTypeId,
          cve__Net__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Submitted for Approval',
        newList[0].cve__Status__c,
        'Status is not Submitted for Approval'
      );
      Assert.areEqual(
        'Submitted for Approval',
        newList[1].cve__Status__c,
        'Status is not Submitted for Approval'
      );
    }
  }

  @isTest
  static void testSupplementalCriticalPaymentWithGreaterAmount() {
    User testUser = getUserWithRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData(
        'Critical Illness',
        6000,
        true
      );
      List<cve__Payment__c> newList = [
        SELECT
          id,
          cve__Start__c,
          cve__Through__c,
          RecordTypeId,
          cve__Net__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Submitted for Approval',
        newList[0].cve__Status__c,
        'Status is not Submitted for Approval'
      );
      Assert.areEqual(
        'Submitted for Approval',
        newList[1].cve__Status__c,
        'Status is not Submitted for Approval'
      );
    }
  }

  @isTest
  static void testDisabilityPaymentWithGreaterAmount() {
    User testUser = getUserWithRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData(
        'Short Term Disability',
        900,
        true
      );
      List<cve__Payment__c> newList = [
        SELECT
          id,
          cve__Start__c,
          cve__Through__c,
          RecordTypeId,
          cve__Net__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Submitted for Approval',
        newList[0].cve__Status__c,
        'Status is not Submitted for Approval'
      );
      Assert.areEqual(
        'Submitted for Approval',
        newList[1].cve__Status__c,
        'Status is not Submitted for Approval'
      );
    }
  }

  @isTest
  static void testAbsencePaymentWithoutUserRole() {
    User testUser = getUserWithoutRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData('Generic', 900, false);
      List<cve__Payment__c> newList = [
        SELECT
          id,
          RecordTypeId,
          cve__Net__c,
          cve__Through__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Submitted for Approval',
        newList[0].cve__Status__c,
        'Status is not Submitted for Approval'
      );
      Assert.areEqual(
        'Submitted for Approval',
        newList[1].cve__Status__c,
        'Status is not Submitted for Approval'
      );
    }
  }

  @isTest
  static void testSupplementalAccidentPaymentWithoutUserRole() {
    User testUser = getUserWithoutRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData('Accident', 900, true);
      List<cve__Payment__c> newList = [
        SELECT
          id,
          cve__Start__c,
          cve__Through__c,
          RecordTypeId,
          cve__Net__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Submitted for Approval',
        newList[0].cve__Status__c,
        'Status is not Submitted for Approval'
      );
      Assert.areEqual(
        'Submitted for Approval',
        newList[1].cve__Status__c,
        'Status is not Submitted for Approval'
      );
    }
  }

  @isTest
  static void testSupplementalCriticalPaymentWithoutUserRole() {
    User testUser = getUserWithoutRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData(
        'Critical Illness',
        900,
        true
      );
      List<cve__Payment__c> newList = [
        SELECT
          id,
          cve__Start__c,
          cve__Through__c,
          RecordTypeId,
          cve__Net__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Submitted for Approval',
        newList[0].cve__Status__c,
        'Status is not Submitted for Approval'
      );
      Assert.areEqual(
        'Submitted for Approval',
        newList[1].cve__Status__c,
        'Status is not Submitted for Approval'
      );
    }
  }

  @isTest
  static void testDisabilityPaymentWithoutUserRole() {
    User testUser = getUserWithoutRole();
    System.runAs(testUser) {
      List<cve__Payment__c> oldList = createTestData(
        'Short Term Disability',
        900,
        true
      );
      List<cve__Payment__c> newList = [
        SELECT
          id,
          cve__Start__c,
          cve__Through__c,
          RecordTypeId,
          cve__Net__c,
          cve__PaymentSpecification__c,
          cve__Status__c,
          cve__Contact__c,
          cve__Account__c
        FROM cve__Payment__c
      ];
      for (cve__Payment__c pay : newList) {
        pay.cve__Status__c = 'Approved';
      }

      PaymentTriggerHandler handler = new PaymentTriggerHandler(
        PaymentTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__Payment__c>(oldList),
        new Map<Id, cve__Payment__c>(newList)
      );
      Test.startTest();
      handler.beforeUpdate();
      Test.stopTest();

      Assert.areEqual(
        'Submitted for Approval',
        newList[0].cve__Status__c,
        'Status is not Submitted for Approval'
      );
      Assert.areEqual(
        'Submitted for Approval',
        newList[1].cve__Status__c,
        'Status is not Submitted for Approval'
      );
    }
  }

  @isTest
  static void checkTheStatusWhenPaymentSpecApproved() {
    User u = getUserWithRole();
    System.runAs(u) {
      List<cve__PaymentSpecification__c> oldList = createTestDataForPaymentStatusCheck();
      List<cve__PaymentSpecification__c> newList = [
        SELECT
          id,
          ClaimLeaveStatus__c,
          cve__OverpaymentNet__c,
          cvint__AbsenceClaim__c,
          cve__Claim__c,
          PaymentApprovalStatus__c
        FROM cve__PaymentSpecification__c
        WHERE PaymentApprovalStatus__c = 'Submitted for Approval'
      ];
      for (cve__PaymentSpecification__c paySpec : newList) {
        paySpec.PaymentApprovalStatus__c = 'Approved';
      }
      PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
        PaymentSpecificationTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__PaymentSpecification__c>(oldList),
        new Map<Id, cve__PaymentSpecification__c>(newList),
        null
      );

      Test.startTest();
      handler.afterUpdate();
      Test.stopTest();

      cve__Payment__c pay = [SELECT id, cve__Status__c FROM cve__Payment__c];
      Assert.areEqual(
        'Approved',
        pay.cve__Status__c,
        'Status is not changed to Approved'
      );
    }
  }

  @isTest
  static void checkTheStatusWhenPaymentSpecRejected() {
    User u = getUserWithRole();
    System.runAs(u) {
      List<cve__PaymentSpecification__c> oldList = createTestDataForPaymentStatusCheck();
      List<cve__PaymentSpecification__c> newList = [
        SELECT
          id,
          ClaimLeaveStatus__c,
          cve__OverpaymentNet__c,
          cvint__AbsenceClaim__c,
          cve__Claim__c,
          PaymentApprovalStatus__c
        FROM cve__PaymentSpecification__c
        WHERE PaymentApprovalStatus__c = 'Submitted for Approval'
      ];
      for (cve__PaymentSpecification__c paySpec : newList) {
        paySpec.PaymentApprovalStatus__c = 'Rejected';
      }
      PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
        PaymentSpecificationTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__PaymentSpecification__c>(oldList),
        new Map<Id, cve__PaymentSpecification__c>(newList),
        null
      );

      Test.startTest();
      handler.afterUpdate();
      Test.stopTest();

      cve__Payment__c pay = [SELECT id, cve__Status__c FROM cve__Payment__c];
      Assert.areEqual(
        'Pending',
        pay.cve__Status__c,
        'Status is not changed to Pending'
      );
    }
  }

  @isTest
  static void checkIfConsolidatedWhenExpressPaid() {
    User u = getUserWithRole();
    System.runAs(u) {
      TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
      cvab__Claim__c c = new cvab__Claim__c(ExpressPaid__c = true);
      insert c;
      cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
        cvint__AbsenceClaim__c = c.id,
        PaymentApprovalStatus__c = 'Submitted for Approval'
      );
      insert ps;
      Id typeID = Schema.getGlobalDescribe()
        .get('cve__Payment__c')
        .getDescribe()
        .getRecordTypeInfosByName()
        .get('Calculated')
        .getRecordTypeId();
      cve__UnallocatedPayment__c up = new cve__UnallocatedPayment__c(
        cve__PaymentSpecification__c = ps.Id,
        cve__Start__c = Date.today(),
        cve__Through__c = Date.today().addDays(6),
        cve__GrossBenefit__c = 1000
      );
      insert up;
      cve__Payment__c pay1 = new cve__Payment__c(
        cve__Start__c = Date.newInstance(2022, 1, 1),
        cve__Through__c = Date.newInstance(2022, 1, 7),
        RecordTypeId = typeId,
        cve__UnallocatedPayment__c = up.id,
        cve__Net__c = 180.00,
        cve__PaymentSpecification__c = ps.id,
        cve__Status__c = 'Pending'
      );
      insert pay1;
      cve__UnallocatedPayment__c up1 = new cve__UnallocatedPayment__c(
        cve__PaymentSpecification__c = ps.Id,
        cve__Start__c = Date.today(),
        cve__Through__c = Date.today().addDays(6),
        cve__GrossBenefit__c = 1000
      );
      insert up1;
      cve__Payment__c pay2 = new cve__Payment__c(
        cve__Start__c = Date.newInstance(2022, 1, 8),
        cve__Through__c = Date.newInstance(2022, 1, 14),
        RecordTypeId = typeId,
        cve__UnallocatedPayment__c = up1.id,
        cve__Net__c = 280.00,
        cve__PaymentSpecification__c = ps.id,
        cve__Status__c = 'Pending'
      );
      insert pay2;
      TriggerHandler.clearAllBypasses();

      List<cve__PaymentSpecification__c> oldList = new List<cve__PaymentSpecification__c>{
        ps
      };
      List<cve__PaymentSpecification__c> newList = [
        SELECT
          id,
          ClaimLeaveStatus__c,
          cve__OverpaymentNet__c,
          cvint__AbsenceClaim__c,
          cve__Claim__c,
          PaymentApprovalStatus__c
        FROM cve__PaymentSpecification__c
        WHERE PaymentApprovalStatus__c = 'Submitted for Approval'
      ];
      for (cve__PaymentSpecification__c paySpec : newList) {
        paySpec.PaymentApprovalStatus__c = 'Approved';
      }

      TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
      update newList;
      TriggerHandler.clearAllBypasses();

      PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
        PaymentSpecificationTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__PaymentSpecification__c>(oldList),
        new Map<Id, cve__PaymentSpecification__c>(newList),
        null
      );

      Test.startTest();
      handler.afterUpdate();
      Test.stopTest();

      List<cve__Payment__c> payList = [
        SELECT id, cve__Status__c
        FROM cve__Payment__c
        WHERE cve__PaymentSpecification__c = :ps.id
      ];
      Assert.areEqual(
        'Consolidated',
        payList[0].cve__Status__c,
        'Status is not changed to Consolidated'
      );
      Assert.areEqual(
        'Consolidated',
        payList[1].cve__Status__c,
        'Status is not changed to Consolidated'
      );
      Assert.areEqual(
        3,
        payList.size(),
        'Consolidated Payment was not created'
      );
    }
  }

  @isTest
  static void checkIfConsolidatedWhenAutoPaid() {
    User u = getUserWithRole();
    System.runAs(u) {
      TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
      cve__Claim__c c = new cve__Claim__c(Autopay__c = true);
      insert c;
      cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
        cve__Claim__c = c.id,
        PaymentApprovalStatus__c = 'Submitted for Approval'
      );
      insert ps;
      Id typeID = Schema.getGlobalDescribe()
        .get('cve__Payment__c')
        .getDescribe()
        .getRecordTypeInfosByName()
        .get('Calculated')
        .getRecordTypeId();
      cve__UnallocatedPayment__c up = new cve__UnallocatedPayment__c(
        cve__PaymentSpecification__c = ps.Id,
        cve__Start__c = Date.today(),
        cve__Through__c = Date.today().addDays(6),
        cve__GrossBenefit__c = 1000
      );
      insert up;
      cve__Payment__c pay1 = new cve__Payment__c(
        cve__Start__c = Date.newInstance(2022, 1, 1),
        cve__Through__c = Date.newInstance(2022, 1, 7),
        RecordTypeId = typeId,
        cve__UnallocatedPayment__c = up.id,
        cve__Net__c = 180.00,
        cve__PaymentSpecification__c = ps.id,
        cve__Status__c = 'Pending'
      );
      insert pay1;
      cve__UnallocatedPayment__c up1 = new cve__UnallocatedPayment__c(
        cve__PaymentSpecification__c = ps.Id,
        cve__Start__c = Date.today(),
        cve__Through__c = Date.today().addDays(6),
        cve__GrossBenefit__c = 1000
      );
      insert up1;
      cve__Payment__c pay2 = new cve__Payment__c(
        cve__Start__c = Date.newInstance(2022, 1, 8),
        cve__Through__c = Date.newInstance(2022, 1, 14),
        RecordTypeId = typeId,
        cve__UnallocatedPayment__c = up1.id,
        cve__Net__c = 280.00,
        cve__PaymentSpecification__c = ps.id,
        cve__Status__c = 'Pending'
      );
      insert pay2;
      TriggerHandler.clearAllBypasses();

      List<cve__PaymentSpecification__c> oldList = new List<cve__PaymentSpecification__c>{
        ps
      };
      List<cve__PaymentSpecification__c> newList = [
        SELECT
          id,
          ClaimLeaveStatus__c,
          cve__OverpaymentNet__c,
          cvint__AbsenceClaim__c,
          cve__Claim__c,
          PaymentApprovalStatus__c
        FROM cve__PaymentSpecification__c
        WHERE PaymentApprovalStatus__c = 'Submitted for Approval'
      ];
      for (cve__PaymentSpecification__c paySpec : newList) {
        paySpec.PaymentApprovalStatus__c = 'Approved';
      }

      TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
      update newList;
      TriggerHandler.clearAllBypasses();

      PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
        PaymentSpecificationTriggerHelper.getInstance(),
        oldList,
        newList,
        new Map<Id, cve__PaymentSpecification__c>(oldList),
        new Map<Id, cve__PaymentSpecification__c>(newList),
        null
      );

      Test.startTest();
      handler.afterUpdate();
      Test.stopTest();

      List<cve__Payment__c> payList = [
        SELECT id, cve__Status__c
        FROM cve__Payment__c
        WHERE cve__PaymentSpecification__c = :ps.id
      ];
      Assert.areEqual(
        'Consolidated',
        payList[0].cve__Status__c,
        'Status is not changed to Consolidated'
      );
      Assert.areEqual(
        'Consolidated',
        payList[1].cve__Status__c,
        'Status is not changed to Consolidated'
      );
      Assert.areEqual(
        3,
        payList.size(),
        'Consolidated Payment was not created'
      );
    }
  }
}