@isTest
public class CaseTriggerTest {
  @testSetup
  public static void makeSetup() {
    TriggerHandler.bypass('CaseTriggerHandler');
    Case c1 = new Case();
    insert c1;
    Test.setCreatedDate(c1.Id, Date.newInstance(2024, 1, 1));
    TriggerHandler.clearAllBypasses();
  }

  @isTest
  public static void testInitialDecisionDateAndTAT() {
    Case oldCase = getCase();
    Case newCase = getCase();
    newCase.Status = 'Closed';

    CaseTriggerHandler handler = new CaseTriggerHandler(
      CaseTriggerHelper.getInstance(),
      new CaseTriggerHandler.ContextVariable(
        new List<Case>{ newCase },
        new List<Case>{ oldCase },
        new Map<Id, Case>{ newCase.id => newCase },
        new Map<Id, Case>{ oldCase.id => oldCase }
      )
    );
    Test.startTest();
    handler.beforeUpdate();
    Test.stopTest();

    System.assertEquals(
      Datetime.now(),
      newCase.InitialDecisionDate__c,
      'Date Updated Incorrectly'
    );
  }

  @isTest
  public static void testCveIntakeDecisionTAT() {
    Case oldCase = getCase();
    Case newCase = getCase();
    newCase.Status = 'Closed';
    cve__Claim__c cveClaim = new cve__Claim__c();
    insert cveClaim;
    Test.setCreatedDate(cveClaim.Id, Date.newInstance(2024, 1, 31));
    newCase.CveClaim__c = cveClaim.id;

    CaseTriggerHandler handler = new CaseTriggerHandler(
      CaseTriggerHelper.getInstance(),
      new CaseTriggerHandler.ContextVariable(
        new List<Case>{ newCase },
        new List<Case>{ oldCase },
        new Map<Id, Case>{ newCase.id => newCase },
        new Map<Id, Case>{ oldCase.id => oldCase }
      )
    );
    Test.startTest();
    handler.beforeUpdate();
    Test.stopTest();

    System.assertEquals(
      22,
      newCase.IntakeDecisionTAT__c,
      'IntakeDecisionTAT__c Updated Incorrectly'
    );
  }

  @isTest
  public static void testCvabIntakeDecisionTAT() {
    Case oldCase = getCase();
    Case newCase = getCase();
    newCase.Status = 'Closed';
    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;
    Test.setCreatedDate(cvabClaim.Id, Date.newInstance(2024, 2, 29));
    newCase.CvabClaim__c = cvabClaim.id;

    CaseTriggerHandler handler = new CaseTriggerHandler(
      CaseTriggerHelper.getInstance(),
      new CaseTriggerHandler.ContextVariable(
        new List<Case>{ newCase },
        new List<Case>{ oldCase },
        new Map<Id, Case>{ newCase.id => newCase },
        new Map<Id, Case>{ oldCase.id => oldCase }
      )
    );
    Test.startTest();
    handler.beforeUpdate();
    Test.stopTest();

    System.assertEquals(
      43,
      newCase.IntakeDecisionTAT__c,
      'IntakeDecisionTAT__c Updated Incorrectly'
    );
  }

  private static Case getCase() {
    return [
      SELECT
        id,
        CreatedDate,
        CvabClaim__c,
        CveClaim__c,
        InitialDecisionDate__c,
        IntakeInitialDecisionTAT__c,
        IntakeDecisionTAT__c,
        Status,
        ClosedDate
      FROM Case
    ];
  }
}