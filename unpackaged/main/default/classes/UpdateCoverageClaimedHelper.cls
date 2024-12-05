public class UpdateCoverageClaimedHelper {
  BenefitCoverageClaimedSelector selector;
  Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>> coverageLimitations;
  Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filterMap;
  List<cve__BenefitClaimed__c> benefitClaimedList = new List<cve__BenefitClaimed__c>();
  Map<String, Schema.SObjectType> schemaSobjects;
  Map<Id, Schema.RecordTypeInfo> coverageRecordTypes;
  Id criticalIllnessId;

  public UpdateCoverageClaimedHelper() {
    if (this.schemaSobjects == null) {
      this.schemaSobjects = Schema.getGlobalDescribe();
    }

    if (this.coverageRecordTypes == null) {
      this.coverageRecordTypes = schemaSobjects.get('cve__Coverage__c')
        .getDescribe()
        .getRecordTypeInfosById();
    }

    if (this.criticalIllnessId == null) {
      this.criticalIllnessId = schemaSobjects.get('cve__BenefitClaimed__c')
        .getDescribe()
        .getRecordTypeInfosByName()
        .get('Critical Illness')
        .getRecordTypeId();
    }
  }

  public static UpdateCoverageClaimedHelper getInstance() {
    return new UpdateCoverageClaimedHelper()
      .setSelector(BenefitCoverageClaimedSelector.getInstance());
  }

  @TestVisible
  private static UpdateCoverageClaimedHelper getInstance(
    BenefitCoverageClaimedSelector selector
  ) {
    return new UpdateCoverageClaimedHelper().setSelector(selector);
  }

  private UpdateCoverageClaimedHelper setSelector(
    BenefitCoverageClaimedSelector selector
  ) {
    this.selector = selector;
    return this;
  }

  public List<cve__CoverageClaimed__c> processEvents(
    List<UpdateCoverageClaimed__e> newList
  ) {
    Set<Id> ccIds = new Set<Id>();
    Set<Id> bcIds = new Set<Id>();
    for (UpdateCoverageClaimed__e event : newList) {
      ccIds.add(event.CoverageClaimedId__c);
    }

    List<cve__CoverageClaimed__c> coverageClaimed = getCoverageClaimed(ccIds);
    for (cve__CoverageClaimed__c cc : coverageClaimed) {
      bcIds.add(cc.cve__BenefitClaimed__c);
    }
    return processCoverageClaimed(coverageClaimed);
  }

  public List<cve__BenefitClaimed__c> getBenefitClaimed(
    List<cve__CoverageClaimed__c> ccList
  ) {
    List<cve__BenefitClaimed__c> result = new List<cve__BenefitClaimed__c>();
    Map<Id, List<cve__CoverageClaimed__c>> bcMap = new Map<Id, List<cve__CoverageClaimed__c>>();
    for (cve__CoverageClaimed__c cc : ccList) {
      result.add(new cve__BenefitClaimed__c(Id = cc.cve__BenefitClaimed__c));
    }
    return selector.getBenefitsCoveragesClaimed(result).values();
  }

  private List<cve__CoverageClaimed__c> getCoverageClaimed(Set<Id> ccIds) {
    return [
      SELECT
        Id,
        Name,
        cve__BenefitClaimed__c,
        cve__BenefitName__c,
        cve__ClaimId__c,
        cve__Amount__c,
        cve__Units__c,
        cve__BenefitClaimed__r.RecordTypeId,
        cve__BenefitClaimed__r.IncurredDate__c,
        cve__BenefitClaimed__r.ClaimBrainIntegrationStatus__c,
        cve__BenefitClaimed__r.cve__DateOfDisability__c,
        cve__BenefitClaimed__r.cve__Benefit__r.cve__CoverageAmount__c,
        cve__BenefitClaimed__r.cve__Benefit__c,
        cve__BenefitClaimed__r.cve__LatestPaymentSpecification__c,
        cve__BenefitClaimed__r.cve__Claim__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__Policy__r.cve__Effective__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__c,
        cve__BenefitClaimed__r.cve__Claim__r.IncurredDate__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__ClaimantInsured__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Policy__c,
        cve__BenefitClaimed__r.cve__ClaimantInsured__c,
        cve__Coverage__r.cve__Category__c,
        cve__Coverage__c,
        cve__Coverage__r.RecordTypeId,
        cve__Coverage__r.cve__Amount__c,
        cve__Coverage__r.cve__AmountPerUnit__c,
        cve__Coverage__r.cve__Percentage__c,
        cve__Coverage__r.cve__PercentageOf__c,
        cve__Coverage__r.cve__PercentageOf__r.cve__Amount__c,
        cve__CoverageAmount__c,
        cve__CoverageRelationshipToPolicyholder__c,
        cve__EffectiveDateOfCoverage__c,
        cve__InvoiceLineItem__c,
        cve__PayableAmount__c,
        cve__PayableUnits__c,
        cve__Start__c
      FROM cve__CoverageClaimed__c
      WHERE id IN :ccIds
    ];
  }

  public List<cve__CoverageClaimed__c> processCoverageClaimed(
    List<cve__CoverageClaimed__c> coveragesToBeUpdated
  ) {
    List<cve__BenefitClaimed__c> benefitClaimedList = new List<cve__BenefitClaimed__c>();
    for (cve__CoverageClaimed__c cc : coveragesToBeUpdated) {
      benefitClaimedList.add(
        new cve__BenefitClaimed__c(Id = cc.cve__BenefitClaimed__c)
      );
    }

    benefitClaimedList = selector.getBenefitsCoveragesClaimed(
        benefitClaimedList
      )
      .values();
    Map<id, usal__MemberBenefit__c> memberBenefits = selector.getMemberBenefits(
      benefitClaimedList
    );
    List<cve__CoverageClaimed__c> coveragesToUpdate = new List<cve__CoverageClaimed__c>();
    selector.getPreexistingCoveragesClaimed(coveragesToBeUpdated);
    this.coverageLimitations = selector.getCoverageLimitations(
      coveragesToBeUpdated
    );
    this.filterMap = selector.filterCoveragesClaimedByCoverageLimitations(
      coveragesToBeUpdated
    );

    for (cve__CoverageClaimed__c cc : coveragesToBeUpdated) {
      Decimal tempAmount = calculateAvailableAmount(
        coverageLimitations.get(cc),
        filterMap.get(cc)
      );
      Decimal amount = tempAmount != null ? Math.Max(tempAmount, 0) : null;

      Decimal tempUnit = calculateAvailableUnits(
        coverageLimitations.get(cc),
        filterMap.get(cc)
      );
      Decimal unit = tempUnit != null ? Math.Max(tempUnit, 0) : null;

      Decimal tempCount = calculateAvailableCount(
        coverageLimitations.get(cc),
        filterMap.get(cc)
      );
      Decimal availableCount = tempCount != null
        ? Math.max(tempCount, 0)
        : null;

      if (availableCount == 0) {
        cc.cve__PayableAmount__c = 0;
      } else {
        AggregateValues ag = new AggregateValues(amount, unit, availableCount);
        cc = updateCoverageClaimed(
          cc,
          ag,
          memberBenefits.get(cc.cve__BenefitClaimed__c)
        );
      }
      coveragesToUpdate.add(cc);
    }
    return coveragesToUpdate;
  }

  public cve__CoverageClaimed__c updateCoverageClaimed(
    cve__CoverageClaimed__c cc,
    AggregateValues ag,
    usal__MemberBenefit__c mb
  ) {
    String recordTypeName = coverageRecordTypes.get(
        cc.cve__Coverage__r.RecordTypeId
      )
      .getName();

    if (
      (recordTypeName == 'Amount' || recordTypeName == 'Amount Auto Named') &&
      ag.amount != null
    ) {
      cc.cve__Amount__c = cc.cve__Coverage__r.cve__Amount__c;
      cc.cve__PayableAmount__c = ag.amount <= cc.cve__Amount__c
        ? ag.amount
        : cc.cve__Amount__c;
    } else if (
      (recordTypeName == 'Percentage of Base Coverage' ||
      recordTypeName == 'Percentage of Other Coverage')
    ) {
      if (ag.amount != null) {
        cc = handlePercentageCoverage(cc, ag, mb, recordTypeName);
      } else if (
        mb != null &&
        mb.usal__Amount__c != null &&
        cc.cve__BenefitClaimed__r.RecordTypeId == CriticalIllnessId &&
        recordTypeName == 'Percentage of Base Coverage'
      ) {
        cc.cve__Amount__c =
          (cc.cve__Coverage__r.cve__Percentage__c * 0.01) * mb.usal__Amount__c;
        cc.cve__PayableAmount__c = cc.cve__Amount__c;
      }
    } else if (
      recordTypeName == 'Variable Amount' ||
      recordTypeName == 'Variable Units'
    ) {
      cc = handleVariableCoverage(cc, ag, mb, recordTypeName);
    }
    return cc;
  }

  public cve__CoverageClaimed__c handleVariableCoverage(
    cve__CoverageClaimed__c cc,
    AggregateValues ag,
    usal__MemberBenefit__c mb,
    String recordTypeName
  ) {
    switch on recordTypeName {
      when ('Variable Amount') {
        if (ag.amount != null) {
          cc.cve__PayableAmount__c = ag.amount <= cc.cve__Amount__c
            ? ag.amount
            : cc.cve__Amount__c;
        }
      }
      when ('Variable Units') {
        cc.cve__PayableUnits__c = ag.units != null &&
          ag.units <= cc.cve__Units__c
          ? ag.units
          : cc.cve__Units__c;
        cc.cve__Amount__c =
          cc.cve__Units__c * cc.cve__Coverage__r.cve__AmountPerUnit__c;
        Decimal tempAmount =
          cc.cve__PayableUnits__c * cc.cve__Coverage__r.cve__AmountPerUnit__c;
        cc.cve__PayableAmount__c = ag.amount != null &&
          ag.amount <= tempAmount
          ? ag.amount
          : tempAmount;
        cc.cve__PayableUnits__c = cc.cve__PayableAmount__c == ag.amount
          ? (cc.cve__PayableAmount__c /
              cc.cve__Coverage__r.cve__AmountPerUnit__c)
              .round(System.RoundingMode.UP)
          : cc.cve__PayableUnits__c;
      }
    }
    return cc;
  }

  public cve__CoverageClaimed__c handlePercentageCoverage(
    cve__CoverageClaimed__c cc,
    AggregateValues ag,
    usal__MemberBenefit__c mb,
    String recordTypeName
  ) {
    switch on recordTypeName {
      when ('Percentage of Base Coverage') {
        cc.cve__Amount__c = cc.cve__BenefitClaimed__r.RecordTypeId ==
          CriticalIllnessId &&
          mb != null &&
          mb.usal__Amount__c != null
          ? (cc.cve__Coverage__r.cve__Percentage__c * 0.01) * mb.usal__Amount__c
          : (cc.cve__Coverage__r.cve__Percentage__c * 0.01) *
            cc.cve__BenefitClaimed__r.cve__Benefit__r.cve__CoverageAmount__c;
        cc.cve__PayableAmount__c = ag.amount <= cc.cve__Amount__c
          ? ag.amount
          : cc.cve__Amount__c;
      }
      when ('Percentage of Other Coverage') {
        cc.cve__Amount__c =
          cc.cve__Coverage__r.cve__PercentageOf__r.cve__Amount__c *
          (cc.cve__Coverage__r.cve__Percentage__c * 0.01);
        cc.cve__PayableAmount__c = ag.amount <= cc.cve__Amount__c
          ? ag.amount
          : cc.cve__Amount__c;
      }
    }
    return cc;
  }

  public Decimal calculateAvailableCount(
    List<usal__CoverageLimitation__c> limitList,
    Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>> filterMap
  ) {
    Decimal availableCount;
    if (limitList == null || filterMap == null) {
      return availableCount;
    }
    for (usal__CoverageLimitation__c climit : limitList) {
      if (climit.usal__MaximumTimesClaimed__c != null) {
        Decimal count = filterMap.get(climit).size();
        Decimal tempResult = climit.usal__MaximumTimesClaimed__c - count;
        if (
          availableCount == null ||
          (availableCount != null &&
          availableCount > tempResult)
        ) {
          availableCount = tempResult;
        }
      }
    }
    return availableCount;
  }

  public Decimal calculateAvailableUnits(
    List<usal__CoverageLimitation__c> limitList,
    Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>> filterMap
  ) {
    Decimal unit;
    if (limitList == null || filterMap == null) {
      return unit;
    }
    for (usal__CoverageLimitation__c climit : limitList) {
      if (climit.usal__MaximumUnits__c != null) {
        Decimal totalPayableUnit = getTotalPayableUnit(filterMap.get(climit));
        Decimal tempResult = climit.usal__MaximumUnits__c - totalPayableUnit;

        if (unit == null || (unit != null && unit > tempResult)) {
          unit = tempResult;
        }
      }
    }
    return unit;
  }

  public Decimal getTotalPayableUnit(List<cve__CoverageClaimed__c> previousCC) {
    Decimal total = 0;
    for (cve__CoverageClaimed__c cc : previousCC) {
      Decimal payableUnits = cc.cve__PayableUnits__c == null
        ? 0
        : cc.cve__PayableUnits__c;
      total += payableUnits;
    }
    return total;
  }

  public Decimal calculateAvailableAmount(
    List<usal__CoverageLimitation__c> limitList,
    Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>> filterMap
  ) {
    Decimal amount;
    if (limitList == null || filterMap == null) {
      return amount;
    }
    for (usal__CoverageLimitation__c climit : limitList) {
      if (climit.usal__MaximumAmount__c != null) {
        Decimal totalPayableAmount = getTotalPayableAmount(
          filterMap.get(climit)
        );
        Decimal tempResult = climit.usal__MaximumAmount__c - totalPayableAmount;
        if (amount == null || (amount != null && amount > tempResult)) {
          amount = tempResult;
        }
      }
    }
    return amount;
  }

  public Decimal getTotalPayableAmount(
    List<cve__CoverageClaimed__c> previousCC
  ) {
    Decimal total = 0;
    for (cve__CoverageClaimed__c cc : previousCC) {
      Decimal payableAmount = cc.cve__PayableAmount__c == null
        ? 0
        : cc.cve__PayableAmount__c;
      total += payableAmount;
    }
    return total;
  }

  public List<RecalculatePaymentSpec__e> generateEvents(
    List<cve__CoverageClaimed__c> ccList
  ) {
    List<RecalculatePaymentSpec__e> eventList = new List<RecalculatePaymentSpec__e>();
    Set<Id> bcWithStatus = new Set<Id>();
    Set<Id> bcWithoutStatus = new Set<Id>();
    for (cve__CoverageClaimed__c cc : ccList) {
      if (cc.cve__BenefitClaimed__r.ClaimBrainIntegrationStatus__c != null) {
        bcWithStatus.add(cc.cve__BenefitClaimed__c);
      } else {
        bcWithoutStatus.add(cc.cve__BenefitClaimed__c);
      }
    }

    List<cve__PaymentSpecification__c> psWithStatus = [
      SELECT id
      FROM cve__PaymentSpecification__c
      WHERE cve__BenefitClaimed__c IN :bcWithStatus
    ];
    List<cve__PaymentSpecification__c> psWithoutStatus = [
      SELECT id
      FROM cve__PaymentSpecification__c
      WHERE cve__BenefitClaimed__c IN :bcWithoutStatus
    ];

    for (cve__PaymentSpecification__c ps : psWithStatus) {
      eventList.add(
        new RecalculatePaymentSpec__e(
          PaymentSpecificationId__c = ps.id,
          RecalculatePaymentRequired__c = true,
          ClaimBrainCalculation__c = true
        )
      );
    }

    for (cve__PaymentSpecification__c ps : psWithoutStatus) {
      eventList.add(
        new RecalculatePaymentSpec__e(
          PaymentSpecificationId__c = ps.id,
          RecalculatePaymentRequired__c = true
        )
      );
    }
    return eventList;
  }

  public class AggregateValues {
    public Decimal amount;
    public Decimal units;
    public Decimal availableCount;

    public AggregateValues(
      Decimal amount,
      Decimal units,
      Decimal availableCount
    ) {
      this.amount = amount;
      this.units = units;
      this.availableCount = availableCount;
    }
  }

  public class CustomException extends Exception {
  }
}