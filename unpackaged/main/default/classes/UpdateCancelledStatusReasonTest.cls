@isTest
public class UpdateCancelledStatusReasonTest {
  @TestSetup
  public static void testSetup() {
    SObject acc = new TestAccountBuilder().buildAndInsert();
    SObject customGroup = new TestGroupBuilder()
      .withMasterGroupId(acc.Id)
      .buildAndInsert();
    SObject con = new TestContactBuilder()
      .withAccountId(acc.Id)
      .withGroupId(customGroup.Id)
      .build();

    cvab__AbsenceSettings__c cs = cvab__AbsenceSettings__c.getInstance();
    cs.cvab__DisableTriggers__c = true;
    insert cs;

    cvab__Claim__c cvabClaim = new cvab__Claim__c(
      cvab__Employee__c = con.Id,
      cvab__ReturnToWork__c = Date.newInstance(2012, 3, 10)
    );
    insert cvabClaim;

    cvab__ClaimLeave__c claimLeave = new cvab__ClaimLeave__c(
      name = 'Massachusetts Paid Family and Medical Leave',
      cvab__Claim__c = cvabClaim.Id,
      cvab__Approved__c = 8025,
      cvab__ApprovedLabel__c = '3 weeks, 1 day, 5 hours, 45 minutes',
      cvab__LeaveType__c = 'Continuous'
    );
    insert claimLeave;
  }

  @isTest
  public static void testUpdateOnStatusReason() {
    cvab__Claim__c claim = [
      SELECT id, cvab__ReturnToWork__c
      FROM cvab__Claim__c
    ];
    cvab__ClaimLeave__c cl = [SELECT id FROM cvab__ClaimLeave__c];
    cvab__DateRange__c dr = new cvab__DateRange__c(
      cvab__StartDate__c = Date.newInstance(2012, 3, 7),
      cvab__EndDate__c = Date.newInstance(2012, 3, 30),
      cvab__Status__c = 'Cancelled',
      cvab__ClaimLeave__c = cl.id
    );
    insert dr;
    cvab__AbsenceSettings__c cs = cvab__AbsenceSettings__c.getInstance();
    cs.cvab__DisableTriggers__c = false;
    update cs;

    UpdateCancelledStatusReasonHandler handler = new UpdateCancelledStatusReasonHandler(
      UpdateCancelledStatusReasonHelper.getInstance(),
      new List<UpdateCancelledStatusReason__e>{
        new UpdateCancelledStatusReason__e(
          ClaimId__c = claim.id,
          ReturnToWork__c = claim.cvab__ReturnToWork__c
        )
      }
    );
    Test.startTest();
    handler.afterInsert();
    Test.stopTest();

    dr = [SELECT id, cvab__StatusReason__c FROM cvab__DateRange__c];
    System.assertEquals(
      'Return to Work',
      dr.cvab__StatusReason__c,
      'Reason was not updated Correctly'
    );
  }

  @isTest
  public static void triggerTest() {
    cvab__Claim__c claim = [
      SELECT id, cvab__ReturnToWork__c
      FROM cvab__Claim__c
    ];
    cvab__ClaimLeave__c cl = [SELECT id FROM cvab__ClaimLeave__c];
    cvab__DateRange__c dr = new cvab__DateRange__c(
      cvab__StartDate__c = Date.newInstance(2012, 3, 7),
      cvab__EndDate__c = Date.newInstance(2012, 3, 30),
      cvab__Status__c = 'Cancelled',
      cvab__ClaimLeave__c = cl.id
    );
    insert dr;
    cvab__AbsenceSettings__c cs = cvab__AbsenceSettings__c.getInstance();
    cs.cvab__DisableTriggers__c = false;
    update cs;
    EventPublisher event = EventPublisher.getInstance();
    List<UpdateCancelledStatusReason__e> eventList = new List<UpdateCancelledStatusReason__e>{
      new UpdateCancelledStatusReason__e(
        ClaimId__c = claim.id,
        ReturnToWork__c = claim.cvab__ReturnToWork__c
      )
    };
    Test.startTest();
    event.publish(eventList);
    Test.stopTest();

    dr = [SELECT id, cvab__StatusReason__c FROM cvab__DateRange__c];
    System.assertEquals(
      'Return to Work',
      dr.cvab__StatusReason__c,
      'Reason was not updated Correctly'
    );
  }
}