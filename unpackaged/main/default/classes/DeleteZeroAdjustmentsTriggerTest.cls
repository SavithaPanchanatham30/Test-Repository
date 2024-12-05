@isTest
public class DeleteZeroAdjustmentsTriggerTest {
  @isTest
  public static void testAdjDeletion() {
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    TriggerHandler.bypass('AdjustmentTriggerHandler');
    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;
    cve__PaymentSpecification__c cvabPs = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvabClaim.id
    );
    insert cvabPs;
    cve__Adjustment__c adj = new cve__Adjustment__c(
      cve__PaymentSpecification__c = cvabPs.id,
      cve__Type__c = 'Recoup Overpayment (Pre-Tax)',
      cve__Amount__c = 0,
      cve__Period__c = 'Daily'
    );
    insert adj;
    TriggerHandler.clearAllBypasses();

    DeleteZeroAdjustmentsTriggerHandler handler = new DeleteZeroAdjustmentsTriggerHandler(
      DeleteZeroAdjustmentsTriggerHelper.getInstance(),
      new List<DeleteZeroAdjustments__e>{
        new DeleteZeroAdjustments__e(PaymentSpecificationId__c = cvabPs.id)
      }
    );
    Test.startTest();
    handler.afterInsert();
    Test.stopTest();

    List<cve__Adjustment__c> adjList = [
      SELECT id
      FROM cve__Adjustment__c
      WHERE cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
    ];

    System.assertEquals(0, adjList.size(), 'adjustment not deleted');
  }

  @isTest
  public static void testUpayDeletion() {
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    TriggerHandler.bypass('AdjustmentTriggerHandler');
    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;
    cve__PaymentSpecification__c cvabPs = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvabClaim.id
    );
    insert cvabPs;
    id recordTypeId = Schema.getGlobalDescribe()
      .get('cve__UnallocatedPayment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Lump Sum Repayment')
      .getRecordTypeId();

    cve__UnallocatedPayment__c upay = new cve__UnallocatedPayment__c(
      RecordTypeId = recordTypeId,
      cve__PaymentSpecification__c = cvabPs.id,
      cve__LumpSum__c = 0
    );
    insert upay;
    TriggerHandler.clearAllBypasses();

    DeleteZeroAdjustmentsTriggerHandler handler = new DeleteZeroAdjustmentsTriggerHandler(
      DeleteZeroAdjustmentsTriggerHelper.getInstance(),
      new List<DeleteZeroAdjustments__e>{
        new DeleteZeroAdjustments__e(PaymentSpecificationId__c = cvabPs.id)
      }
    );
    Test.startTest();
    handler.afterInsert();
    Test.stopTest();

    List<cve__UnallocatedPayment__c> upayList = [
      SELECT id
      FROM cve__UnallocatedPayment__c
      WHERE cve__LumpSum__c = 0
    ];

    System.assertEquals(0, upayList.size(), 'unallocated Payment not deleted');
  }

  @isTest
  public static void testResetPS() {
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    TriggerHandler.bypass('AdjustmentTriggerHandler');
    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;
    cve__PaymentSpecification__c cvabPs = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvabClaim.id,
      RecoupOverpayment__c = true
    );
    insert cvabPs;
    TriggerHandler.clearAllBypasses();

    DeleteZeroAdjustmentsTriggerHandler handler = new DeleteZeroAdjustmentsTriggerHandler(
      DeleteZeroAdjustmentsTriggerHelper.getInstance(),
      new List<DeleteZeroAdjustments__e>{
        new DeleteZeroAdjustments__e(PaymentSpecificationId__c = cvabPs.id)
      }
    );
    Test.startTest();
    handler.afterInsert();
    Test.stopTest();

    cve__PaymentSpecification__c ps = [
      SELECT id, RecoupOverpayment__c
      FROM cve__PaymentSpecification__c
      WHERE id = :cvabPs.id
    ];

    System.assertEquals(false, ps.RecoupOverpayment__c, 'reset ps failed');
  }

  @isTest
  public static void triggerTest() {
    TriggerHandler.bypass('CvabClaimTriggerHandler');
    TriggerHandler.bypass('PaymentSpecificationTriggerHandler');
    TriggerHandler.bypass('AdjustmentTriggerHandler');
    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;
    cve__PaymentSpecification__c cvabPs = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvabClaim.id,
      RecoupOverpayment__c = true
    );
    insert cvabPs;
    TriggerHandler.clearAllBypasses();

    EventPublisher eventPub = EventPublisher.getInstance();
    Test.startTest();
    eventPub.publish(
      new List<DeleteZeroAdjustments__e>{
        new DeleteZeroAdjustments__e(PaymentSpecificationId__c = cvabPs.id)
      }
    );
    Test.stopTest();

    cve__PaymentSpecification__c ps = [
      SELECT id, RecoupOverpayment__c
      FROM cve__PaymentSpecification__c
      WHERE id = :cvabPs.id
    ];

    System.assertEquals(false, ps.RecoupOverpayment__c, 'reset ps failed');
  }
}