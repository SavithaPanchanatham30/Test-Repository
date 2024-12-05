public with sharing class BenefitCoverageClaimedSelector {
  private Map<cve__CoverageClaimed__c, List<cve__CoverageClaimed__c>> preexistingCoveragesClaimedByNewCoverageClaimed;
  private Map<Id, cve__BenefitClaimed__c> benefitsCoveragesClaimed;
  private Map<Id, usal__MemberBenefit__c> memberBenefitByBenefitClaimedId;
  private Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>> coverageLimitationsByCoveragesClaimed;
  private Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> coveragesClaimedByCoverageLimitation;
  private static BenefitCoverageClaimedSelector instance = null;
  private static Map<String, Map<Id, cve__BenefitClaimed__c>> benefitsCoveragesClaimedSupermap;
  private static Map<String, Map<Id, usal__MemberBenefit__c>> memberBenefitsSupermap;

  public BenefitCoverageClaimedSelector() {
    if (Test.isRunningTest()) {
      this(true);
    } else {
      throw new CustomException(
        'Please use getInstance method instead of directly instantiating the class'
      );
    }
  }

  private BenefitCoverageClaimedSelector(Boolean mockSingleton) {
    benefitsCoveragesClaimedSupermap = new Map<String, Map<Id, cve__BenefitClaimed__c>>();
    memberBenefitsSupermap = new Map<String, Map<Id, usal__MemberBenefit__c>>();
  }

  public static BenefitCoverageClaimedSelector getInstance() {
    if (instance == null) {
      instance = new BenefitCoverageClaimedSelector(true);
    }
    return instance;
  }

  public Map<cve__CoverageClaimed__c, List<cve__CoverageClaimed__c>> getPreexistingCoveragesClaimed(
    List<cve__CoverageClaimed__c> coveragesClaimed
  ) {
    Map<String, List<Object>> outputsFromIteratingCoveragesClaimed = iterateCoveragesClaimed(
      coveragesClaimed
    );
    getBenefitsCoveragesClaimed(
      (List<cve__BenefitClaimed__c>) outputsFromIteratingCoveragesClaimed.get(
        'BenefitsClaimed'
      )
    );

    Map<String, List<Id>> coverageClaimedRelatedIds = getRelatedIds(
      coveragesClaimed
    );

    CoverageClaimedIds ccs = new CoverageClaimedIds()
      .withContacts(coverageClaimedRelatedIds.get('Contacts'))
      .withPolicies(coverageClaimedRelatedIds.get('Policies'))
      .withExistingIds(
        (List<Id>) outputsFromIteratingCoveragesClaimed.get(
          'CoverageClaimedIds'
        )
      )
      .withCoverageIds(
        (List<Id>) outputsFromIteratingCoveragesClaimed.get('CoverageIds')
      );

    List<cve__CoverageClaimed__c> existingCoveragesClaimed = queryCoveragesClaimed(
      ccs
    );

    preexistingCoveragesClaimedByNewCoverageClaimed = matchPreexistingCoveragesClaimedToNew(
      coveragesClaimed,
      existingCoveragesClaimed
    );

    return preexistingCoveragesClaimedByNewCoverageClaimed;
  }

  private Map<String, List<Object>> iterateCoveragesClaimed(
    List<cve__CoverageClaimed__c> coveragesClaimed
  ) {
    Map<String, List<Object>> iterationOutputsByType = new Map<String, List<Object>>();
    List<cve__BenefitClaimed__c> benefitsClaimed;
    List<Id> coverageIds = new List<Id>();
    List<Id> updatedCoverageClaimedIds = new List<Id>();

    Set<cve__BenefitClaimed__c> bcSet = new Set<cve__BenefitClaimed__c>();
    for (cve__CoverageClaimed__c coverageClaimed : coveragesClaimed) {
      bcSet.add(
        new cve__BenefitClaimed__c(Id = coverageClaimed.cve__BenefitClaimed__c)
      );
      coverageIds.add(coverageClaimed.cve__Coverage__c);

      if (coverageClaimed.Id != null) {
        updatedCoverageClaimedIds.add(coverageClaimed.Id);
      }
    }
    benefitsClaimed = new List<cve__BenefitClaimed__c>(bcSet);

    iterationOutputsByType.put('BenefitsClaimed', benefitsClaimed);
    iterationOutputsByType.put('CoverageIds', coverageIds);
    iterationOutputsByType.put('CoverageClaimedIds', updatedCoverageClaimedIds);

    return iterationOutputsByType;
  }

  private Map<String, List<Id>> getRelatedIds(
    List<cve__CoverageClaimed__c> ccs
  ) {
    List<Id> policyholderIds = new List<Id>();
    List<Id> policyIds = new List<Id>();

    for (cve__CoverageClaimed__c cc : ccs) {
      policyholderIds.add(
        benefitsCoveragesClaimed.get(cc.cve__BenefitClaimed__c)
          .cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c
      );
      policyIds.add(
        benefitsCoveragesClaimed.get(cc.cve__BenefitClaimed__c)
          .cve__Claim__r.cve__PolicyRelationship__r.cve__Policy__c
      );
    }

    return new Map<String, List<Id>>{
      'Contacts' => policyholderIds,
      'Policies' => policyIds
    };
  }

  private List<cve__CoverageClaimed__C> queryCoveragesClaimed(
    CoverageClaimedIds ccs
  ) {
    return [
      SELECT
        Id,
        cve__BenefitClaimed__c,
        cve__BenefitName__c,
        cve__ClaimId__c,
        cve__CalculatedAmount__c,
        cve__Units__c,
        cve__Coverage__c,
        cve__CoverageAmount__c,
        cve__CoverageRelationshipToPolicyholder__c,
        cve__EffectiveDateOfCoverage__c,
        cve__InvoiceLineItem__c,
        cve__PayableAmount__c,
        cve__PayableUnits__c,
        cve__Start__c,
        cve__Status__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__ClaimantInsured__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Policy__c,
        cve__BenefitClaimed__r.cve__DateOfDisability__c,
        cve__BenefitClaimed__r.cve__Benefit__c,
        cve__BenefitClaimed__r.cve__ClaimantInsured__c,
        cve__BenefitClaimed__r.cve__Policy__c,
        cve__BenefitClaimed__r.IncurredDate__c,
        cve__Coverage__r.cve__Category__c
      FROM cve__CoverageClaimed__c
      WHERE
        Id NOT IN :ccs.existingUpdatedCoverageClaimedIds
        AND cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c IN :ccs.contacts
        AND cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Policy__c IN :ccs.policies
        AND cve__PayableAmount__c != 0
        AND cve__Status__c != 'Denied'
    ];
  }

  private Map<cve__CoverageClaimed__c, List<cve__CoverageClaimed__c>> matchPreexistingCoveragesClaimedToNew(
    List<cve__CoverageClaimed__c> newCCs,
    List<cve__CoverageClaimed__c> existingCCs
  ) {
    Map<cve__CoverageClaimed__c, List<cve__CoverageClaimed__c>> preexistingCoveragesClaimed = new Map<cve__CoverageClaimed__c, List<cve__CoverageClaimed__c>>();

    for (cve__CoverageClaimed__c newCC : newCCs) {
      preexistingCoveragesClaimed.put(
        newCC,
        getRelatedExistingCCs(newCC, existingCCs)
      );
    }

    return preexistingCoveragesClaimed;
  }

  private List<cve__CoverageClaimed__c> getRelatedExistingCCs(
    cve__CoverageClaimed__c cc,
    List<cve__CoverageClaimed__c> existingCCs
  ) {
    List<cve__CoverageClaimed__c> relatedCCs = new List<cve__CoverageClaimed__c>();

    for (cve__CoverageClaimed__c exister : existingCCs) {
      if (ccsAreRelated(exister, cc)) {
        relatedCCs.add(exister);
      }
    }

    return relatedCCs;
  }

  private Boolean ccsAreRelated(
    cve__CoverageClaimed__c cc1,
    cve__CoverageClaimed__c cc2
  ) {
    Boolean ccsSharePolicy = getPolicy(cc1) == getPolicy(cc2);
    Boolean ccsSharePolicyholder = getPolicyholder(cc1) == getPolicyholder(cc2);
    return ccsSharePolicyholder && ccsSharePolicy;
  }

  private String getPolicyholder(cve__CoverageClaimed__c cc) {
    String policyholderId = cc
        ?.cve__BenefitClaimed__r
        ?.cve__Claim__r
        ?.cve__PolicyRelationship__r
        ?.cve__Contact__c == null
      ? benefitsCoveragesClaimed
          ?.get(cc.cve__BenefitClaimed__c)
          ?.cve__Claim__r
          ?.cve__PolicyRelationship__r
          ?.cve__Contact__c
      : cc.cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c;

    return policyholderId != null ? policyholderId : '';
  }

  private String getPolicy(cve__CoverageClaimed__c cc) {
    String policyId = cc
        ?.cve__BenefitClaimed__r
        ?.cve__Claim__r
        ?.cve__PolicyRelationship__r
        ?.cve__Policy__c == null
      ? benefitsCoveragesClaimed
          ?.get(cc.cve__BenefitClaimed__c)
          ?.cve__Claim__r
          ?.cve__PolicyRelationship__r
          ?.cve__Policy__c
      : cc.cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Policy__c;

    return policyId != null ? policyId : '';
  }

  public Map<Id, cve__BenefitClaimed__c> getBenefitsCoveragesClaimed(
    List<cve__BenefitClaimed__c> benefitsClaimed
  ) {
    String bcsIdKey = extractAndSortIds(benefitsClaimed);

    //I commented it because it was giving me old copies of coverage claimed that was messing up things in Benefit Claimed update
    /*if (benefitsCoveragesClaimedSupermap.containsKey(bcsIdKey)) {
      benefitsCoveragesClaimed = benefitsCoveragesClaimedSupermap.get(bcsIdKey);
      return benefitsCoveragesClaimed;
    }*/

    benefitsCoveragesClaimed = new Map<Id, cve__BenefitClaimed__c>(
      [
        SELECT
          Id,
          Name,
          CreatedById,
          cve__Explanation2__c,
          cve__BaseCoverageAmount__c,
          cve__Benefit__c,
          IncurredDate__c,
          cve__DateOfDisability__c,
          cve__Benefit__r.cve__CoverageAmount__c,
          cve__Claim__c,
          cve__Claim__r.IncurredDate__c,
          cve__Claim__r.cve__ClaimantInsured__c,
          cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
          cve__Claim__r.cve__PolicyRelationship__r.cve__Policy__c,
          cve__ClaimantInsured__c,
          cve__ClaimantInsuredAccount__c,
          cve__ClaimantInsuredName__c,
          cve__CoverageAmount__c,
          cve__CoverageAmountRemaining__c,
          cve__CriticalBurnMaximum__c,
          cve__CurrentAccountValue__c,
          cve__FeloniousAssaultMaximum__c,
          cve__FirstNotified__c,
          cve__HasReinsurance__c,
          cve__Hemiplegia__c,
          cve__HigherEducationMaximum__c,
          cve__IncurredBeforeTax__c,
          cve__Policy__c,
          RecordTypeId,
          (
            SELECT
              Id,
              Name,
              cve__BenefitClaimed__c,
              cve__BenefitName__c,
              cve__ClaimId__c,
              cve__CalculatedAmount__c,
              cve__Units__c,
              cve__Coverage__c,
              cve__Coverage__r.RecordTypeId,
              cve__Coverage__r.Name,
              cve__Coverage__r.cve__Amount__c,
              cve__Coverage__r.cve__AmountPerUnit__c,
              cve__Coverage__r.cve__Category__c,
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
            FROM cve__CoveragesClaimed__r
          )
        FROM cve__BenefitClaimed__c
        WHERE Id IN :benefitsClaimed
      ]
    );

    bcsIdKey = extractAndSortIds(benefitsCoveragesClaimed.values());
    benefitsCoveragesClaimedSupermap.put(bcsIdKey, benefitsCoveragesClaimed);

    return benefitsCoveragesClaimed;
  }

  private String extractAndSortIds(List<SObject> sobjs) {
    List<String> sobjIdKey = new List<String>();

    for (SObject sobj : sobjs) {
      sobjIdKey.add(sobj.Id);
    }

    sobjIdKey.sort();
    return String.join(sobjIdKey, ':');
  }

  public Map<Id, usal__MemberBenefit__c> getMemberBenefits(
    List<cve__BenefitClaimed__c> benefitsClaimed
  ) {
    String bcsIdKey = extractAndSortIds(benefitsClaimed);

    if (memberBenefitsSupermap.containsKey(bcsIdKey)) {
      memberBenefitByBenefitClaimedId = memberBenefitsSupermap.get(bcsIdKey);
      return memberBenefitByBenefitClaimedId;
    }

    BenefitClaimedMemberBenefitIds bcMbIds = buildBenefitClaimedMemberBenefits(
      benefitsClaimed
    );

    List<usal__MemberBenefit__c> memberBenefits = queryMemberBenefits(bcMbIds);

    memberBenefitByBenefitClaimedId = mapBenefitClaimedIdToMemberBenefit(
      memberBenefits,
      benefitsClaimed
    );

    memberBenefitsSupermap.put(bcsIdKey, memberBenefitByBenefitClaimedId);

    return memberBenefitByBenefitClaimedId;
  }

  private BenefitClaimedMemberBenefitIds buildBenefitClaimedMemberBenefits(
    List<cve__BenefitClaimed__c> benefitsClaimed
  ) {
    BenefitClaimedMemberBenefitIds bcMbIds = new BenefitClaimedMemberBenefitIds();

    for (cve__BenefitClaimed__c bc : benefitsClaimed) {
      if (bc.cve__Benefit__c != null && bc.cve__ClaimantInsured__c != null) {
        bcMbIds.benefitIds.add(bc.cve__Benefit__c);
        bcMbIds.claimantIds.add(bc.cve__ClaimantInsured__c);
      }
    }

    return bcMbIds;
  }

  private List<usal__MemberBenefit__c> queryMemberBenefits(
    BenefitClaimedMemberBenefitIds bcMbIds
  ) {
    return [
      SELECT
        Id,
        usal__BenefitId__c,
        usal__ContactId__c,
        usal__EndDate__c,
        usal__StartDate__c,
        usal__Amount__c
      FROM usal__MemberBenefit__c
      WHERE
        usal__BenefitId__c IN :bcMbIds.benefitIds
        AND usal__ContactId__c IN :bcMbIds.claimantIds
    ];
  }

  private Map<Id, usal__MemberBenefit__c> mapBenefitClaimedIdToMemberBenefit(
    List<usal__MemberBenefit__c> memberBenefits,
    List<cve__BenefitClaimed__c> benefitsClaimed
  ) {
    Map<Id, usal__MemberBenefit__c> memberBenefitsByBenefitClaimed = new Map<Id, usal__MemberBenefit__c>();

    for (cve__BenefitClaimed__c bc : benefitsClaimed) {
      Date disabilityIncurredDate = bc.IncurredDate__c == null
        ? bc.cve__DateOfDisability__c
        : bc.IncurredDate__c;

      for (usal__MemberBenefit__c mb : memberBenefits) {
        if (
          bc?.cve__ClaimantInsured__c == mb?.usal__ContactId__c &&
          bc?.cve__Benefit__c == mb?.usal__BenefitId__c &&
          ((mb.usal__EndDate__c == null &&
          mb.usal__StartDate__c != null &&
          disabilityIncurredDate >= mb.usal__StartDate__c) ||
          (mb.usal__EndDate__c != null &&
          mb.usal__StartDate__c == null &&
          disabilityIncurredDate <= mb.usal__EndDate__c) ||
          (disabilityIncurredDate <= mb.usal__EndDate__c &&
          disabilityIncurredDate >= mb.usal__StartDate__c))
        ) {
          memberBenefitsByBenefitClaimed.put(bc.Id, mb);
          continue;
        }
      }
    }

    return memberBenefitsByBenefitClaimed;
  }

  public Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>> getCoverageLimitations(
    List<cve__CoverageClaimed__c> coveragesClaimed
  ) {
    Set<Id> coverageIds = new Set<Id>();
    for (cve__CoverageClaimed__c covClaim : coveragesClaimed) {
      coverageIds.add(covClaim.cve__Coverage__c);
    }

    Map<Id, cve__Coverage__c> coverages = queryCoveragesAndLimitations(
      coverageIds
    );

    coverageLimitationsByCoveragesClaimed = buildCoverageLimitationsByCoveragesClaimed(
      coveragesClaimed,
      coverages
    );
    return coverageLimitationsByCoveragesClaimed;
  }

  private Map<Id, cve__Coverage__c> queryCoveragesAndLimitations(
    Set<Id> coverageIds
  ) {
    return new Map<Id, cve__Coverage__c>(
      [
        SELECT
          Id,
          Name,
          RecordTypeId,
          RecordType.Name,
          cve__Benefit__c,
          cve__Benefit__r.Name,
          cve__Category__c,
          (
            SELECT
              Id,
              usal__ByCategory__c,
              usal__Coverage__c,
              usal__MaximumAmount__c,
              usal__MaximumTimesClaimed__c,
              usal__MaximumUnits__c,
              usal__PeriodLengthDays__c,
              usal__Scopes__c
            FROM usal__CoverageLimitations__r
          )
        FROM cve__Coverage__c
        WHERE Id IN :coverageIds
      ]
    );
  }

  private Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>> buildCoverageLimitationsByCoveragesClaimed(
    List<cve__CoverageClaimed__c> coveragesClaimed,
    Map<Id, cve__Coverage__c> coverages
  ) {
    Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>> coverageLimitationsByCC = new Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>>();
    for (cve__CoverageClaimed__c cc : coveragesClaimed) {
      List<usal__CoverageLimitation__c> coverageLimitations = coverages
        ?.get(cc?.cve__Coverage__c)
        ?.usal__CoverageLimitations__r;
      if (coverageLimitations != null && !coverageLimitations.isEmpty()) {
        coverageLimitationsByCC.put(cc, coverageLimitations);
      }
    }

    return coverageLimitationsByCC;
  }

  public Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filterCoveragesClaimedByCoverageLimitations(
    List<cve__CoverageClaimed__c> coveragesClaimed
  ) {
    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> nestedCoveragesClaimedByCoverageLimitation = new Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>>();
    List<AppliedLimitation> appliedLimitations = buildAppliedLimitations(
      coveragesClaimed
    );

    for (AppliedLimitation al : appliedLimitations) {
      if (
        al.coverageClaimed == null ||
        al.coverageLimitations == null ||
        al.preexistingCoveragesClaimed == null
      ) {
        continue;
      }

      Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>> coveragesClaimedByCoverageLimitations = filterAndMapByCoverageLimitations(
        al
      );
      nestedCoveragesClaimedByCoverageLimitation.put(
        al.coverageClaimed,
        coveragesClaimedByCoverageLimitations
      );
    }
    return nestedCoveragesClaimedByCoverageLimitation;
  }

  private List<AppliedLimitation> buildAppliedLimitations(
    List<cve__CoverageClaimed__c> coveragesClaimed
  ) {
    List<AppliedLimitation> appliedLimitations = new List<AppliedLimitation>();

    for (cve__CoverageClaimed__c cc : coveragesClaimed) {
      AppliedLimitation al = new AppliedLimitation();
      al.coverageClaimed = cc;
      al.coverageLimitations = getCoverageLimitations(coveragesClaimed)
        ?.get(cc);
      al.preexistingCoveragesClaimed = getPreexistingCoveragesClaimed(
          coveragesClaimed
        )
        ?.get(cc);
      appliedLimitations.add(al);
    }

    return appliedLimitations;
  }

  private Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>> filterAndMapByCoverageLimitations(
    AppliedLimitation al
  ) {
    Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>> limitationMap = new Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>();
    for (usal__CoverageLimitation__c cl : al.coverageLimitations) {
      if (cl.usal__Scopes__c == null) {
        continue;
      }
      List<cve__CoverageClaimed__c> filteredPreexistingCCs = filterCCsByLimitations(
        al.coverageClaimed,
        cl,
        al.preexistingCoveragesClaimed
      );
      limitationMap.put(cl, filteredPreexistingCCs);
    }

    return limitationMap;
  }

  private List<cve__CoverageClaimed__c> filterCCsByLimitations(
    cve__CoverageClaimed__c newCC,
    usal__CoverageLimitation__c cl,
    List<cve__CoverageClaimed__c> ccs
  ) {
    List<cve__CoverageClaimed__c> filteredList = new List<cve__CoverageClaimed__c>();

    for (cve__CoverageClaimed__c cc : ccs) {
      if (ScopeMatcherUtil.scopesMatch(newCC, cl, cc)) {
        filteredList.add(cc);
      }
    }

    return filteredList;
  }

  public Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>> refreshKeys(
    List<cve__CoverageClaimed__c> ccs,
    Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>> ccMap
  ) {
    for (cve__CoverageClaimed__c cc : ccs) {
      for (cve__CoverageClaimed__c oldCC : ccMap.keySet()) {
        if (cc.Id == oldCC.Id && ccMap?.get(cc) == null) {
          ccMap.put(cc, ccMap.get(oldCC));
          ccMap.remove(oldCC);
        }
      }
    }

    return ccMap;
  }

  public Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> refreshKeys(
    List<cve__CoverageClaimed__c> ccs,
    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> ccMap
  ) {
    for (cve__CoverageClaimed__c cc : ccs) {
      for (cve__CoverageClaimed__c oldCC : ccMap.keySet()) {
        if (cc.Id == oldCC.Id && ccMap?.get(cc) == null) {
          ccMap.put(cc, ccMap.get(oldCC));
          ccMap.remove(oldCC);
        }
      }
    }

    return ccMap;
  }

  public Map<cve__CoverageClaimed__c, List<cve__CoverageClaimed__c>> refreshKeys(
    List<cve__CoverageClaimed__c> ccs,
    Map<cve__CoverageClaimed__c, List<cve__CoverageClaimed__c>> ccMap
  ) {
    for (cve__CoverageClaimed__c cc : ccs) {
      for (cve__CoverageClaimed__c oldCC : ccMap.keySet()) {
        if (cc.Id == oldCC.Id && ccMap?.get(cc) == null) {
          ccMap.put(cc, ccMap.get(oldCC));
          ccMap.remove(oldCC);
        }
      }
    }

    return ccMap;
  }

  class CoverageClaimedIds {
    List<Id> contacts;
    List<Id> policies;
    List<Id> existingUpdatedCoverageClaimedIds;
    List<Id> coverageIds;

    public CoverageClaimedIds withContacts(List<Id> contacts) {
      this.contacts = contacts;
      return this;
    }

    public CoverageClaimedIds withPolicies(List<Id> policies) {
      this.policies = policies;
      return this;
    }

    public CoverageClaimedIds withExistingIds(List<Id> existingIds) {
      this.existingUpdatedCoverageClaimedIds = existingIds;
      return this;
    }

    public CoverageClaimedIds withCoverageIds(List<Id> coverageIds) {
      this.coverageIds = coverageIds;
      return this;
    }
  }

  class BenefitClaimedMemberBenefitIds {
    List<Id> claimantIds;
    List<Id> benefitIds;

    public BenefitClaimedMemberBenefitIds() {
      this.claimantIds = new List<Id>();
      this.benefitIds = new List<Id>();
    }
  }

  class AppliedLimitation {
    List<cve__CoverageClaimed__c> preexistingCoveragesClaimed;
    List<usal__CoverageLimitation__c> coverageLimitations;
    cve__CoverageClaimed__c coverageClaimed;

    public AppliedLimitation withPreexistingCoveragesClaimed(
      List<cve__CoverageClaimed__c> preexistingCoveragesClaimed
    ) {
      this.preexistingCoveragesClaimed = preexistingCoveragesClaimed;
      preexistingCoveragesClaimed = new List<cve__CoverageClaimed__c>();
      return this;
    }

    public AppliedLimitation withCoverageLimitations(
      List<usal__CoverageLimitation__c> coverageLimitations
    ) {
      this.coverageLimitations = coverageLimitations;
      coverageLimitations = new List<usal__CoverageLimitation__c>();
      return this;
    }

    public AppliedLimitation withCoverageClaimed(
      cve__CoverageClaimed__c coverageClaimed
    ) {
      this.coverageClaimed = coverageClaimed;
      return this;
    }
  }

  public class CustomException extends Exception {
  }
}