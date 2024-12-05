public with sharing class PaymentTriggerHelper {
  public static PaymentTriggerHelper instance;
  public HandlePaymentApprovalHelper approvalHelper;
  private List<cve__Payment__c> oldPayments;
  private List<cve__Payment__c> newPayments;
  private Map<Id, cve__Payment__c> oldPaymentsMap;
  private Map<Id, cve__Payment__c> newPaymentsMap;

  public static PaymentTriggerHelper getInstance() {
    if (instance == null) {
      instance = new PaymentTriggerHelper();
    }

    return instance;
  }

  @TestVisible
  private PaymentTriggerHelper setHandlePaymentApprovalHelper(
    HandlePaymentApprovalHelper helper
  ) {
    this.approvalHelper = helper;
    return this;
  }

  public PaymentTriggerHelper setContext(
    PaymentTriggerHandler.HandlerContext contxt
  ) {
    this.oldPayments = contxt.oldPayments;
    this.newPayments = contxt.newPayments;
    this.oldPaymentsMap = contxt.oldPaymentsMap;
    this.newPaymentsMap = contxt.newPaymentsMap;

    return instance;
  }

  @TestVisible
  private PaymentTriggerHelper() {
  }

  public void updatePayableAndIssueDate() {
    for (cve__Payment__c pay : newPayments) {
      cve__Payment__c oldPay = oldPaymentsMap != null &&
        oldPaymentsMap.containsKey(pay.id)
        ? oldPaymentsMap.get(pay.id)
        : null;
      if (
        (oldPay == null && pay.cve__Through__c != pay.cve__Payable__c) ||
        (oldPay != null &&
        oldPay.cve__Through__c != pay.cve__Through__c &&
        pay.cve__Through__c != pay.cve__Payable__c)
      ) {
        pay.cve__Payable__c = pay.cve__Through__c;
        pay.cve__Issue__c = pay.cve__Through__c;
      }
    }
  }

  public List<cve__Payment__c> populateClaimantLookups() {
    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    Map<Id, cve__PaymentSpecification__c> paymentSpecificationsMap = getPaymentSpecsByPayments(
      newPayments
    );
    for (cve__Payment__c payment : newPayments) {
      cve__PaymentSpecification__c paymentSpec = paymentSpecificationsMap.get(
        payment.cve__PaymentSpecification__c
      );
      payment.Claimant__c = getClaimant(paymentSpec);
      if (paymentSpec.PaymentApprovalStatus__c == 'Submitted for Approval') {
        payment.cve__Status__c = paymentSpec.PaymentApprovalStatus__c;
      }
      payments.add(payment);
    }

    return payments;
  }

  public List<cve__Payment__c> updateStatusToSubmittedForApproval() {
    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    Map<Id, cve__PaymentSpecification__c> paymentSpecificationsMap = getPaymentSpecsByPayments(
      newPayments
    );
    for (cve__Payment__c payment : newPayments) {
      cve__PaymentSpecification__c paymentSpec = paymentSpecificationsMap.get(
        payment.cve__PaymentSpecification__c
      );
      if (paymentSpec.PaymentApprovalStatus__c == 'Submitted for Approval') {
        payment.cve__Status__c = paymentSpec.PaymentApprovalStatus__c;
      }
      payments.add(payment);
    }

    return payments;
  }

  private Map<Id, cve__PaymentSpecification__c> getPaymentSpecsByPayments(
    List<cve__Payment__c> payments
  ) {
    Map<Id, cve__PaymentSpecification__c> paymentSpecificationsMap = new Map<Id, cve__PaymentSpecification__c>();

    for (cve__Payment__c payment : payments) {
      paymentSpecificationsMap.put(payment.cve__PaymentSpecification__c, null);
    }

    paymentSpecificationsMap = new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT
          Id,
          PaymentApprovalStatus__c,
          cve__Claim__c,
          cve__Claim__r.cve__ClaimantInsured__c,
          cvint__AbsenceClaim__c,
          cvint__AbsenceClaim__r.cvab__Employee__c
        FROM cve__PaymentSpecification__c
        WHERE Id IN :paymentSpecificationsMap.keySet()
      ]
    );

    return paymentSpecificationsMap;
  }

  private Id getClaimant(cve__PaymentSpecification__c paymentSpec) {
    return paymentSpec.cve__Claim__c != null
      ? paymentSpec.cve__Claim__r.cve__ClaimantInsured__c
      : paymentSpec.cvint__AbsenceClaim__r.cvab__Employee__c;
  }

  public List<Approval.ProcessSubmitRequest> validateApproval() {
    List<Approval.ProcessSubmitRequest> result = new List<Approval.ProcessSubmitRequest>();
    Map<Id, cve__Payment__c> paymentsToBeApproved = getPaymentsToBeApproved();
    if (!paymentsToBeApproved.isEmpty()) {
      this.approvalHelper = this.approvalHelper == null
        ? new HandlePaymentApprovalHelper(paymentsToBeApproved, oldPaymentsMap)
        : this.approvalHelper;
      result.addAll(approvalHelper.validatePaymentApproval());
    }
    return result;
  }

  private Map<Id, cve__Payment__c> getPaymentsToBeApproved() {
    Map<Id, cve__Payment__c> result = new Map<Id, cve__Payment__c>();
    for (cve__Payment__c newPay : newPaymentsMap.values()) {
      cve__Payment__c oldPay = oldPaymentsMap.get(newPay.id);
      if (
        newPay.cve__Status__c != oldPay.cve__Status__c &&
        newPay.cve__Status__c == 'Approved' ||
        (oldPay.cve__Status__c == 'Submitted for Approval' &&
        newPay.cve__Status__c == 'Pending')
      ) {
        result.put(newPay.id, newPay);
      }
    }
    return result;
  }

  public List<cve__Adjustment__c> lockRecoupOverpaymentAdjustment(
    List<cve__Payment__c> newList,
    Map<Id, cve__Payment__c> oldMap
  ) {
    Set<cve__Payment__c> paySet = new Set<cve__Payment__c>();
    Set<Id> psIds = new Set<Id>();
    List<cve__Adjustment__c> result = new List<cve__Adjustment__c>();
    for (cve__Payment__c pay : newList) {
      cve__Payment__c oldPay = oldMap.get(pay.id);
      if (
        pay.cve__Status__c != oldPay.cve__Status__c &&
        pay.cve__Status__c == 'Processed'
      ) {
        paySet.add(pay);
        psIds.add(pay.cve__PaymentSpecification__c);
      }
    }

    if (paySet.size() == 0) {
      return result;
    }

    List<cve__Adjustment__c> recoupAdj = [
      SELECT id, Recouped__c, cve__Start__c, cve__Through__c
      FROM cve__Adjustment__c
      WHERE
        cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
        AND cve__PaymentSpecification__c IN :psIds
    ];

    for (cve__Payment__c pay : paySet) {
      List<cve__Adjustment__c> adjList = findRecoupAdjustment(pay, recoupAdj);
      result.addAll(updateAdjustmentRecoupedField(adjList, true));
    }
    return result;
  }

  public List<cve__Adjustment__c> unlockRecoupOverpaymentAdjustment(
    List<cve__Payment__c> newList,
    Map<Id, cve__Payment__c> oldMap
  ) {
    Set<cve__Payment__c> paySet = new Set<cve__Payment__c>();
    Set<Id> psIds = new Set<Id>();
    List<cve__Adjustment__c> result = new List<cve__Adjustment__c>();
    for (cve__Payment__c pay : newList) {
      cve__Payment__c oldPay = oldMap.get(pay.id);
      if (
        pay.cve__Status__c != oldPay.cve__Status__c &&
        pay.cve__Status__c != 'Released' &&
        oldPay.cve__Status__c == 'Processed'
      ) {
        paySet.add(pay);
        psIds.add(pay.cve__PaymentSpecification__c);
      }
    }

    if (paySet.size() == 0) {
      return result;
    }

    List<cve__Adjustment__c> recoupAdj = [
      SELECT id, Recouped__c, cve__Start__c, cve__Through__c
      FROM cve__Adjustment__c
      WHERE
        cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
        AND cve__PaymentSpecification__c IN :psIds
    ];

    for (cve__Payment__c pay : paySet) {
      List<cve__Adjustment__c> adjList = findRecoupAdjustment(pay, recoupAdj);
      result.addAll(updateAdjustmentRecoupedField(adjList, false));
    }
    return result;
  }

  private List<cve__Adjustment__c> updateAdjustmentRecoupedField(
    List<cve__Adjustment__c> adjList,
    Boolean value
  ) {
    for (cve__Adjustment__c adj : adjList) {
      adj.Recouped__c = value;
    }
    return adjList;
  }

  public List<cve__Adjustment__c> findRecoupAdjustment(
    cve__Payment__c pay,
    List<cve__Adjustment__c> recoupAdj
  ) {
    List<cve__Adjustment__c> adjList = new List<cve__Adjustment__c>();
    for (cve__Adjustment__c adj : recoupAdj) {
      if (
        adj.cve__Start__c == pay.cve__Start__c &&
        adj.cve__Through__c == pay.cve__Through__c
      ) {
        adjList.add(adj);
      }
    }
    return adjList;
  }
}