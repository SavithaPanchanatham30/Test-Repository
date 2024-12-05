@isTest
public class HandleOverpaymentHelperTest {
  @testSetup
  public static void testSetup() {
    User u = [
      SELECT id, name, email
      FROM User
      WHERE id = :UserInfo.getUserId()
    ];
    System.runAs(u) {
      User testUser = (User) new TestUserBuilder()
        .withLastName('overpaymentUser')
        .buildAndInsert();

      assignPermissionSetsToUser(
        testUser,
        new List<String>{ 'PaymentSpecificationRollup_WRITE' }
      );
    }

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
    id recordTypeID = Schema.getGlobalDescribe()
      .get('cve__Benefit__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Short Term Disability')
      .getRecordTypeId();
    cve__Benefit__c benefit = new cve__Benefit__c(
      cve__Product__c = product.Id,
      cve__Product__r = product,
      RecordTypeId = recordTypeId,
      cve__BenefitPercentage__c = 50.00
    );
    insert benefit;

    Account acc = (Account) new TestAccountBuilder().buildAndInsert();

    SObject customGroup = new TestGroupBuilder()
      .withMasterGroupId(acc.Id)
      .buildAndInsert();

    Contact con = (Contact) new TestContactBuilder()
      .withAccountId(acc.Id)
      .withGroupId(customGroup.Id)
      .buildAndInsert();

    cve__Claim__c c = new cve__Claim__c(cve__ClaimantInsured__c = con.id);
    insert c;
  }

  @isTest
  public static void testDisabilityEventGeneration() {
    User u = getTestUser();
    System.runAs(u) {
      Contact con = getContact();
      con.HasCveOverpayment__c = true;
      update con;

      cve__Claim__c c = new cve__Claim__c(
        cve__Policy__c = getPolicyId(),
        cve__ClaimantInsured__c = con.id
      );
      insert c;
      cve__Claim__c c2 = new cve__Claim__c(
        cve__Policy__c = getPolicyId(),
        cve__ClaimantInsured__c = con.id
      );
      insert c2;

      TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
      TriggerHandler.bypass('PaymentTriggerHandler');
      cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
        cve__Claim__c = c.id,
        cve__Period__c = 'Weekly',
        cve__Start__c = Date.newInstance(2024, 1, 1),
        cve__OverpaymentBeforeTax__c = 180.00
      );
      insert ps;
      cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
        cve__Claim__c = c2.id
      );
      insert ps2;

      cve__Payment__c pay = new cve__Payment__c(
        cve__PaymentSpecification__c = ps2.id,
        cve__Status__c = 'Pending'
      );
      insert pay;

      Map<Id, cve__PaymentSpecification__c> oldMap = new Map<Id, cve__PaymentSpecification__c>(
        [
          SELECT
            id,
            cve__Claim__c,
            cvint__AbsenceClaim__c,
            cve__Start__c,
            cve__Through__c,
            cve__Amount__c,
            cve__AmountPeriod__c
          FROM cve__PaymentSpecification__c
          WHERE id = :ps2.id
        ]
      );
      ps2.cve__Start__c = Date.newInstance(2024, 2, 2);
      ps2.cve__Through__c = Date.newInstance(2024, 2, 30);
      ps2.cve__Amount__c = 2000;
      ps2.cve__AmountPeriod__c = 'Weekly';
      update ps2;
      Map<Id, cve__PaymentSpecification__c> newMap = new Map<Id, cve__PaymentSpecification__c>(
        [
          SELECT
            id,
            cve__Claim__c,
            cvint__AbsenceClaim__c,
            cve__Start__c,
            cve__Through__c,
            cve__Amount__c,
            cve__AmountPeriod__c
          FROM cve__PaymentSpecification__c
          WHERE id = :ps2.id
        ]
      );

      TriggerHandler.clearAllBypasses();

      Amoss_Instance mockEventPublisher = new Amoss_Instance(
        EventPublisher.class
      );
      mockEventPublisher.byDefaultMethodsReturn(
        new List<Database.SaveResult>()
      );
      EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

      Test.startTest();

      PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
        null,
        oldMap.values(),
        newMap.values(),
        oldMap,
        newMap,
        eventPublisherDouble
      );
      handler = handler.setHandleOverpaymentHelper(
        new HandleOverpaymentHelper()
      );
      handler.afterUpdate();

      Test.stopTest();

      List<RecalculatePayments__e> expectedResult = new List<RecalculatePayments__e>{
        new RecalculatePayments__e(
          PaymentSpecificationId__c = ps2.id,
          RunOverpaymentCheck__c = true
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
  }

  @isTest
  public static void testAbsenceEventGeneration() {
    User u = getTestUser();
    System.runAs(u) {
      Contact con = getContact();

      cvab__EmployeeLeave__c absenceType = new cvab__EmployeeLeave__c(
        cvab__Employee__c = con.id
      );
      insert absenceType;
      cvab__Claim__c c = new cvab__Claim__c();
      insert c;
      cvab__Claim__c c2 = new cvab__Claim__c(
        cvab__StartDate__c = Date.newInstance(2024, 1, 1),
        cvab__EndDate__c = Date.newInstance(2024, 1, 30),
        cvab__Employee__c = con.id
      );
      insert c2;
      Id paidLeaveID = Schema.getGlobalDescribe()
        .get('cvab__ClaimLeave__c')
        .getDescribe()
        .getRecordTypeInfosByName()
        .get('Paid Leave')
        .getRecordTypeId();
      cvab__ClaimLeave__c absence = new cvab__ClaimLeave__c(
        cvab__EmployeeLeave__c = absenceType.id,
        cvab__Claim__c = c.id,
        RecordTypeId = paidLeaveID
      );
      insert absence;
      cvab__ClaimLeave__c absence2 = new cvab__ClaimLeave__c(
        cvab__EmployeeLeave__c = absenceType.id,
        cvab__Claim__c = c2.id,
        RecordTypeId = paidLeaveID
      );
      insert absence2;

      TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
      TriggerHandler.bypass('PaymentTriggerHandler');
      cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
        cvint__AbsenceClaim__c = c.id,
        cve__Period__c = 'Weekly',
        cve__Start__c = Date.newInstance(2024, 1, 1),
        cve__OverpaymentBeforeTax__c = 180.00
      );
      insert ps;
      cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
        cvint__AbsenceClaim__c = c2.id
      );
      insert ps2;

      cve__Payment__c pay = new cve__Payment__c(
        cve__PaymentSpecification__c = ps2.id,
        cve__Status__c = 'Pending'
      );
      insert pay;

      Map<Id, cve__PaymentSpecification__c> oldMap = new Map<Id, cve__PaymentSpecification__c>(
        [
          SELECT
            id,
            cve__Claim__c,
            cvint__AbsenceClaim__c,
            cve__Start__c,
            cve__Through__c,
            cve__Amount__c,
            cve__AmountPeriod__c
          FROM cve__PaymentSpecification__c
          WHERE id = :ps2.id
        ]
      );
      ps2.cve__Start__c = Date.newInstance(2024, 2, 2);
      ps2.cve__Through__c = Date.newInstance(2024, 2, 30);
      ps2.cve__Amount__c = 2000;
      ps2.cve__AmountPeriod__c = 'Weekly';
      update ps2;
      con.HasCvabOverpayment__c = true;
      update con;
      Map<Id, cve__PaymentSpecification__c> newMap = new Map<Id, cve__PaymentSpecification__c>(
        [
          SELECT
            id,
            cve__Claim__c,
            cvint__AbsenceClaim__c,
            cve__Start__c,
            cve__Through__c,
            cve__Amount__c,
            cve__AmountPeriod__c
          FROM cve__PaymentSpecification__c
          WHERE id = :ps2.id
        ]
      );

      TriggerHandler.clearAllBypasses();

      Amoss_Instance mockEventPublisher = new Amoss_Instance(
        EventPublisher.class
      );
      mockEventPublisher.byDefaultMethodsReturn(
        new List<Database.SaveResult>()
      );
      EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

      Test.startTest();

      PaymentSpecificationTriggerHandler handler = new PaymentSpecificationTriggerHandler(
        null,
        oldMap.values(),
        newMap.values(),
        oldMap,
        newMap,
        eventPublisherDouble
      );
      handler = handler.setHandleOverpaymentHelper(
        new HandleOverpaymentHelper()
      );
      handler.afterUpdate();

      Test.stopTest();

      List<RecalculatePayments__e> expectedResult = new List<RecalculatePayments__e>{
        new RecalculatePayments__e(
          PaymentSpecificationId__c = ps2.id,
          RunOverpaymentCheck__c = true
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
  }

  public static id getBenefitId() {
    return [SELECT id FROM cve__Benefit__c][0].id;
  }

  public static id getPolicyId() {
    return [SELECT id FROM cve__Policy__c][0].id;
  }

  public static Contact getContact() {
    return [SELECT id FROM Contact][0];
  }

  public static User getTestUser() {
    return [SELECT id FROM User WHERE LastName = :'overpaymentUser'];
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