@isTest
public class UpdateCaseRecordControllerTest {
  @TestSetup
  public static void testSetup() {
    Case c = new Case();
    insert c;
  }

  @isTest
  public static void testIfRecordUpdates() {
    Case c = [SELECT id FROM Case];
    UpdateCaseRecordController.updateClaimIntakeLastRunByUserField(c.id);

    c = [SELECT id, ClaimIntakeLastRunByUser__c FROM Case];

    Assert.areEqual(
      UserInfo.getUserId(),
      c.ClaimIntakeLastRunByUser__c,
      'Field not updated properly'
    );
  }

  @isTest
  public static void testIfRecordAreFetched() {
    Case c = [SELECT id FROM Case];
    Case c1 = UpdateCaseRecordController.getCaseRecord(c.id);

    Assert.areEqual(c.id, c1.id, 'Field not fetched properly');
  }
}