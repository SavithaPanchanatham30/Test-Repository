public with sharing class PaymentSpecificationTriggerHelper {
  private static PaymentSpecificationTriggerHelper instance;
  private PaymentSpecificationTriggerHandler.ContextVariables contxtVars;

  private Map<Id, cvab__Claim__c> cvabClaimsByPaymentSpecId;
  private Map<Id, cve__Claim__c> cveClaimsByPaymentSpecId;

  public static PaymentSpecificationTriggerHelper getInstance() {
    if (instance == null) {
      instance = new PaymentSpecificationTriggerHelper();
    }
    return instance;
  }

  public PaymentSpecificationTriggerHelper withContextVars(
    PaymentSpecificationTriggerHandler.ContextVariables contxtVars
  ) {
    this.contxtVars = contxtVars;
    return this;
  }

  public List<cve__PaymentSpecification__c> populateClaimants() {
    List<Id> claimIds = getClaimIds(contxtVars.newList);
    if (claimIds != null && claimIds.size() > 0) {
      cvabClaimsByPaymentSpecId = new Map<Id, cvab__Claim__c>(
        [SELECT cvab__Employee__c FROM cvab__Claim__c WHERE Id IN :claimIds]
      );
      cveClaimsByPaymentSpecId = new Map<Id, cve__Claim__c>(
        [
          SELECT cve__ClaimantInsured__c
          FROM cve__Claim__c
          WHERE Id IN :claimIds
        ]
      );
      for (cve__PaymentSpecification__c ps : contxtVars.newList) {
        if (ps.cvint__AbsenceClaim__c != null || ps.cve__Claim__c != null) {
          ps.Claimant__c = getClaimantId(ps);
        }
      }
    }

    return contxtVars.newList;
  }

  public void disableFicaAdjustments() {
    Set<Id> cvabClaimIds = new Set<Id>();
    Set<Id> bcIds = new Set<Id>();
    for (cve__PaymentSpecification__c ps : contxtVars.newList) {
      if (ps.cvint__AbsenceClaim__c != null) {
        cvabClaimIds.add(ps.cvint__AbsenceClaim__c);
      } else if (ps.cve__BenefitClaimed__c != null) {
        bcIds.add(ps.cve__BenefitClaimed__c);
      }
    }

    cvabClaimIds = getCvabClaim(cvabClaimIds);
    bcIds = getBc(bcIds);

    for (cve__PaymentSpecification__c ps : contxtVars.newList) {
      if (
        ps.cvint__AbsenceClaim__c != null &&
        cvabClaimIds.contains(ps.cvint__AbsenceClaim__c)
      ) {
        ps.cve__DisabledAutomatedAdjustmentTypes__c = 'FICA Tax';
      } else if (
        ps.cve__BenefitClaimed__c != null &&
        bcIds.contains(ps.cve__BenefitClaimed__c)
      ) {
        ps.cve__DisabledAutomatedAdjustmentTypes__c = 'FICA Tax';
      }
    }
  }

  private Set<Id> getCvabClaim(Set<Id> cvabIds) {
    return new Map<Id, cvab__Claim__c>(
        [
          SELECT id
          FROM cvab__Claim__c
          WHERE
            id IN :cvabIds
            AND cvab__Employee__r.Account.SocialSecurityExempt__c = TRUE
        ]
      )
      .keySet();
  }

  private Set<Id> getBc(Set<Id> bcIds) {
    return new Map<Id, cve__BenefitClaimed__c>(
        [
          SELECT id
          FROM cve__BenefitClaimed__c
          WHERE
            id IN :bcIds
            AND cve__ClaimantInsured__r.Account.SocialSecurityExempt__c = TRUE
        ]
      )
      .keySet();
  }

  private List<Id> getClaimIds(List<cve__PaymentSpecification__c> psList) {
    List<Id> claimIds = new List<Id>();

    for (cve__PaymentSpecification__c ps : psList) {
      if (belongsToAbsenceClaim(ps)) {
        claimIds.add(ps.cvint__AbsenceClaim__c);
      } else {
        claimIds.add(ps.cve__Claim__c);
      }
    }

    return claimIds;
  }

  private Boolean belongsToAbsenceClaim(cve__PaymentSpecification__c ps) {
    Boolean belongsToAbsenceClaim =
      ps != null &&
      ps.cvint__AbsenceClaim__c != null;

    return belongsToAbsenceClaim;
  }

  private Id getClaimantId(cve__PaymentSpecification__c ps) {
    if (belongsToAbsenceClaim(ps)) {
      return cvabClaimsByPaymentSpecId.get(ps.cvint__AbsenceClaim__c)
        .cvab__Employee__c;
    } else {
      return cveClaimsByPaymentSpecId.get(ps.cve__Claim__c)
        .cve__ClaimantInsured__c;
    }
  }

  public Map<Id, cve__PaymentSpecification__c> checkIfOverpaymentIsUpdated(
    Map<Id, cve__PaymentSpecification__c> oldMap,
    Map<Id, cve__PaymentSpecification__c> newMap
  ) {
    Map<Id, cve__PaymentSpecification__c> result = new Map<Id, cve__PaymentSpecification__c>();
    for (cve__PaymentSpecification__c newPs : newMap.values()) {
      cve__PaymentSpecification__c oldPs = oldMap.get(newPs.id);
      if (
        newPs.cve__OverpaymentNet__c != oldPs.cve__OverpaymentNet__c &&
        newPs.cvint__AbsenceClaim__c != null
      ) {
        result.put(newPs.id, newPs);
      }
    }
    return result;
  }

  public List<cvab__Claim__c> aggregateCvabOverpaymentAmount() {
    Map<Id, cve__PaymentSpecification__c> paymentMap;
    if (contxtVars.oldMap != null && contxtVars.newMap != null) {
      paymentMap = checkIfOverpaymentIsUpdated(
        contxtVars.oldMap,
        contxtVars.newMap
      );
    } else if (contxtVars.newMap != null) {
      paymentMap = contxtVars.newMap;
    } else {
      paymentMap = contxtVars.oldMap;
    }
    Set<Id> absenceClaimIds = new Set<Id>();
    List<cvab__Claim__c> result = new List<cvab__Claim__c>();

    if (paymentMap.values().size() == 0) {
      return result;
    }

    for (cve__PaymentSpecification__c ps : paymentMap.values()) {
      if (ps.cvint__AbsenceClaim__c != null) {
        absenceClaimIds.add(ps.cvint__AbsenceClaim__c);
      }
    }

    Map<Id, cvab__Claim__c> claimMap = getCvabClaims(absenceClaimIds);
    List<AggregateResult> sumOfOverpayment = [
      SELECT SUM(cve__OverpaymentNet__c) overpayment, cvint__AbsenceClaim__c
      FROM cve__PaymentSpecification__c
      WHERE cvint__AbsenceClaim__c IN :absenceClaimIds
      GROUP BY cvint__AbsenceClaim__c
    ];

    Map<Id, Decimal> aggregateMap = new Map<Id, Decimal>();
    for (Id claimId : claimMap.keySet()) {
      aggregateMap.put(claimId, 0);
    }

    for (AggregateResult ar : sumOfOverpayment) {
      aggregateMap.put(
        (Id) ar.get('cvint__AbsenceClaim__c'),
        (Decimal) ar.get('overpayment')
      );
    }

    for (cvab__Claim__c claim : claimMap.values()) {
      claim.TotalOverpayments__c = aggregateMap.get(claim.id);
      result.add(claim);
    }

    return result;
  }

  public Map<Id, cvab__Claim__c> getCvabClaims(Set<Id> claimIds) {
    return new Map<Id, cvab__Claim__c>(
      [
        SELECT Id, TotalOverpayments__c
        FROM cvab__Claim__c
        WHERE id IN :claimIds
      ]
    );
  }

  public List<cve__PaymentSpecification__c> checkIfPaymentsShouldBeApproved() {
    List<cve__PaymentSpecification__c> result = new List<cve__PaymentSpecification__c>();
    if (contxtVars.newMap == null || contxtVars.oldMap == null) {
      return result;
    }
    for (cve__PaymentSpecification__c ps : contxtVars.newMap.values()) {
      cve__PaymentSpecification__c oldPs = contxtVars.oldMap.get(ps.id);
      if (
        oldPs != null &&
        ps != null &&
        oldPs.PaymentApprovalStatus__c == 'Submitted For Approval' &&
        (ps.PaymentApprovalStatus__c == 'Approved' ||
        ps.PaymentApprovalStatus__c == 'Rejected')
      ) {
        result.add(ps);
      }
    }
    return result;
  }

  public List<Id> checkIfConsolidationIsNeeded(
    List<cve__PaymentSpecification__c> paymentSpecs
  ) {
    Map<Id, cve__PaymentSpecification__c> psMap = new Map<Id, cve__PaymentSpecification__c>(
      paymentSpecs
    );
    Map<Id, cve__PaymentSpecification__c> result = new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT id
        FROM cve__PaymentSpecification__c
        WHERE
          (cvint__AbsenceClaim__r.ExpressPaid__c = TRUE
          OR cve__Claim__r.Autopay__c = TRUE
          OR cve__Claim__r.ExpressPaid__c = TRUE)
          AND id IN :psMap.keySet()
          AND PaymentApprovalStatus__c = 'Approved'
      ]
    );
    return new List<id>(result.keySet());
  }

  public List<cve__Payment__c> updateTheStatus(
    List<cve__PaymentSpecification__c> psList
  ) {
    Map<Id, cve__PaymentSpecification__c> psMap = new Map<Id, cve__PaymentSpecification__c>(
      psList
    );
    Set<Id> paymentSpecIds = psMap.keySet();
    List<cve__Payment__c> result = [
      SELECT id, cve__Status__c, cve__PaymentSpecification__c
      FROM cve__Payment__c
      WHERE
        cve__PaymentSpecification__c IN :paymentSpecIds
        AND cve__Status__c = 'Submitted for Approval'
    ];
    for (cve__Payment__c pay : result) {
      String status = psMap.get(pay.cve__PaymentSpecification__c)
        .PaymentApprovalStatus__c;
      pay.cve__Status__c = status == 'Approved' ? status : 'Pending';
    }
    return result;
  }

  public ReturnValues deleteRecoupment(
    List<cve__PaymentSpecification__c> newList,
    Map<Id, cve__PaymentSpecification__c> oldMap
  ) {
    Set<Id> psIds = new Set<Id>();
    ReturnValues values = new ReturnValues();

    if (newList == null || oldMap == null) {
      return values;
    }

    for (cve__PaymentSpecification__c ps : newList) {
      cve__PaymentSpecification__c oldPs = oldMap.get(ps.id);
      if (
        ps.ClaimLeaveStatus__c != oldPs.ClaimLeaveStatus__c &&
        (ps.ClaimLeaveStatus__c == 'Denied' ||
        ps.ClaimLeaveStatus__c == 'Cancelled')
      ) {
        psIds.add(ps.id);
      }
    }

    if (psIds.size() == 0) {
      return values;
    }

    List<cve__Adjustment__c> adjList = getAdjustments(psIds);

    List<cve__UnallocatedPayment__c> upList = getUnallocatedPayments(adjList);

    List<RecalculatePayments__e> eventList = getEvents(psIds, adjList);

    values.adjList.addAll(adjList);
    values.upayList.addAll(upList);
    values.eventList.addAll(eventList);

    return values;
  }

  private List<cve__Adjustment__c> getAdjustments(Set<Id> psIds) {
    return [
      SELECT id, UnallocatedPayment__c, PriorPaymentSpecs__c
      FROM cve__Adjustment__c
      WHERE
        cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
        AND cve__PaymentSpecification__c IN :psIds
    ];
  }

  private List<cve__UnallocatedPayment__c> getUnallocatedPayments(
    List<cve__Adjustment__c> adjList
  ) {
    Set<Id> upayIds = new Set<Id>();

    for (cve__Adjustment__c adj : adjList) {
      if (adj.UnallocatedPayment__c != null) {
        upayIds.add(adj.UnallocatedPayment__c);
      }
    }

    List<cve__UnallocatedPayment__c> upList = [
      SELECT id
      FROM cve__UnallocatedPayment__c
      WHERE id IN :upayIds
    ];

    return upList;
  }

  private List<RecalculatePayments__e> getEvents(
    Set<Id> psIds,
    List<cve__Adjustment__c> adjList
  ) {
    Set<Id> priorIds = new Set<Id>();

    for (cve__Adjustment__c adj : adjList) {
      if (adj.PriorPaymentSpecs__c != null) {
        priorIds.add(adj.PriorPaymentSpecs__c);
      }
    }

    List<RecalculatePayments__e> eventList = new List<RecalculatePayments__e>();

    for (Id psId : psIds) {
      eventList.add(
        new RecalculatePayments__e(PaymentSpecificationId__c = psId)
      );
    }

    for (Id psId : priorIds) {
      eventList.add(
        new RecalculatePayments__e(PaymentSpecificationId__c = psId)
      );
    }

    return eventList;
  }

  public class ReturnValues {
    public List<cve__UnallocatedPayment__c> upayList;
    public List<cve__Adjustment__c> adjList;
    public List<RecalculatePayments__e> eventList;

    public ReturnValues() {
      this.upayList = new List<cve__UnallocatedPayment__c>();
      this.adjList = new List<cve__Adjustment__c>();
      this.eventList = new List<RecalculatePayments__e>();
    }
  }
}