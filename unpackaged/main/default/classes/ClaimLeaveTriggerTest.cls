@isTest
public class ClaimLeaveTriggerTest {
  @testSetUp
  static void dataSetUp() {
    User u = [
      SELECT id, name, email
      FROM User
      WHERE id = :UserInfo.getUserId()
    ];

    System.runAs(u) {
      SObject acc = new TestAccountBuilder().buildAndInsert();
      SObject customGroup = new TestGroupBuilder()
        .withMasterGroupId(acc.Id)
        .buildAndInsert();
      SObject con = new TestContactBuilder()
        .withAccountId(acc.Id)
        .withGroupId(customGroup.Id)
        .buildAndInsert();

      cvab__claim__c cvab = new cvab__claim__c();
      cvab.cvab__Employee__c = con.id;
      cvab.IntakeCase__c = null;
      insert cvab;

      cvab__ClaimLeave__c absence = new cvab__ClaimLeave__c();
      absence.cvab__Claim__c = cvab.Id;
      absence.cvab__Status__c = 'Pending';
      insert absence;

      Case cs = new Case();
      cs.CvabClaim__c = cvab.Id;
      insert cs;
    }
  }

  @isTest
  static void cvabInitialTATCalculation() {
    User testUser = (User) new TestUserBuilder()
      .withLastName('claimLeaveTriggerUser')
      .buildAndInsert();
    System.runAs(testUser) {
      cvab__ClaimLeave__c absence = [
        SELECT Id, cvab__Status__c
        FROM cvab__ClaimLeave__c
        LIMIT 1
      ];
      Map<Id, cvab__ClaimLeave__c> oldMap = new Map<Id, cvab__ClaimLeave__c>(
        new List<cvab__ClaimLeave__c>{ absence }
      );

      absence.cvab__Status__c = 'Pending Eligibility';
      update absence;

      Map<Id, cvab__ClaimLeave__c> newMap = new Map<Id, cvab__ClaimLeave__c>(
        new List<cvab__ClaimLeave__c>{ absence }
      );

      test.startTest();
      ClaimLeaveTriggerHandler handler = new ClaimLeaveTriggerHandler(
        ClaimLeaveTriggerHelper.getInstance(),
        new List<cvab__ClaimLeave__c>{ absence },
        oldMap,
        newMap
      );
      handler.afterUpdate();
      test.stopTest();

      cvab__Claim__c result = [
        SELECT Id, InitialDecisionDate__c
        FROM cvab__Claim__c
        LIMIT 1
      ];
      Assert.areEqual(
        system.today(),
        result.InitialDecisionDate__c,
        'Initial Decision date was not populated correctly'
      );
    }
  }
  @isTest
  static void cvabFinalTATCalculation() {
    User testUser = (User) new TestUserBuilder()
      .withLastName('claimLeaveTriggerUser')
      .buildAndInsert();
    System.runAs(testUser) {
      cvab__ClaimLeave__c absence = [
        SELECT Id, cvab__Status__c
        FROM cvab__ClaimLeave__c
        LIMIT 1
      ];
      Map<Id, cvab__ClaimLeave__c> oldMap = new Map<Id, cvab__ClaimLeave__c>(
        new List<cvab__ClaimLeave__c>{ absence }
      );

      absence.cvab__Status__c = 'Approved';
      update absence;

      Map<Id, cvab__ClaimLeave__c> newMap = new Map<Id, cvab__ClaimLeave__c>(
        new List<cvab__ClaimLeave__c>{ absence }
      );

      test.startTest();
      ClaimLeaveTriggerHandler handler = new ClaimLeaveTriggerHandler(
        ClaimLeaveTriggerHelper.getInstance(),
        new List<cvab__ClaimLeave__c>{ absence },
        oldMap,
        newMap
      );
      handler.afterUpdate();
      test.stopTest();

      cvab__Claim__c result = [
        SELECT Id, cvab__Status__c, FinalDecisionDate__c
        FROM cvab__Claim__c
        LIMIT 1
      ];

      Assert.areEqual(
        system.today(),
        result.FinalDecisionDate__c,
        'Final Decision date was not populated correctly'
      );
    }
  }
}