public with sharing class RecoupOverpaymentAssistant {
  public Map<Id, cve__PaymentSpecification__c> getPaymentSpecs(
    List<RecoupOverpayment__e> eventList
  ) {
    Set<Id> psIds = new Set<Id>();
    for (RecoupOverpayment__e event : eventList) {
      psIds.add(event.PaymentSpecificationId__c);
    }

    List<cve__PaymentSpecification__c> psList = [
      SELECT
        id,
        cve__OverpaymentBeforeTax__c,
        cvint__AbsenceClaim__c,
        cve__Claim__c,
        cve__AmountPeriod__c,
        cve__BenefitClaimed__c,
        cve__BenefitClaimed__r.cve__AdjustedBenefitStart__c
      FROM cve__PaymentSpecification__c
      WHERE id IN :psIds
    ];
    return new Map<Id, cve__PaymentSpecification__c>(psList);
  }

  public Map<Id, List<cve__PaymentSpecification__c>> getPriorPaymentSpecs(
    Map<Id, cve__PaymentSpecification__c> paymentSpecMap
  ) {
    Map<Id, List<cve__PaymentSpecification__c>> result = new Map<Id, List<cve__PaymentSpecification__c>>();
    HandleCvabOverpaymentAssistant cvabAssist = new HandleCvabOverpaymentAssistant(
      getCvabPs(paymentSpecMap.values())
    );
    HandleCveOverpaymentAssistant cveAssist = new HandleCveOverpaymentAssistant(
      getCvePs(paymentSpecMap.values())
    );
    result.putAll(cvabAssist.getPriorPaymentSpecs());
    result.putAll(cveAssist.getPriorPaymentSpecs());
    for (cve__PaymentSpecification__c ps : paymentSpecMap.values()) {
      if (!result.containsKey(ps.id)) {
        result.put(ps.id, new List<cve__PaymentSpecification__c>());
      }
    }

    return result;
  }

  private List<cve__PaymentSpecification__c> getCvabPs(
    List<cve__PaymentSpecification__c> psList
  ) {
    List<cve__PaymentSpecification__c> result = new List<cve__PaymentSpecification__c>();
    for (cve__PaymentSpecification__c ps : psList) {
      if (ps.cvint__AbsenceClaim__c != null) {
        result.add(ps);
      }
    }
    return result;
  }

  private List<cve__PaymentSpecification__c> getCvePs(
    List<cve__PaymentSpecification__c> psList
  ) {
    List<cve__PaymentSpecification__c> result = new List<cve__PaymentSpecification__c>();
    for (cve__PaymentSpecification__c ps : psList) {
      if (ps.cve__Claim__c != null) {
        result.add(ps);
      }
    }
    return result;
  }

  public Map<Id, List<cve__Adjustment__c>> getRecoupAdjustments(
    Map<Id, cve__PaymentSpecification__c> paymentSpecMap
  ) {
    Set<Id> cvabClaimIds = new Set<Id>();
    Set<Id> bcIds = new Set<Id>();
    Map<Id, List<cve__Adjustment__c>> result = new Map<Id, List<cve__Adjustment__c>>();

    for (cve__PaymentSpecification__c ps : paymentSpecMap.values()) {
      if (ps.cvint__AbsenceClaim__c != null) {
        cvabClaimIds.add(ps.cvint__AbsenceClaim__c);
      }
      if (ps.cve__BenefitClaimed__c != null) {
        bcIds.add(ps.cve__BenefitClaimed__c);
      }
    }

    List<cve__Adjustment__c> adjList = [
      SELECT
        id,
        cve__Start__c,
        cve__Through__c,
        cve__PaymentSpecification__c,
        PriorPaymentSpecs__c,
        UnallocatedPayment__c,
        UnallocatedPayment__r.cve__LumpSum__c,
        Recouped__c,
        cve__PaymentSpecification__r.cvint__AbsenceClaim__c,
        cve__PaymentSpecification__r.cve__BenefitClaimed__c
      FROM cve__Adjustment__c
      WHERE
        cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
        AND (cve__PaymentSpecification__r.cvint__AbsenceClaim__c IN :cvabClaimIds
        OR cve__PaymentSpecification__r.cve__BenefitClaimed__c IN :bcIds)
        AND Recouped__c = FALSE
    ];

    for (cve__PaymentSpecification__c ps : paymentSpecMap.values()) {
      if (ps.cvint__AbsenceClaim__c != null) {
        result.put(
          ps.cvint__AbsenceClaim__c,
          getAdjustments(adjList, ps.cvint__AbsenceClaim__c)
        );
      }
      if (ps.cve__BenefitClaimed__c != null) {
        result.put(
          ps.cve__BenefitClaimed__c,
          getAdjustments(adjList, ps.cve__BenefitClaimed__c)
        );
      }
    }

    return result;
  }

  private List<cve__Adjustment__c> getAdjustments(
    List<cve__Adjustment__c> adjList,
    Id ref
  ) {
    List<cve__Adjustment__c> result = new List<cve__Adjustment__c>();
    for (cve__Adjustment__c adj : adjList) {
      if (
        adj.cve__PaymentSpecification__r.cvint__AbsenceClaim__c == ref ||
        adj.cve__PaymentSpecification__r.cve__BenefitClaimed__c == ref
      ) {
        result.add(adj);
      }
    }
    return result;
  }

  private List<cve__UnallocatedPayment__c> getUnallocatedPayments(
    List<cve__UnallocatedPayment__c> upayList,
    Id ref
  ) {
    List<cve__UnallocatedPayment__c> result = new List<cve__UnallocatedPayment__c>();
    for (cve__UnallocatedPayment__c upay : upayList) {
      if (
        upay.cve__PaymentSpecification__r.cvint__AbsenceClaim__c == ref ||
        upay.cve__PaymentSpecification__r.cve__BenefitClaimed__c == ref
      ) {
        result.add(upay);
      }
    }
    return result;
  }

  public Map<Id, List<cve__Adjustment__c>> getRecoupedAdjustments(
    Map<Id, cve__PaymentSpecification__c> paymentSpecMap
  ) {
    Set<Id> cvabClaimIds = new Set<Id>();
    Set<Id> bcIds = new Set<Id>();
    Map<Id, List<cve__Adjustment__c>> result = new Map<Id, List<cve__Adjustment__c>>();

    for (cve__PaymentSpecification__c ps : paymentSpecMap.values()) {
      if (ps.cvint__AbsenceClaim__c != null) {
        cvabClaimIds.add(ps.cvint__AbsenceClaim__c);
      }
      if (ps.cve__BenefitClaimed__c != null) {
        bcIds.add(ps.cve__BenefitClaimed__c);
      }
    }

    List<cve__Adjustment__c> adjList = [
      SELECT
        id,
        cve__Start__c,
        cve__Through__c,
        cve__PaymentSpecification__c,
        PriorPaymentSpecs__c,
        UnallocatedPayment__c,
        Recouped__c,
        cve__PaymentSpecification__r.cvint__AbsenceClaim__c,
        cve__PaymentSpecification__r.cve__BenefitClaimed__c,
        UnallocatedPayment__r.cve__LumpSum__c
      FROM cve__Adjustment__c
      WHERE
        cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
        AND (cve__PaymentSpecification__r.cvint__AbsenceClaim__c IN :cvabClaimIds
        OR cve__PaymentSpecification__r.cve__BenefitClaimed__c IN :bcIds)
        AND Recouped__c = TRUE
    ];

    for (cve__PaymentSpecification__c ps : paymentSpecMap.values()) {
      if (ps.cvint__AbsenceClaim__c != null) {
        result.put(
          ps.cvint__AbsenceClaim__c,
          getAdjustments(adjList, ps.cvint__AbsenceClaim__c)
        );
      }
      if (ps.cve__BenefitClaimed__c != null) {
        result.put(
          ps.cve__BenefitClaimed__c,
          getAdjustments(adjList, ps.cve__BenefitClaimed__c)
        );
      }
    }

    return result;
  }

  public Map<Id, List<cve__PaymentSpecification__c>> addPriorSpecsFromRecoupAdj(
    Map<Id, List<cve__PaymentSpecification__c>> priorMap,
    Map<Id, List<cve__Adjustment__c>> recoupAdjMap
  ) {
    Set<Id> priorIds = new Set<Id>();
    List<cve__Adjustment__c> adjList = new List<cve__Adjustment__c>();
    for (Id key : recoupAdjMap.keySet()) {
      for (cve__Adjustment__c adj : recoupAdjMap.get(key)) {
        if (adj.PriorPaymentSpecs__c != null) {
          priorIds.add(adj.PriorPaymentSpecs__c);
          adjList.add(adj);
        }
      }
    }

    Map<Id, cve__PaymentSpecification__c> priorPsMap = new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT id, cve__OverpaymentBeforeTax__c
        FROM cve__PaymentSpecification__c
        WHERE id IN :priorIds
      ]
    );

    for (cve__Adjustment__c adj : adjList) {
      cve__PaymentSpecification__c prior = priorPsMap.get(
        adj.PriorPaymentSpecs__c
      );
      if (priorMap.containsKey(adj.cve__PaymentSpecification__c)) {
        List<cve__PaymentSpecification__c> temp = priorMap.get(
          adj.cve__PaymentSpecification__c
        );
        Set<Id> psIds = new Map<Id, cve__PaymentSpecification__c>(temp)
          .KeySet();
        if (!psIds.contains(prior.id)) {
          temp.add(prior);
        }
        priorMap.put(adj.cve__PaymentSpecification__c, temp);
      } else {
        List<cve__PaymentSpecification__c> temp = new List<cve__PaymentSpecification__c>();
        temp.add(prior);
        priorMap.put(adj.cve__PaymentSpecification__c, temp);
      }
    }
    return priorMap;
  }

  public Map<Id, List<cve__UnallocatedPayment__c>> getUnallocatedPayments(
    Map<Id, cve__PaymentSpecification__c> paymentSpecMap
  ) {
    Id calculatedId = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Calculated')
      .getRecordTypeId();

    Set<Id> cvabClaimIds = new Set<Id>();
    Set<String> statuses = new Set<String>{ 'Pending', 'Approved' };
    Set<Id> bcIds = new Set<Id>();
    Map<Id, List<cve__UnallocatedPayment__c>> result = new Map<Id, List<cve__UnallocatedPayment__c>>();

    for (cve__PaymentSpecification__c ps : paymentSpecMap.values()) {
      if (ps.cvint__AbsenceClaim__c != null) {
        cvabClaimIds.add(ps.cvint__AbsenceClaim__c);
      }
      if (ps.cve__BenefitClaimed__c != null) {
        bcIds.add(ps.cve__BenefitClaimed__c);
      }
    }

    List<cve__Payment__c> payList = [
      SELECT id, cve__UnallocatedPayment__c, cve__Status__c
      FROM cve__Payment__c
      WHERE
        cve__Status__c IN :statuses
        AND (cve__PaymentSpecification__r.cvint__AbsenceClaim__c IN :cvabClaimIds
        OR cve__PaymentSpecification__r.cve__BenefitClaimed__c IN :bcIds)
        AND RecordTypeId = :calculatedId
    ];

    Set<Id> upayIds = new Set<Id>();

    for (cve__Payment__c pay : payList) {
      upayIds.add(pay.cve__UnallocatedPayment__c);
    }
    List<cve__UnallocatedPayment__c> upayList = [
      SELECT
        id,
        cve__Start__c,
        cve__Through__c,
        cve__NetBeforeTaxes__c,
        cve__PaymentSpecification__c,
        cve__PaymentSpecification__r.cvint__AbsenceClaim__c,
        cve__PaymentSpecification__r.cve__BenefitClaimed__c
      FROM cve__UnallocatedPayment__c
      WHERE cve__NetBeforeTaxes__c > 0 AND id IN :upayIds
    ];
    for (cve__PaymentSpecification__c ps : paymentSpecMap.values()) {
      if (ps.cvint__AbsenceClaim__c != null) {
        result.put(
          ps.cvint__AbsenceClaim__c,
          getUnallocatedPayments(upayList, ps.cvint__AbsenceClaim__c)
        );
      }
      if (ps.cve__BenefitClaimed__c != null) {
        result.put(
          ps.cve__BenefitClaimed__c,
          getUnallocatedPayments(upayList, ps.cve__BenefitClaimed__c)
        );
      }
    }

    return result;
  }

  public Map<String, Decimal> getRecoupedAmount(
    Map<Id, List<cve__Adjustment__c>> recoupedAdjMap
  ) {
    Map<String, Decimal> result = new Map<String, Decimal>();
    Set<Id> adjIds = getRecoupedAdjIds(recoupedAdjMap);
    List<cve__AppliedAdjustment__c> appliedAdj = [
      SELECT
        id,
        cve__Amount__c,
        cve__Adjustment__r.PriorPaymentSpecs__c,
        cve__Adjustment__r.cve__PaymentSpecification__r.cvint__AbsenceClaim__c,
        cve__Adjustment__r.cve__PaymentSpecification__r.cve__BenefitClaimed__c
      FROM cve__AppliedAdjustment__c
      WHERE cve__Adjustment__c IN :adjIds
    ];
    for (cve__AppliedAdjustment__c adj : appliedAdj) {
      Id ref = adj.cve__Adjustment__r.cve__PaymentSpecification__r.cvint__AbsenceClaim__c !=
        null
        ? adj.cve__Adjustment__r.cve__PaymentSpecification__r.cvint__AbsenceClaim__c
        : adj.cve__Adjustment__r.cve__PaymentSpecification__r.cve__BenefitClaimed__c;
      String key = ref + ' ' + adj.cve__Adjustment__r.PriorPaymentSpecs__c;
      if (result.containsKey(key)) {
        Decimal sum = result.get(key) + adj.cve__Amount__c;
        result.put(key, sum);
      } else {
        result.put(key, adj.cve__Amount__c);
      }
    }
    return result;
  }

  private Set<Id> getRecoupedAdjIds(
    Map<Id, List<cve__Adjustment__c>> recoupedAdjMap
  ) {
    Set<Id> result = new Set<Id>();
    for (Id key : recoupedAdjMap.keySet()) {
      result.addAll(
        new Map<Id, cve__Adjustment__c>(recoupedAdjMap.get(key)).keySet()
      );
    }
    return result;
  }
}