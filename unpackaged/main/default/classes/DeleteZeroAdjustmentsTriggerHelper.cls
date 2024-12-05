public with sharing class DeleteZeroAdjustmentsTriggerHelper {
  public static DeleteZeroAdjustmentsTriggerHelper getInstance() {
    return new DeleteZeroAdjustmentsTriggerHelper();
  }

  public List<cve__Adjustment__c> getAdjToBeDeleted(
    List<DeleteZeroAdjustments__e> eventList
  ) {
    Set<Id> psIds = new Set<Id>();
    Set<Id> refIds = new Set<Id>();

    for (DeleteZeroAdjustments__e event : eventList) {
      psIds.add(event.PaymentSpecificationId__c);
    }

    if (psIds.size() == 0) {
      return new List<cve__Adjustment__c>();
    }

    List<cve__PaymentSpecification__c> psList = [
      SELECT id, cvint__AbsenceClaim__c, cve__BenefitClaimed__c
      FROM cve__PaymentSpecification__c
      WHERE Id IN :psIds
    ];

    for (cve__PaymentSpecification__c ps : psList) {
      if (ps.cvint__AbsenceClaim__c != null) {
        refIds.add(ps.cvint__AbsenceClaim__c);
      } else if (ps.cve__BenefitClaimed__c != null) {
        refIds.add(ps.cve__BenefitClaimed__c);
      }
    }

    if (refIds.size() == 0) {
      return new List<cve__Adjustment__c>();
    }

    return [
      SELECT id
      FROM cve__Adjustment__c
      WHERE
        cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
        AND UnallocatedPayment__c = NULL
        AND (cve__PaymentSpecification__r.cvint__AbsenceClaim__c IN :refIds
        OR cve__PaymentSpecification__r.cve__BenefitClaimed__c IN :refIds)
    ];
  }

  public List<cve__UnallocatedPayment__c> getUpayToBeDeleted(
    List<DeleteZeroAdjustments__e> eventList
  ) {
    Set<Id> psIds = new Set<Id>();
    for (DeleteZeroAdjustments__e event : eventList) {
      psIds.add(event.PaymentSpecificationId__c);
    }

    if (psIds.size() == 0) {
      return new List<cve__UnallocatedPayment__c>();
    }

    id recordTypeId = Schema.getGlobalDescribe()
      .get('cve__UnallocatedPayment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Lump Sum Repayment')
      .getRecordTypeId();

    return [
      SELECT id
      FROM cve__UnallocatedPayment__c
      WHERE
        RecordTypeId = :recordTypeId
        AND cve__LumpSum__c = 0
        AND cve__PaymentSpecification__c IN :psIds
    ];
  }

  public List<cve__PaymentSpecification__c> resetRecoupOverpaymentField(
    List<DeleteZeroAdjustments__e> eventList
  ) {
    Set<Id> psIds = new Set<Id>();
    List<cve__PaymentSpecification__c> result = new List<cve__PaymentSpecification__c>();

    for (DeleteZeroAdjustments__e event : eventList) {
      psIds.add(event.PaymentSpecificationId__c);
    }

    if (psIds.size() == 0) {
      return result;
    }

    List<cve__PaymentSpecification__c> psList = [
      SELECT id, RecoupOverpayment__c
      FROM cve__PaymentSpecification__c
      WHERE id IN :psIds AND RecoupOverpayment__c = TRUE
    ];

    for (cve__PaymentSpecification__c ps : psList) {
      ps.RecoupOverpayment__c = false;
      result.add(ps);
    }

    return result;
  }
}