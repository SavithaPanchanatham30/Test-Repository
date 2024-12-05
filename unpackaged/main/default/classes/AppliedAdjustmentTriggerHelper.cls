public with sharing class AppliedAdjustmentTriggerHelper {
  private AppliedAdjustmentTriggerHandler.ContextVariables contxtVars;
  private List<Id> paymentSpecificationIds = new List<Id>();
  private Map<Id, Id> payIdAdjId = new Map<Id, Id>();
  private Map<Id, cve__Adjustment__c> adjustments = new Map<Id, cve__Adjustment__c>();
  private List<String> weeklyScheduleKey = new List<String>();
  private Set<Id> absenceClaimIds = new Set<Id>();
  private Boolean isAbsenceClaim = false;
  private Decimal averageWeeklyWageFromCert;
  private Map<Id, cve__Claim__c> claims = new Map<Id, cve__Claim__c>();
  private Set<Id> allPaymentSpecIds = new Set<Id>();
  private Set<Id> adjustmentIds = new Set<Id>();
  private Set<Id> unallocatedPaymentIds = new Set<Id>();
  private List<cve__ContactHistory__c> contactHistories = new List<cve__ContactHistory__c>();
  private Decimal prorationFactor;

  public static AppliedAdjustmentTriggerHelper getInstance() {
    return new AppliedAdjustmentTriggerHelper();
  }

  public AppliedAdjustmentTriggerHelper withContextVars(
    AppliedAdjustmentTriggerHandler.ContextVariables contxtVars
  ) {
    this.contxtVars = contxtVars;
    return this;
  }

  public List<cve__Adjustment__c> processAppliedAdjustments() {
    List<cve__AppliedAdjustment__c> adjustmentList = contxtVars.newList;
    Set<Id> appliedAdjIds = new Set<Id>();

    List<cve__AppliedAdjustment__c> appliedAdjRec = new List<cve__AppliedAdjustment__c>();
    List<cve__UnallocatedPayment__c> ups = new List<cve__UnallocatedPayment__c>();
    Map<Id, List<cve__AppliedAdjustment__c>> mapPaymentToAppliedAdj = new Map<Id, List<cve__AppliedAdjustment__c>>();
    Map<Id, List<cve__AppliedAdjustment__c>> mapPaymentSpecToAppliedAdj = new Map<Id, List<cve__AppliedAdjustment__c>>();

    for (cve__AppliedAdjustment__c adj : adjustmentList) {
      adjustmentIds.add(adj.cve__Adjustment__c);
      appliedAdjIds.add(adj.Id);
    }
    AppliedAdjustmentUtils helper = new AppliedAdjustmentUtils();
    adjustments = helper.getAdditionalIncomeAdjustments(adjustmentIds);

    List<cve__AppliedAdjustment__c> appAdjs = new List<cve__AppliedAdjustment__c>();
    appAdjs = [
      SELECT
        Id,
        cve__UnallocatedPayment__c,
        cve__UnallocatedPayment__r.cve__PaymentSpecification__c,
        cve__Adjustment__c,
        cve__Adjustment__r.cve__Amount__c,
        cve__Amount__c
      FROM cve__AppliedAdjustment__c
      WHERE Id IN :appliedAdjIds
      WITH SECURITY_ENFORCED
    ];

    for (cve__AppliedAdjustment__c adj : adjustmentList) {
      if (adjustments.keySet().contains(adj.cve__Adjustment__c)) {
        appliedAdjRec.add(adj);
      }
    }

    for (cve__AppliedAdjustment__c adj : appliedAdjRec) {
      if (mapPaymentToAppliedAdj.containsKey(adj.cve__UnallocatedPayment__c)) {
        List<cve__AppliedAdjustment__c> appliedAdj = mapPaymentToAppliedAdj.get(
          adj.cve__UnallocatedPayment__c
        );
        appliedAdj.add(adj);
        mapPaymentToAppliedAdj.put(adj.cve__UnallocatedPayment__c, appliedAdj);
      } else {
        mapPaymentToAppliedAdj.put(
          adj.cve__UnallocatedPayment__c,
          new List<cve__AppliedAdjustment__c>{ adj }
        );
      }
    }

    Map<Id, cve__UnallocatedPayment__c> paymentList = helper.getAllUnallocatedPayments(
      mapPaymentToAppliedAdj.keySet()
    );
    unallocatedPaymentIds = (paymentList.keySet());

    for (cve__UnallocatedPayment__c payment : paymentList.values()) {
      allPaymentSpecIds.add(payment.cve__PaymentSpecification__c);
      ups.add(payment);
      if (
        mapPaymentSpecToAppliedAdj.containsKey(
          payment.cve__PaymentSpecification__c
        )
      ) {
        List<cve__AppliedAdjustment__c> appliedAdjPay = mapPaymentSpecToAppliedAdj.get(
          payment.cve__PaymentSpecification__c
        );
        appliedAdjPay.addAll(mapPaymentToAppliedAdj.get(payment.id));
        mapPaymentSpecToAppliedAdj.put(
          payment.cve__PaymentSpecification__c,
          appliedAdjPay
        );
      } else {
        mapPaymentSpecToAppliedAdj.put(
          payment.cve__PaymentSpecification__c,
          mapPaymentToAppliedAdj.get(payment.id)
        );
      }
    }

    // Query payment specifications outside of the loop
    Map<Id, cve__PaymentSpecification__c> paymentSpecifications = new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT
          Id,
          cve__BenefitClaimed__c,
          cve__Amount__c,
          cve__Claim__c,
          cvint__AbsenceClaim__c,
          cve__AmountPeriod__c
        FROM cve__PaymentSpecification__c
        WHERE Id IN :allPaymentSpecIds
        WITH SECURITY_ENFORCED
      ]
    );
    getClaimsAndBenefits(paymentSpecifications);

    // Query claims
    claims.putAll(
      [
        SELECT Id, cve__DateOfDisability__c
        FROM cve__Claim__c
        WHERE Id IN :claims.keySet()
        WITH SECURITY_ENFORCED
      ]
    );

    List<cve__Adjustment__c> adjustmentToBeCreated = createAdjustments(
      mapPaymentSpecToAppliedAdj,
      ups,
      appAdjs
    );

    return adjustmentToBeCreated;
  }

  // Collect all Absence Claim Ids from paymentSpecifications
  private void getClaimsAndBenefits(
    Map<Id, cve__PaymentSpecification__c> paymentSpecifications
  ) {
    for (cve__PaymentSpecification__c ps : paymentSpecifications.values()) {
      if (ps.cvint__AbsenceClaim__c != null) {
        absenceClaimIds.add(ps.cvint__AbsenceClaim__c);
        isAbsenceClaim = true;
      } else if (ps.cve__Claim__c != null) {
        absenceClaimIds.add(ps.cve__Claim__c);
        claims.put(ps.cve__Claim__c, null);
      }
    }
  }

  private List<cve__Adjustment__c> createAdjustments(
    Map<Id, List<cve__AppliedAdjustment__c>> mapPaymentSpecToAppliedAdj,
    List<cve__UnallocatedPayment__c> ups,
    List<cve__AppliedAdjustment__c> appAdjs
  ) {
    Id contactId = getContactFromclaim();
    List<cve__Adjustment__c> adjustmentToBeCreated = new List<cve__Adjustment__c>();
    Map<Id, cve__PaymentSpecification__c> paymentSpecifications = new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT
          Id,
          cve__BenefitClaimed__c,
          cve__Amount__c,
          cve__Claim__c,
          cvint__AbsenceClaim__c,
          cve__AmountPeriod__c
        FROM cve__PaymentSpecification__c
        WHERE Id IN :allPaymentSpecIds
        WITH SECURITY_ENFORCED
      ]
    );
    List<cvab__DateRange__c> drs = [
      SELECT
        Id,
        cvint__PaymentSpecification__c,
        cvab__PaymentAmount__c,
        cvab__ExplainationOfBenefitAmount__c
      FROM cvab__DateRange__c
      WHERE cvint__PaymentSpecification__c IN :allPaymentSpecIds
      WITH SECURITY_ENFORCED
    ];
    contactHistories = [
      SELECT
        Id,
        cve__Contact__c,
        cve__EarningsPeriod__c,
        cve__Earnings__c,
        cve__Effective__c
      FROM cve__ContactHistory__c
      WHERE cve__Contact__c = :contactId
      WITH SECURITY_ENFORCED
      ORDER BY cve__Effective__c DESC
    ];
    for (cve__UnallocatedPayment__c up : ups) {
      List<cve__AppliedAdjustment__c> currentAdjs = new List<cve__AppliedAdjustment__c>();
      for (cve__AppliedAdjustment__c appAdj : appAdjs) {
        if (appAdj.cve__UnallocatedPayment__c == up.Id) {
          currentAdjs.add(appAdj);
        }
      }
      cve__PaymentSpecification__c ps = paymentSpecifications.get(
        up.cve__PaymentSpecification__c
      );
      cvab__DateRange__c currentDr = new cvab__DateRange__c();
      for (cvab__DateRange__c dr : drs) {
        if (dr.cvint__PaymentSpecification__c == ps.Id) {
          currentDr = dr;
        }
      }
      if (up.cve__PaymentSpecification__r.cve__Claim__c != null) {
        cve__Claim__c claim = claims.get(
          up.cve__PaymentSpecification__r.cve__Claim__c
        );
        adjustmentToBeCreated.addAll(
          createAdjustmentForDisabilityClaim(up, currentAdjs, claim, ps)
        );
      } else if (
        up.cve__PaymentSpecification__r.cvint__AbsenceClaim__c != null
      ) {
        adjustmentToBeCreated.addAll(
          createAdjustmentForAbsenceCliam(up, currentAdjs, ps, currentDr)
        );
      }
    }

    return adjustmentToBeCreated;
  }

  private Decimal calculateAww(
    cve__UnallocatedPayment__c up,
    cvab__DateRange__c dr
  ) {
    Decimal awwFromDR = Decimal.valueOf(
        dr.cvab__ExplainationOfBenefitAmount__c.substringAfter(
            'Average Weekly Earnings</strong> is $'
          )
          .substringBefore('.</li><li><strong>Benefit Rate</strong>')
      )
      .setScale(2);
    awwFromDR = awwFromDR * prorationFactor;
    return awwFromDR;
  }

  private Decimal getAdjustedPredisabilityAmount(
    cve__Claim__c claim,
    cve__UnallocatedPayment__c up
  ) {
    List<cve__ContactHistory__c> preChs = new List<cve__ContactHistory__c>();
    for (cve__ContactHistory__c ch : contactHistories) {
      if (ch.cve__Effective__c < claim.cve__DateOfDisability__c) {
        preChs.add(ch);
      }
    }
    cve__ContactHistory__c latestCh = preChs[0];
    Decimal adjustedAmount = 0;
    Decimal chEarnings = latestCh.cve__Earnings__c;
    adjustedAmount = ((chEarnings / 52) * prorationFactor).setScale(2);
    return adjustedAmount;
  }

  //TODO: refactor to bulkify
  private Id getContactFromclaim() {
    Id absenceClaimToContact;
    if (isAbsenceClaim) {
      for (cvab__Claim__c absenceClaim : [
        SELECT Id, cvab__Employee__c, cvab__StartDate__c, cvab__EndDate__c
        FROM cvab__Claim__c
        WHERE Id IN :absenceClaimIds
        WITH SECURITY_ENFORCED
      ]) {
        absenceClaimToContact = absenceClaim.cvab__Employee__c;
      }
    } else {
      // Query contacts associated with Absence Claims
      for (cve__Claim__c absenceClaim : [
        SELECT Id, cve__ClaimantInsured__c
        FROM cve__Claim__c
        WHERE Id IN :absenceClaimIds
        WITH SECURITY_ENFORCED
      ]) {
        absenceClaimToContact = absenceClaim.cve__ClaimantInsured__c;
      }
    }
    return absenceClaimToContact;
  }

  private List<cve__Adjustment__c> createAdjustmentForDisabilityClaim(
    cve__UnallocatedPayment__c up,
    List<cve__AppliedAdjustment__c> adjList,
    cve__Claim__c claim,
    cve__PaymentSpecification__c ps
  ) {
    AppliedAdjustmentUtils helper = new AppliedAdjustmentUtils();
    Integer upDays = up.cve__Start__c.daysBetween(up.cve__Through__c) + 1;
    List<cve__AppliedAdjustment__c> allAppliedAdjustments = helper.getAllAppliedAdjustments(
      up.Id
    );
    prorationFactor = up.cve__GrossBenefit__c / ps.cve__Amount__c;
    Decimal totalAmount = helper.getTotalAmountDisability(
      allAppliedAdjustments,
      adjustments,
      prorationFactor
    );
    Decimal benefitAmount = up.cve__GrossBenefit__c;

    List<cve__AppliedAdjustment__c> adjListOrderByStartDate = helper.getAllAppliedAdjustmentsOrderByDate(
      adjList
    );
    List<cve__Adjustment__c> adjustmentToBeCreated = helper.getDisabilityAdjustmentToBeCreated(
      adjListOrderByStartDate,
      up,
      ps
    );
    Decimal predisabilityEarnings = getAdjustedPredisabilityAmount(claim, up);
    List<cve__Adjustment__c> nonZeroAdjs = new List<cve__Adjustment__c>();
    for (cve__Adjustment__c adj : adjustmentToBeCreated) {
      adj.cve__Amount__c = Math.max(
          benefitAmount - totalAmount - predisabilityEarnings,
          0.00
        )
        .setScale(2);
      if (upDays != 7) {
        adj.cve__Amount__c = (adj.cve__Amount__c / upDays).setScale(2);
      }
      if (adj.cve__Amount__c != 0) {
        nonZeroAdjs.add(adj);
      }
      paymentSpecificationIds.add(adj.cve__PaymentSpecification__c);
    }
    return nonZeroAdjs;
  }

  private List<cve__Adjustment__c> createAdjustmentForAbsenceCliam(
    cve__UnallocatedPayment__c up,
    List<cve__AppliedAdjustment__c> adjList,
    cve__PaymentSpecification__c ps,
    cvab__DateRange__c dr
  ) {
    AppliedAdjustmentUtils helper = new AppliedAdjustmentUtils();
    Integer upDays = up.cve__Start__c.daysBetween(up.cve__Through__c) + 1;
    List<cve__AppliedAdjustment__c> allAppliedAdjustments = helper.getAllAppliedAdjustments(
      up.Id
    );
    prorationFactor = up.cve__GrossBenefit__c / ps.cve__Amount__c;
    Decimal totalAmount = helper.getTotalAmountAbsence(
      allAppliedAdjustments,
      adjustments,
      prorationFactor
    );

    Decimal benefitAmount = up.cve__GrossBenefit__c;
    List<cve__AppliedAdjustment__c> adjListOrderByStartDate = helper.getAllAppliedAdjustmentsOrderByDate(
      adjList
    );
    List<cve__Adjustment__c> adjustmentToBeCreated = helper.getAbsenceAdjustmentToBeCreated(
      adjListOrderByStartDate,
      up,
      ps
    );
    Decimal adjustedAww = calculateAww(up, dr);
    List<cve__Adjustment__c> nonZeroAdjs = new List<cve__Adjustment__c>();
    for (cve__Adjustment__c adj : adjustmentToBeCreated) {
      adj.cve__Amount__c = Math.max(
          benefitAmount - totalAmount - adjustedAww,
          0.00
        )
        .setScale(2);
      if (upDays != 7) {
        adj.cve__Amount__c = (adj.cve__Amount__c / upDays).setScale(2);
      }
      if (adj.cve__Amount__c != 0) {
        nonZeroAdjs.add(adj);
      }
      paymentSpecificationIds.add(adj.cve__PaymentSpecification__c);
    }
    return nonZeroAdjs;
  }

  public List<Id> getpaymentIds() {
    return paymentSpecificationIds;
  }

  public List<cve__Adjustment__c> deleteAdjustmentsOnPaymentSpec() {
    List<cve__Adjustment__c> adjustmentsToDelete = AppliedAdjustmentUtils.getAdjustmentToDelete(
      paymentSpecificationIds
    );

    return adjustmentsToDelete;
  }
}