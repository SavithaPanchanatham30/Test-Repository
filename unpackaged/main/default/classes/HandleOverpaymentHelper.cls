public with sharing class HandleOverpaymentHelper {
  private static final List<String> SUPPLEMENTALRECORDTYPES = new List<String>{
    'Accident',
    'Critical Illness',
    'Hospital Indemnity'
  };

  public Set<Id> filterPaymentSpec(
    List<cve__PaymentSpecification__c> newList,
    Map<Id, cve__PaymentSpecification__c> oldMap
  ) {
    List<String> statusList = new List<String>{ 'Denied', 'Cancelled' };
    Set<Id> result = new Set<Id>();
    Map<Id, Boolean> hasRecoupAdj = checkRecoupAdjustments(oldMap.keySet());
    for (cve__PaymentSpecification__c ps : newList) {
      cve__PaymentSpecification__c oldPs = oldMap.get(ps.id);
      Boolean hasRecoup = hasRecoupAdj.containsKey(ps.id)
        ? hasRecoupAdj.get(ps.id)
        : false;
      if (
        ps.cve__Amount__c != oldPs.cve__Amount__c ||
        ps.cve__Start__c != oldPs.cve__Start__c ||
        ps.cve__Through__c != oldPs.cve__Through__c ||
        (ps.ClaimLeaveStatus__c != oldPs.ClaimLeaveStatus__c &&
        !statusList.contains(ps.ClaimLeaveStatus__c) &&
        statusList.contains(oldPs.ClaimLeaveStatus__c)) ||
        (ps.RecoupOverpayment__c != oldPs.RecoupOverpayment__c &&
        ps.RecoupOverpayment__c == true) ||
        (ps.cve__OverpaymentBeforeTax__c !=
        oldPs.cve__OverpaymentBeforeTax__c &&
        ps.cve__OverpaymentBeforeTax__c > 0 &&
        !hasRecoup)
      ) {
        result.add(ps.id);
      }
    }

    return result;
  }

  private Map<Id, Boolean> checkRecoupAdjustments(Set<Id> psIds) {
    Map<Id, Boolean> result = new Map<Id, Boolean>();

    for (Id psId : psIds) {
      result.put(psId, false);
    }

    List<cve__Adjustment__c> adjList = [
      SELECT id, cve__PaymentSpecification__c
      FROM cve__Adjustment__c
      WHERE
        cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
        AND cve__PaymentSpecification__c IN :psIds
        AND Recouped__c = FALSE
    ];

    for (cve__Adjustment__c adj : adjList) {
      result.put(adj.cve__PaymentSpecification__c, true);
    }

    return result;
  }

  public Set<Id> filterBenefitClaimed(
    List<cve__BenefitClaimed__c> newList,
    Map<Id, cve__BenefitClaimed__c> oldMap
  ) {
    List<String> statusList = new List<String>{ 'Denied', 'Cancelled' };
    Set<Id> bcIds = new Set<Id>();
    for (cve__BenefitClaimed__c bc : newList) {
      cve__BenefitClaimed__c oldBc = oldMap.get(bc.id);
      if (
        !SUPPLEMENTALRECORDTYPES.contains(bc.cve__RecordTypeName__c) &&
        ((bc.cve__BenefitStart__c != null &&
        bc.cve__BenefitStart__c != oldBc.cve__BenefitStart__c) ||
        (bc.cve__BenefitThrough__c != null &&
        bc.cve__BenefitThrough__c != oldBc.cve__BenefitThrough__c) ||
        (bc.cve__AdjustedBenefitStart__c != null &&
        bc.cve__AdjustedBenefitStart__c !=
        oldBc.cve__AdjustedBenefitStart__c) ||
        (bc.cve__AdjustedBenefitThrough__c != null &&
        bc.cve__AdjustedBenefitThrough__c !=
        oldBc.cve__AdjustedBenefitThrough__c) ||
        (!statusList.contains(bc.cve__Status__c) &&
        statusList.contains(oldBc.cve__Status__c)))
      ) {
        bcIds.add(bc.id);
      } else if (
        SUPPLEMENTALRECORDTYPES.contains(bc.cve__RecordTypeName__c) &&
        (!statusList.contains(bc.cve__Status__c) &&
        statusList.contains(oldBc.cve__Status__c))
      ) {
        bcIds.add(bc.id);
      }
    }

    return bcIds;
  }

  public Set<Id> filterAdjustments(List<cve__Adjustment__c> newList) {
    Set<Id> result = new Set<Id>();
    for (cve__Adjustment__c adj : newList) {
      if (
        adj.cve__Type__c != 'Recoup Overpayment (Pre-Tax)' &&
        !adj.cve__Type__c.contains('(Post-Tax)') &&
        !adj.cve__Automated__c &&
        adj.cve__Amount__c > 0
      ) {
        result.add(adj.cve__PaymentSpecification__c);
      }
    }

    return result;
  }

  public List<RecalculatePayments__e> generateEvents(
    Set<Id> psIds,
    Boolean passedBcIds
  ) {
    Set<Id> claimIds = new Set<Id>();
    Set<Id> specIds = new Set<Id>();
    List<RecalculatePayments__e> result = new List<RecalculatePayments__e>();
    List<cve__PaymentSpecification__c> psList = passedBcIds
      ? getPaymentSpecsFromBc(psIds)
      : getPaymentSpecs(psIds);
    for (cve__PaymentSpecification__c ps : psList) {
      if (ps.cve__Claim__c != null && ps.cve__BenefitClaimed__c != null) {
        claimIds.add(ps.cve__BenefitClaimed__c);
      } else if (ps.cvint__AbsenceClaim__c != null) {
        claimIds.add(ps.cvint__AbsenceClaim__c);
      }
      specIds.add(ps.id);
      result.add(
        new RecalculatePayments__e(
          PaymentSpecificationId__c = ps.id,
          RunOverpaymentCheck__c = true
        )
      );
    }

    List<cve__PaymentSpecification__c> relatedPs = getRelatedPs(
      claimIds,
      specIds
    );

    for (cve__PaymentSpecification__c ps : relatedPs) {
      result.add(new RecalculatePayments__e(PaymentSpecificationId__c = ps.id));
    }

    return result;
  }

  public List<cve__Adjustment__c> updateAdjustments(
    List<RecalculatePayments__e> eventList
  ) {
    Set<Id> psIds = new Set<Id>();
    for (RecalculatePayments__e event : eventList) {
      psIds.add(event.PaymentSpecificationId__c);
    }

    List<cve__Adjustment__c> adjList = [
      SELECT id, cve__Amount__c
      FROM cve__Adjustment__c
      WHERE
        cve__PaymentSpecification__c IN :psIds
        AND (cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
        OR cve__Type__c = 'Minimum Benefit Adjustment (Pre-Tax)')
        AND Recouped__c = FALSE
    ];
    for (cve__Adjustment__c adj : adjList) {
      adj.cve__Amount__c = 0;
    }
    return adjList;
  }

  private List<cve__PaymentSpecification__c> getPaymentSpecs(Set<Id> psIds) {
    List<cve__PaymentSpecification__c> result = new List<cve__PaymentSpecification__c>();
    List<cve__PaymentSpecification__c> psList = [
      SELECT
        id,
        cve__PaymentCalculationDate__c,
        cve__OverpaymentBeforeTax__c,
        cve__Claim__c,
        cve__BenefitClaimed__c,
        cve__Claim__r.cve__ClaimantInsured__r.HasCveOverpayment__c,
        cvint__AbsenceClaim__c,
        cvint__AbsenceClaim__r.cvab__Employee__r.HasCvabOverpayment__c,
        (
          SELECT id, cve__Status__c
          FROM cve__Payments__r
          WHERE cve__Status__c = 'Pending' OR cve__Status__c = 'Approved'
        ),
        (
          SELECT id
          FROM cve__Adjustments__r
          WHERE
            cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
            AND Recouped__c = FALSE
        )
      FROM cve__PaymentSpecification__c
      WHERE id IN :psIds
    ];
    for (cve__PaymentSpecification__c ps : psList) {
      if (
        ps.cve__Claim__c != null &&
        (ps.cve__Claim__r.cve__ClaimantInsured__r.HasCveOverpayment__c ||
        (ps.cve__Adjustments__r != null &&
        ps.cve__Adjustments__r.size() > 0) ||
        (ps.cve__OverpaymentBeforeTax__c > 0 &&
        ps.cve__Adjustments__r.size() == 0 &&
        !ps.cve__Claim__r.cve__ClaimantInsured__r.HasCveOverpayment__c)) &&
        (ps.cve__Payments__r.size() > 0 ||
        (ps.cve__Payments__r.size() == 0 &&
        ps.cve__PaymentCalculationDate__c == null))
      ) {
        result.add(ps);
      } else if (
        ps.cvint__AbsenceClaim__c != null &&
        (ps.cvint__AbsenceClaim__r.cvab__Employee__r.HasCvabOverpayment__c ||
        (ps.cve__Adjustments__r != null &&
        ps.cve__Adjustments__r.size() > 0)) &&
        (ps.cve__Payments__r.size() > 0 ||
        (ps.cve__Payments__r.size() == 0 &&
        ps.cve__PaymentCalculationDate__c == null))
      ) {
        result.add(ps);
      }
    }
    return result;
  }

  private List<cve__PaymentSpecification__c> getPaymentSpecsFromBc(
    Set<Id> bcIds
  ) {
    List<cve__PaymentSpecification__c> result = new List<cve__PaymentSpecification__c>();
    List<cve__PaymentSpecification__c> psList = [
      SELECT
        id,
        cve__Through__c,
        cve__PaymentCalculationDate__c,
        cve__OverpaymentBeforeTax__c,
        cve__Claim__c,
        cve__BenefitClaimed__c,
        cve__BenefitClaimed__r.cve__AdjustedBenefitThrough__c,
        cve__Claim__r.cve__ClaimantInsured__r.HasCveOverpayment__c,
        cvint__AbsenceClaim__c,
        cvint__AbsenceClaim__r.cvab__Employee__r.HasCvabOverpayment__c,
        (
          SELECT id, cve__Status__c
          FROM cve__Payments__r
          WHERE cve__Status__c = 'Pending' OR cve__Status__c = 'Approved'
        ),
        (
          SELECT id
          FROM cve__Adjustments__r
          WHERE
            cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
            AND Recouped__c = FALSE
        )
      FROM cve__PaymentSpecification__c
      WHERE cve__BenefitClaimed__c IN :bcIds
    ];
    for (cve__PaymentSpecification__c ps : psList) {
      if (
        ps.cve__Claim__c != null &&
        ((ps.cve__Adjustments__r != null &&
        ps.cve__Adjustments__r.size() > 0) ||
        (ps.cve__Adjustments__r.size() == 0 &&
        ps.cve__OverpaymentBeforeTax__c > 0)) &&
        (ps.cve__Payments__r.size() > 0 ||
        (ps.cve__Payments__r.size() == 0 &&
        ps.cve__PaymentCalculationDate__c == null) ||
        (ps.cve__BenefitClaimed__r.cve__AdjustedBenefitThrough__c != null &&
        ps.cve__Through__c <
        ps.cve__BenefitClaimed__r.cve__AdjustedBenefitThrough__c &&
        ps.cve__OverpaymentBeforeTax__c > 0))
      ) {
        result.add(ps);
      }
    }
    return result;
  }

  private List<cve__PaymentSpecification__c> getRelatedPs(
    Set<Id> claimIds,
    Set<Id> psIds
  ) {
    List<cve__PaymentSpecification__c> result = new List<cve__PaymentSpecification__c>();
    if (claimIds == null || (claimIds != null && claimIds.size() == 0)) {
      return result;
    }
    List<cve__PaymentSpecification__c> psList = [
      SELECT
        id,
        cve__PaymentCalculationDate__c,
        (
          SELECT id, cve__Status__c
          FROM cve__Payments__r
          WHERE cve__Status__c = 'Pending' OR cve__Status__c = 'Approved'
        )
      FROM cve__PaymentSpecification__c
      WHERE
        (cvint__AbsenceClaim__c IN :claimIds
        OR cve__BenefitClaimed__c IN :claimIds)
        AND id NOT IN :psIds
    ];
    for (cve__PaymentSpecification__c ps : psList) {
      if (
        ps.cve__Payments__r.size() > 0 ||
        (ps.cve__Payments__r.size() == 0 &&
        ps.cve__PaymentCalculationDate__c == null)
      ) {
        result.add(ps);
      } else if (
        ps.cve__Payments__r.size() > 0 ||
        (ps.cve__Payments__r.size() == 0 &&
        ps.cve__PaymentCalculationDate__c == null)
      ) {
        result.add(ps);
      }
    }
    return result;
  }
}