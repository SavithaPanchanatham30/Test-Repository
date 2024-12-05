public with sharing class AppliedAdjustmentUtils {
  public static final cve__DateConversionFactors__c DATE_CONVERSION_FACTORS = cve__DateConversionFactors__c.getOrgDefaults();
  public static final Integer MONTHS_PER_QUARTER = 3;
  public static final Integer MONTHS_PER_YEAR = (Integer) DATE_CONVERSION_FACTORS.cve__MonthsPerYear__c;
  public static final Decimal WEEKS_PER_MONTH = DATE_CONVERSION_FACTORS.cve__WeeksPerMonth__c;
  public static final Integer DAYS_PER_WEEK = (Integer) DATE_CONVERSION_FACTORS.cve__DaysPerWeek__c;
  public static final Decimal DAYS_PER_MONTH = DATE_CONVERSION_FACTORS.cve__DaysPerMonth__c;
  public static final Decimal DAYS_PER_YEAR = DATE_CONVERSION_FACTORS.cve__InterestDaysPerYear__c;
  public static final Integer BUSINESS_DAYS_PER_WEEK = (Integer) DATE_CONVERSION_FACTORS.cve__BusinessDaysPerWeek__c;
  public static final Integer QUARTERS_PER_YEAR = 4;
  private Decimal totalAmounts;
  Map<Id, cve__Adjustment__c> adjustmentsMap = new Map<Id, cve__Adjustment__c>();

  public Map<Id, cve__Adjustment__c> getAdditionalIncomeAdjustments(
    Set<Id> adjustmentIds
  ) {
    return new Map<Id, cve__Adjustment__c>(
      [
        SELECT id, cve__Period__c, cve__Type__c
        FROM cve__Adjustment__c
        WHERE
          id IN :adjustmentIds
          AND cve__Type__c = 'Additional Income (Pre-Tax)'
        WITH SECURITY_ENFORCED
      ]
    );
  }

  public Map<Id, cve__UnallocatedPayment__c> getAllUnallocatedPayments(
    Set<Id> paymentIds
  ) {
    return new Map<Id, cve__UnallocatedPayment__c>(
      [
        SELECT
          id,
          cve__PaymentSpecification__c,
          cve__Start__c,
          cve__Through__c,
          cve__GrossBenefit__c,
          cve__PaymentSpecification__r.cve__Claim__c,
          cve__PaymentSpecification__r.cve__BenefitClaimed__c,
          cve__PaymentSpecification__r.cvint__AbsenceClaim__c,
          cve__PaymentSpecification__r.cve__AmountPeriod__c
        FROM cve__UnallocatedPayment__c
        WHERE id IN :paymentIds
        WITH SECURITY_ENFORCED
      ]
    );
  }

  public List<cve__AppliedAdjustment__c> getAllAppliedAdjustments(
    Id unallocatedPaymentId
  ) {
    return [
      SELECT
        Id,
        Name,
        cve__Amount__c,
        cve__Adjustment__c,
        cve__Adjustment__r.cve__Amount__c,
        cve__Start__c,
        cve__Through__c
      FROM cve__AppliedAdjustment__c
      WHERE cve__UnallocatedPayment__c = :unallocatedPaymentId
      WITH SECURITY_ENFORCED
      ORDER BY cve__Start__c
    ];
  }
  public List<cve__AppliedAdjustment__c> getAllAppliedAdjustmentsOrderByDate(
    List<cve__AppliedAdjustment__c> adjRecs
  ) {
    return [
      SELECT
        Id,
        Name,
        cve__Amount__c,
        cve__Adjustment__c,
        cve__Start__c,
        cve__Through__c,
        cve__Adjustment__r.cve__Type__c
      FROM cve__AppliedAdjustment__c
      WHERE
        Id IN :adjRecs
        AND cve__Amount__c != 0
        AND cve__Adjustment__r.cve__Type__c = 'Additional Income (Pre-Tax)'
      WITH SECURITY_ENFORCED
      ORDER BY cve__Start__c
    ];
  }

  public Decimal getTotalAmountDisability(
    List<cve__AppliedAdjustment__c> allAppliedAdjustments,
    Map<Id, cve__Adjustment__c> adjustments,
    Decimal prorationFactor
  ) {
    Decimal totalAmount = 0;
    for (cve__AppliedAdjustment__c adj : allAppliedAdjustments) {
      if (
        adjustments.containsKey(adj.cve__Adjustment__c) &&
        adjustments.get(adj.cve__Adjustment__c).cve__Type__c ==
        'Additional Income (Pre-Tax)'
      ) {
        if (prorationFactor.setScale(0) != 1) {
          totalAmount +=
            adj.cve__Adjustment__r.cve__Amount__c * prorationFactor;
        } else {
          totalAmount += adj.cve__Amount__c;
        }
      }
    }
    totalAmounts = totalAmount;
    adjustmentsMap = adjustments;
    return totalAmount;
  }

  public Decimal getTotalAmountAbsence(
    List<cve__AppliedAdjustment__c> allAppliedAdjustments,
    Map<Id, cve__Adjustment__c> adjustments,
    Decimal prorationFactor
  ) {
    Decimal totalAmount = 0;
    for (cve__AppliedAdjustment__c adj : allAppliedAdjustments) {
      if (
        adjustments.containsKey(adj.cve__Adjustment__c) &&
        adjustments.get(adj.cve__Adjustment__c).cve__Type__c ==
        'Additional Income (Pre-Tax)'
      ) {
        if (prorationFactor.setScale(0) != 1) {
          totalAmount +=
            adj.cve__Adjustment__r.cve__Amount__c * prorationFactor;
        } else {
          totalAmount += adj.cve__Amount__c;
        }
      }
    }
    totalAmounts = totalAmount;
    adjustmentsMap = adjustments;
    return totalAmount;
  }

  public List<cve__Adjustment__c> getDisabilityAdjustmentToBeCreated(
    List<cve__AppliedAdjustment__c> adjListOrderByStartDate,
    cve__UnallocatedPayment__c up,
    cve__PaymentSpecification__c ps
  ) {
    List<cve__Adjustment__c> result = new List<cve__Adjustment__c>();
    for (integer i = 0; i < adjListOrderByStartDate.size(); i++) {
      // Create the adjustment record
      cve__Adjustment__c adjustment = new cve__Adjustment__c();
      adjustment.cve__Type__c = 'Additional Income Offset (Pre-Tax)';
      adjustment.cve__Status__c = 'Actual';
      adjustment.cve__Start__c = up.cve__Start__c;
      adjustment.cve__Through__c = up.cve__Through__c;
      if (up.cve__Start__c.daysBetween(up.cve__Through__c) + 1 == 7) {
        adjustment.cve__Period__c = ps.cve__AmountPeriod__c;
      } else {
        adjustment.cve__Period__c = 'Daily';
      }
      adjustment.cve__PaymentSpecification__c = ps.Id;

      result.add(adjustment);
    }
    return result;
  }

  public List<cve__Adjustment__c> getAbsenceAdjustmentToBeCreated(
    List<cve__AppliedAdjustment__c> adjListOrderByStartDate,
    cve__UnallocatedPayment__c up,
    cve__PaymentSpecification__c ps
  ) {
    List<cve__Adjustment__c> result = new List<cve__Adjustment__c>();
    for (integer i = 0; i < adjListOrderByStartDate.size(); i++) {
      // Create the adjustment record
      cve__Adjustment__c adjustment = new cve__Adjustment__c();
      adjustment.cve__Type__c = 'Additional Income Offset (Pre-Tax)';
      adjustment.cve__Status__c = 'Actual';
      adjustment.cve__Start__c = up.cve__Start__c;
      adjustment.cve__Through__c = up.cve__Through__c;
      if (up.cve__Start__c.daysBetween(up.cve__Through__c) + 1 == 7) {
        adjustment.cve__Period__c = ps.cve__AmountPeriod__c;
      } else {
        adjustment.cve__Period__c = 'Daily';
      }
      adjustment.cve__PaymentSpecification__c = ps.Id;

      result.add(adjustment);
    }
    return result;
  }
  public static List<cve__Adjustment__c> getAdjustmentToDelete(
    List<Id> paymentSpecificationIds
  ) {
    List<cve__Adjustment__c> adjustmentsToDelete = new List<cve__Adjustment__c>();
    if (paymentSpecificationIds.size() > 0) {
      adjustmentsToDelete = [
        SELECT Id, cve__PaymentSpecification__c
        FROM cve__Adjustment__c
        WHERE
          cve__PaymentSpecification__c IN :paymentSpecificationIds
          AND cve__Type__c = 'Additional Income (Pre-Tax)'
        WITH SECURITY_ENFORCED
      ];
    }

    return adjustmentsToDelete;
  }

  /*public List<cve__Adjustment__c> mergeAllAdjustments(
    List<cve__Adjustment__c> adjustmentToBeCreated
  ) {
    List<cve__Adjustment__c> mergedAdjustments = new List<cve__Adjustment__c>();
    adjustmentToBeCreated.sort();
    cve__Adjustment__c current = null;
    for (cve__Adjustment__c adj : adjustmentToBeCreated) {
      if (
        current == null ||
        current.cve__Through__c.addDays(1) < adj.cve__Start__c
      ) {
        current = adj.clone();
        mergedAdjustments.add(current);
      } else {
        // Extend the current merged adjustment
        current.cve__Through__c = adj.cve__Through__c;
      }
    }

    return mergedAdjustments;
  }*/
}