public with sharing class RecalculatePaymentTriggerHelper {
  private static RecalculatePaymentTriggerHelper instance = null;

  public static RecalculatePaymentTriggerHelper getHelperInstance() {
    if (instance == null) {
      instance = new RecalculatePaymentTriggerHelper();
    }

    return instance;
  }

  public List<Id> getPaymentSpecIds(List<RecalculatePayments__e> newList) {
    List<Id> paySpecIds = new List<Id>();
    for (RecalculatePayments__e rp : newList) {
      paySpecIds.add(rp.PaymentSpecificationId__c);
    }
    return paySpecIds;
  }
  public List<String> calculatePaymentsByPaymentSpecIds(List<Id> paySpecIds) {
    List<String> results = new List<String>();
    for (Id id : paySpecIds) {
      results.add(cve.PaymentSpecificationActions.calculatePayments(id));
    }
    System.debug(
      [
        SELECT
          Id,
          cve__PaymentSpecification__r.cvint__AbsenceClaim__c,
          cve__PaymentSpecification__r.cve__BenefitClaimed__c
        FROM cve__Payment__c
      ]
    );
    System.debug(
      [
        SELECT Id, cvint__AbsenceClaim__c, cve__BenefitClaimed__c
        FROM cve__PaymentSpecification__c
      ]
    );
    return results;
  }

  public List<cve__Payment__c> approvePaymentsByPaymentSpecIds(
    List<Id> paySpecIds
  ) {
    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    consolidatePayments cp = new consolidatePayments();
    payments = cp.getPayments(paySpecIds);
    for (cve__Payment__c payment : payments) {
      payment.cve__Status__c = 'Approved';
    }
    return payments;
  }

  public List<Id> filterPaymentSpecs(List<Id> paymentSpecIds) {
    Map<Id, cve__PaymentSpecification__c> paymentSpecMap = new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT id
        FROM cve__PaymentSpecification__c
        WHERE
          id IN :paymentSpecIds
          AND PaymentApprovalStatus__c != 'Submitted for Approval'
      ]
    );
    return new List<Id>(paymentSpecMap.keySet());
  }

  public List<cve__Payment__c> consolidatePaymentsByPaymentSpecIds(
    List<Id> paySpecIds
  ) {
    consolidatePayments cp = new consolidatePayments();
    List<cve__Payment__c> consolidatedPayments = cp.consolidatePaymentsByPaymentSpecIds(
      paySpecIds
    );
    return consolidatedPayments;
  }

  public List<Id> getExpressPayClaims(List<Id> paymentSpecIds) {
    Map<Id, cve__PaymentSpecification__c> expressPaymentSpecs = new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT
          Id,
          cvint__AbsenceClaim__r.ExpressPaid__c,
          cve__Claim__r.ExpressPaid__c
        FROM cve__PaymentSpecification__c
        WHERE
          Id IN :paymentSpecIds
          AND (cvint__AbsenceClaim__r.ExpressPaid__c = TRUE
          OR cve__Claim__r.Autopay__c = TRUE
          OR cve__Claim__r.ExpressPaid__c = TRUE)
      ]
    );

    return new List<Id>(expressPaymentSpecs.keySet());
  }

  public List<RecoupOverpayment__e> generateOverpaymentEvents(
    List<RecalculatePayments__e> eventList
  ) {
    List<RecoupOverpayment__e> result = new List<RecoupOverpayment__e>();
    Set<Id> psIds = new Set<Id>();
    for (RecalculatePayments__e event : eventList) {
      if (event.RunOverpaymentCheck__c) {
        psIds.add(event.PaymentSpecificationId__c);
      }
    }

    if (psIds.size() == 0) {
      return result;
    }

    List<cve__PaymentSpecification__c> psList = [
      SELECT
        id,
        cvint__AbsenceClaim__c,
        cvint__AbsenceClaim__r.cvab__AbsenceStatus__c,
        cve__Claim__c,
        cve__BenefitClaimed__c,
        cve__BenefitClaimed__r.cve__Status__c
      FROM cve__PaymentSpecification__c
      WHERE id IN :psIds
    ];

    for (cve__PaymentSpecification__c ps : psList) {
      if (
        (ps.cvint__AbsenceClaim__c != null &&
        ps.cvint__AbsenceClaim__r.cvab__AbsenceStatus__c != 'Denied' &&
        ps.cvint__AbsenceClaim__r.cvab__AbsenceStatus__c != 'Cancelled') ||
        (ps.cve__Claim__c != null &&
        ps.cve__BenefitClaimed__c != null &&
        ps.cve__BenefitClaimed__r.cve__Status__c != 'Denied')
      ) {
        result.add(new RecoupOverpayment__e(PaymentSpecificationId__c = ps.id));
      }
    }

    return result;
  }

  public List<DeleteZeroAdjustments__e> generateDeleteAdjustmentEvent(
    List<RecalculatePayments__e> eventList
  ) {
    List<DeleteZeroAdjustments__e> result = new List<DeleteZeroAdjustments__e>();
    for (RecalculatePayments__e event : eventList) {
      if (event.DeleteZeroAdjustments__c) {
        result.add(
          new DeleteZeroAdjustments__e(
            PaymentSpecificationId__c = event.PaymentSpecificationId__c
          )
        );
      }
    }
    return result;
  }

  public List<cve__BenefitClaimed__c> updateBenefitClaimed(
    List<RecalculatePayments__e> eventList
  ) {
    Set<Id> psIds = new Set<Id>();
    for (RecalculatePayments__e event : eventList) {
      if (event.ClaimBrainCalculation__c) {
        psIds.add(event.PaymentSpecificationId__c);
      }
    }

    if (psIds.size() == 0) {
      return new List<cve__BenefitClaimed__c>();
    }

    List<cve__PaymentSpecification__c> psList = [
      SELECT Id, cve__BenefitClaimed__c
      FROM cve__PaymentSpecification__c
      WHERE id IN :psIds
    ];
    Set<Id> bcIds = new Set<Id>();

    for (cve__PaymentSpecification__c ps : psList) {
      if (ps.cve__BenefitClaimed__c != null) {
        bcIds.add(ps.cve__BenefitClaimed__c);
      }
    }

    if (bcIds.size() == 0) {
      return new List<cve__BenefitClaimed__c>();
    }
    List<cve__BenefitClaimed__c> bcList = [
      SELECT id, ClaimBrainIntegrationStatus__c
      FROM cve__BenefitClaimed__c
      WHERE id IN :bcIds
    ];
    for (cve__BenefitClaimed__c bc : bcList) {
      bc.ClaimBrainIntegrationStatus__c = 'Complete';
    }
    return bcList;
  }
}