@isTest
public class SubflowProcessExpressPayClaimTest {
  @TestSetup
  public static void createData() {
    cve__Claim__c disability = new cve__Claim__c();
    insert disability;
    cvab__Claim__c absence = new cvab__Claim__c(ExpressPaid__c = false);
    insert absence;
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = absence.id,
      cve__Claim__c = disability.id
    );

    insert ps;
  }
  @isTest
  public static void express_pay() {
    cvab__Claim__c clm = [SELECT Id FROM cvab__Claim__c];

    Test.StartTest();
    Flow.Interview testFlow = Flow.Interview.createInterview(
      'Subflow_ProcessExpressPayClaim',
      new Map<String, Object>{ 'recordId' => clm.Id }
    );
    testFlow.start();
    Test.StopTest();

    clm = [
      SELECT Id, ExpressPaid__c
      FROM cvab__Claim__c
      WHERE Id = :clm.Id
    ];

    Assert.areEqual(
      true,
      clm.ExpressPaid__c,
      'Unexpected ExpressPaid__c value'
    );
  }
}