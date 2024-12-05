public with sharing class RecoupOverpaymentTriggerHelper {
  RecoupOverpaymentAssistant assistant;
  Map<Id, cve__PaymentSpecification__c> paymentSpecMap;
  Map<Id, List<cve__PaymentSpecification__c>> priorPaymentSpecs;
  Map<Id, List<cve__Adjustment__c>> recoupAdjustments;
  Map<Id, List<cve__Adjustment__c>> recoupedAdjustments;
  Map<Id, List<cve__UnallocatedPayment__c>> upayMap;
  Map<String, Decimal> recoupedAmount;

  public static RecoupOverpaymentTriggerHelper getInstance() {
    return new RecoupOverpaymentTriggerHelper()
      .setRecoupOverpaymentAssistant(new RecoupOverpaymentAssistant());
  }

  private RecoupOverpaymentTriggerHelper setRecoupOverpaymentAssistant(
    RecoupOverpaymentAssistant assist
  ) {
    this.assistant = assist;
    return this;
  }

  public ReturnValues handleOverpayment(List<RecoupOverpayment__e> eventList) {
    ReturnValues result = new ReturnValues();
    this.paymentSpecMap = assistant.getPaymentSpecs(eventList);
    this.priorPaymentSpecs = assistant.getPriorPaymentSpecs(
      this.paymentSpecMap
    );
    this.recoupAdjustments = assistant.getRecoupAdjustments(
      this.paymentSpecMap
    );
    this.recoupedAdjustments = assistant.getRecoupedAdjustments(
      this.paymentSpecMap
    );
    this.upayMap = assistant.getUnallocatedPayments(this.paymentSpecMap);
    this.recoupedAmount = assistant.getRecoupedAmount(recoupedAdjustments);
    this.priorPaymentSpecs = assistant.addPriorSpecsFromRecoupAdj(
      priorPaymentSpecs,
      recoupAdjustments
    );

    for (cve__PaymentSpecification__c ps : paymentSpecMap.values()) {
      List<cve__PaymentSpecification__c> priorPs = priorPaymentSpecs.containsKey(
          ps.id
        )
        ? priorPaymentSpecs.get(ps.id)
        : new List<cve__PaymentSpecification__c>();
      Id key = ps.cvint__AbsenceClaim__c != null
        ? ps.cvint__AbsenceClaim__c
        : ps.cve__BenefitClaimed__c;
      List<cve__Adjustment__c> adjList = recoupAdjustments.containsKey(key)
        ? recoupAdjustments.get(key)
        : new List<cve__Adjustment__c>();
      List<cve__UnallocatedPayment__c> upayList = upayMap.containsKey(key)
        ? upayMap.get(key)
        : new List<cve__UnallocatedPayment__c>();
      if ((priorPs.size() > 0 || adjList.size() > 0) && upayList.size() > 0) {
        ReturnValues temp = recoupOverpayment(ps, priorPs, adjList, upayList);
        result.upMap.putAll(temp.upMap);
        result.adjMap.putAll(temp.adjMap);
      }
    }

    return result;
  }

  public List<cve__Adjustment__c> getAdjToBeDeleted() {
    List<cve__Adjustment__c> result = new List<cve__Adjustment__c>();
    for (Id key : recoupAdjustments.keySet()) {
      result.addAll(recoupAdjustments.get(key));
    }
    return result;
  }

  public List<cve__Adjustment__c> updateAdjToBeDeleted(
    List<cve__Adjustment__c> adjList
  ) {
    for (cve__Adjustment__c adj : adjList) {
      adj.UnallocatedPayment__c = null;
    }
    return adjList;
  }

  public List<cve__UnallocatedPayment__c> getUpayToBeDeleted(
    List<cve__Adjustment__c> adjList
  ) {
    Set<Id> upayIds = new Set<Id>();
    for (cve__Adjustment__c adj : adjList) {
      if (adj.UnallocatedPayment__c != null) {
        upayIds.add(adj.UnallocatedPayment__c);
      }
    }

    List<cve__Adjustment__c> recouped = new List<cve__Adjustment__c>();

    for (Id key : recoupedAdjustments.keySet()) {
      recouped.addAll(recoupedAdjustments.get(key));
    }

    for (cve__Adjustment__c adj : recouped) {
      List<cve__PaymentSpecification__c> priorPs = priorPaymentSpecs.containsKey(
          adj.cve__PaymentSpecification__c
        )
        ? priorPaymentSpecs.get(adj.cve__PaymentSpecification__c)
        : new List<cve__PaymentSpecification__c>();
      Set<Id> priorPsIds = new Map<Id, cve__PaymentSpecification__c>(priorPs)
        .keySet();
      if (
        adj.UnallocatedPayment__c != null &&
        priorPsIds.contains(adj.PriorPaymentSpecs__c)
      ) {
        upayIds.add(adj.UnallocatedPayment__c);
      }
    }

    List<cve__UnallocatedPayment__c> upayList = [
      SELECT
        id,
        cve__LumpSum__c,
        cve__LumpSumBeforeTaxes__c,
        cve__BeforeTaxesPaid__c,
        cve__Paid__c
      FROM cve__UnallocatedPayment__c
      WHERE id IN :upayIds
    ];

    for (cve__UnallocatedPayment__c up : upayList) {
      up.cve__LumpSum__c = 0;
      up.cve__LumpSumBeforeTaxes__c = 0;
      up.cve__BeforeTaxesPaid__c = 0;
      up.cve__Paid__c = 0;
    }

    return upayList;
  }

  private ReturnValues recoupOverpayment(
    cve__PaymentSpecification__c ps,
    List<cve__PaymentSpecification__c> priorPs,
    List<cve__Adjustment__c> adjList,
    List<cve__UnallocatedPayment__c> upayList
  ) {
    ReturnValues result = new ReturnValues();
    Decimal amountAvailable = getTotalAmount(upayList);
    if (amountAvailable <= 0) {
      return result;
    }
    for (cve__PaymentSpecification__c prior : priorPs) {
      if (prior.cve__OverpaymentBeforeTax__c < 0) {
        continue;
      }
      Id ref = ps.cvint__AbsenceClaim__c != null
        ? ps.cvint__AbsenceClaim__c
        : ps.cve__BenefitClaimed__c;
      String key = ref + ' ' + prior.id;
      Decimal amountRecouped = recoupedAmount.containsKey(key)
        ? recoupedAmount.get(key)
        : 0;
      List<cve__Adjustment__c> recoupedAdj = recoupedAdjustments.containsKey(
          ref
        )
        ? recoupedAdjustments.get(ref)
        : new List<cve__Adjustment__c>();
      List<cve__Adjustment__c> allAdj = new List<cve__Adjustment__c>();
      allAdj.addAll(recoupedAdj);
      allAdj.addAll(adjList);
      Decimal totalOverpayment =
        (prior.cve__OverpaymentBeforeTax__c +
        getAmountFromAdj(prior.id, allAdj)) - amountRecouped;
      List<cve__Adjustment__c> newAdjList = createAdjustments(
        prior,
        ps,
        upayList,
        totalOverpayment
      );
      Decimal coveredAmount = calculateCoveredAmount(
        upayList,
        amountRecouped,
        totalOverpayment,
        prior
      );
      cve__UnallocatedPayment__c newUpay = createUnallocatedPayment(
        coveredAmount,
        prior.id
      );
      if (newUpay != null) {
        result.upMap.put(key, newUpay);
        result.adjMap.put(key, newAdjList);
        amountAvailable -= coveredAmount;
        if (amountAvailable == 0) {
          break;
        }
      }
    }
    return result;
  }

  private Decimal getAmountFromAdj(
    Id priorId,
    List<cve__Adjustment__c> adjList
  ) {
    Decimal result = 0;
    for (cve__Adjustment__c adj : adjList) {
      if (adj.PriorPaymentSpecs__c == priorId) {
        result = adj.UnallocatedPayment__c != null
          ? (adj.UnallocatedPayment__r.cve__LumpSum__c * -1)
          : 0;
      }
    }
    return result;
  }

  private Decimal getTotalAmount(List<cve__UnallocatedPayment__c> payments) {
    Decimal total = 0;
    for (cve__UnallocatedPayment__c pay : payments) {
      total += pay.cve__NetBeforeTaxes__c;
    }
    return total;
  }

  public cve__UnallocatedPayment__c createUnallocatedPayment(
    Decimal coveredAmount,
    Id psId
  ) {
    if (coveredAmount == 0) {
      return null;
    }
    Decimal amount = coveredAmount * -1;
    id repaymentRecordTypeId = Schema.getGlobalDescribe()
      .get('cve__UnallocatedPayment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Lump Sum Repayment')
      .getRecordTypeId();
    return new cve__UnallocatedPayment__c(
      cve__Start__c = Date.Today(),
      RecordTypeId = repaymentRecordTypeId,
      cve__PaymentSpecification__c = psId,
      cve__LumpSum__c = amount,
      cve__LumpSumBeforeTaxes__c = amount,
      cve__BeforeTaxesPaid__c = amount,
      cve__Paid__c = amount
    );
  }

  private Decimal calculateCoveredAmount(
    List<cve__UnallocatedPayment__c> payments,
    Decimal amountAlreadyCovered,
    Decimal overpayment,
    cve__PaymentSpecification__c priorPs
  ) {
    Decimal coveredAmount = 0;
    for (cve__UnallocatedPayment__c pay : payments) {
      Decimal amount = 0;
      if (overpayment >= pay.cve__NetBeforeTaxes__c) {
        coveredAmount += pay.cve__NetBeforeTaxes__c;
        amount = pay.cve__NetBeforeTaxes__c;
      } else {
        coveredAmount += overpayment;
        amount = overpayment;
      }
      overpayment -= amount;
      if (overpayment == 0) {
        break;
      }
    }
    return coveredAmount + amountAlreadyCovered;
  }

  private List<cve__Adjustment__c> createAdjustments(
    cve__PaymentSpecification__c priorPs,
    cve__PaymentSpecification__c ps,
    List<cve__UnallocatedPayment__c> payments,
    Decimal overpayment
  ) {
    List<cve__Adjustment__c> result = new List<cve__Adjustment__c>();
    for (cve__UnallocatedPayment__c pay : payments) {
      cve__Adjustment__c adj;
      Decimal amount = 0;
      Date startDate = ps != null &&
        ps.cve__BenefitClaimed__c != null &&
        ps.cve__BenefitClaimed__r.cve__AdjustedBenefitStart__c != null &&
        ps.cve__BenefitClaimed__r.cve__AdjustedBenefitStart__c >
        pay.cve__Start__c
        ? ps.cve__BenefitClaimed__r.cve__AdjustedBenefitStart__c
        : pay.cve__Start__c;
      if (overpayment >= pay.cve__NetBeforeTaxes__c) {
        adj = new cve__Adjustment__c(
          cve__Type__c = 'Recoup Overpayment (Pre-Tax)',
          cve__Start__c = startDate,
          cve__Through__c = pay.cve__Through__c,
          cve__Amount__c = (pay.cve__NetBeforeTaxes__c /
          (startDate.daysBetween(pay.cve__Through__c) + 1)),
          cve__Period__c = ps.cve__AmountPeriod__c == 'Lump Sum'
            ? 'Lump Sum'
            : 'Daily',
          cve__PaymentSpecification__c = pay.cve__PaymentSpecification__c,
          PriorPaymentSpecs__c = priorPs.id
        );
        amount = pay.cve__NetBeforeTaxes__c;
      } else {
        adj = new cve__Adjustment__c(
          cve__Type__c = 'Recoup Overpayment (Pre-Tax)',
          cve__Start__c = startDate,
          cve__Through__c = pay.cve__Through__c,
          cve__Amount__c = (overpayment /
          (startDate.daysBetween(pay.cve__Through__c) + 1)),
          cve__Period__c = ps.cve__AmountPeriod__c == 'Lump Sum'
            ? 'Lump Sum'
            : 'Daily',
          cve__PaymentSpecification__c = pay.cve__PaymentSpecification__c,
          PriorPaymentSpecs__c = priorPs.id
        );
        amount = overpayment;
      }
      overpayment -= amount;
      result.add(adj);
      if (overpayment == 0) {
        break;
      }
    }
    return result;
  }

  public List<cve__Adjustment__c> updateNewAdjustments(ReturnValues values) {
    List<cve__Adjustment__c> result = new List<cve__Adjustment__c>();
    for (String key : values.adjMap.keySet()) {
      Id upId = values.upMap.get(key).id;
      for (cve__Adjustment__c adj : values.adjMap.get(key)) {
        adj.UnallocatedPayment__c = upId;
        result.add(adj);
      }
    }
    return result;
  }

  public List<cve__Adjustment__c> updateRecoupedAdjustments(
    ReturnValues values
  ) {
    List<cve__Adjustment__c> result = new List<cve__Adjustment__c>();

    for (Id key : recoupedAdjustments.keySet()) {
      for (cve__Adjustment__c adj : recoupedAdjustments.get(key)) {
        String upKey = key + ' ' + adj.PriorPaymentSpecs__c;
        if (values.upMap.containsKey(upKey)) {
          adj.UnallocatedPayment__c = values.upMap.get(upKey).id;
          result.add(adj);
        } else if (adj.UnallocatedPayment__r.cve__LumpSum__c == 0) {
          Decimal amount = recoupedAmount.containsKey(upKey)
            ? recoupedAmount.get(upKey)
            : 0;
          adj.UnallocatedPayment__r.cve__LumpSum__c = amount * -1;
          adj.UnallocatedPayment__r.cve__LumpSumBeforeTaxes__c = amount * -1;
          adj.UnallocatedPayment__r.cve__BeforeTaxesPaid__c = amount * -1;
          adj.UnallocatedPayment__r.cve__Paid__c = amount * -1;

          result.add(adj);
        }
      }
    }

    return result;
  }

  public List<RecalculatePayments__e> createEvents(
    List<cve__Adjustment__c> adjList
  ) {
    Set<id> paymentSpecIds = new Set<Id>();
    List<RecalculatePayments__e> eventList = new List<RecalculatePayments__e>();
    for (cve__Adjustment__c adj : adjList) {
      paymentSpecIds.add(adj.cve__PaymentSpecification__c);
      paymentSpecIds.add(adj.PriorPaymentSpecs__c);
    }
    for (Id psId : paymentSpecIds) {
      eventList.add(
        new RecalculatePayments__e(
          PaymentSpecificationId__c = psId,
          DeleteZeroAdjustments__c = true
        )
      );
    }

    return eventList;
  }

  public List<cve__Payment__c> createPayments(
    List<cve__UnallocatedPayment__c> upList
  ) {
    List<cve__Payment__c> result = new List<cve__Payment__c>();
    Set<Id> paymentSpecIds = new Set<Id>();
    for (cve__UnallocatedPayment__c up : upList) {
      paymentSpecIds.add(up.cve__PaymentSpecification__c);
    }
    id calculatedId = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Calculated')
      .getRecordTypeId();
    List<cve__Payment__c> paymentList = [
      SELECT id, cve__Contact__c, cve__PaymentSpecification__c
      FROM cve__Payment__c
      WHERE
        cve__PaymentSpecification__c IN :paymentSpecIds
        AND RecordTypeId = :calculatedId
    ];
    Map<Id, Id> payeeMap = new Map<Id, Id>();
    for (cve__Payment__c pay : paymentList) {
      payeeMap.put(pay.cve__PaymentSpecification__c, pay.cve__Contact__c);
    }
    Id repaymentRecordTypeId = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Lump Sum Repayment')
      .getRecordTypeId();
    for (cve__UnallocatedPayment__c up : upList) {
      cve__Payment__c p = new cve__Payment__c(
        RecordTypeId = repaymentRecordTypeId,
        cve__UnallocatedPayment__c = up.Id,
        cve__PaymentSpecification__c = up.cve__PaymentSpecification__c,
        cve__Start__c = up.cve__Start__c,
        cve__Through__c = (null != up.cve__Through__c)
          ? up.cve__Through__c
          : up.cve__Start__c,
        cve__Payable__c = up.cve__Start__c,
        cve__Status__c = 'Processed',
        cve__NetBeforeTaxes__c = up.cve__LumpSumBeforeTaxes__c,
        cve__NetAfterTaxes__c = up.cve__LumpSum__c,
        cve__Net__c = up.cve__LumpSum__c,
        cve__Contact__c = payeeMap.get(up.cve__PaymentSpecification__c)
      );
      result.add(p);
    }
    return result;
  }

  public List<cve__ExplanationOfBenefit__c> createEob(
    List<cve__Payment__c> paymentList
  ) {
    List<cve__ExplanationOfBenefit__c> result = new List<cve__ExplanationOfBenefit__c>();
    id recordTypeId = Schema.getGlobalDescribe()
      .get('cve__ExplanationOfBenefit__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Explanation')
      .getRecordTypeId();
    for (cve__Payment__c p : paymentList) {
      cve__ExplanationOfBenefit__c eob = new cve__ExplanationOfBenefit__c(
        cve__Description__c = 'Lump Sum EOB',
        cve__Start__c = p.cve__Start__c,
        cve__Through__c = p.cve__Through__c,
        cve__Amount__c = p.cve__NetAfterTaxes__c,
        cve__Payment__c = p.Id,
        RecordTypeId = recordTypeId
      );
      result.add(eob);
    }
    return result;
  }

  public class ReturnValues {
    public Map<String, cve__UnallocatedPayment__c> upMap;
    public Map<String, List<cve__Adjustment__c>> adjMap;
    public ReturnValues() {
      this.upMap = new Map<String, cve__UnallocatedPayment__c>();
      this.adjMap = new Map<String, List<cve__Adjustment__c>>();
    }
  }
}