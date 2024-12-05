public without sharing class ScopeMatcherUtil {
  public static Boolean scopesMatch(
    cve__CoverageClaimed__c newCC,
    usal__CoverageLimitation__c cl,
    cve__CoverageClaimed__c cc
  ) {
    Boolean isMatch = cl.usal__ByCategory__c
      ? isCategoryMatch(newCC, cc)
      : isCoverageMatch(newCC, cc);

    if (isMatch == false) {
      return false;
    }

    for (String scope : cl.usal__Scopes__c.split(';')) {
      if (!isScopeMatch(scope, newCC, cc, cl)) {
        return false;
      }
    }

    return true;
  }

  private static Boolean isScopeMatch(
    String scope,
    cve__CoverageClaimed__c newCC,
    cve__CoverageClaimed__c cc,
    usal__CoverageLimitation__c cl
  ) {
    Boolean isMatch = true;

    switch on scope {
      when 'Per Calendar Year' {
        isMatch = isCalendarYearMatch(newCC, cc);
      }
      when 'Per Policy Year' {
        isMatch = isPolicyYearMatch(newCC, cc);
      }
      when 'Per Accident Date' {
        isMatch = isAccidentDateMatch(newCC, cc);
      }
      when 'Per Claimant' {
        isMatch = isClaimantMatch(newCC, cc);
      }
      when 'Per Period (Days)' {
        isMatch = isPeriodMatch(newCC, cc, cl);
      }
    }

    return isMatch;
  }

  private static Boolean isCategoryMatch(
    cve__CoverageClaimed__c newCC,
    cve__CoverageClaimed__c cc
  ) {
    if (
      newCC?.cve__Coverage__r?.cve__Category__c == null ||
      cc?.cve__Coverage__r?.cve__Category__c == null
    ) {
      return false;
    }

    return newCC.cve__Coverage__r.cve__Category__c ==
      cc.cve__Coverage__r.cve__Category__c;
  }

  private static Boolean isCoverageMatch(
    cve__CoverageClaimed__c newCC,
    cve__CoverageClaimed__c cc
  ) {
    return newCC.cve__Coverage__c == cc.cve__Coverage__c;
  }

  private static Boolean isCalendarYearMatch(
    cve__CoverageClaimed__c newCC,
    cve__CoverageClaimed__c cc
  ) {
    if (cc?.cve__Start__c == null || newCC?.cve__Start__c == null) {
      return false;
    }
    return newCC.cve__Start__c.year() == cc.cve__Start__c.year();
  }

  private static Boolean isPolicyYearMatch(
    cve__CoverageClaimed__c newCC,
    cve__CoverageClaimed__c cc
  ) {
    if (cc?.cve__Start__c == null || newCC?.cve__Start__c == null) {
      return false;
    }

    Date policyEffectiveDate = newCC.cve__BenefitClaimed__r.cve__Claim__r.cve__Policy__r.cve__Effective__c;

    PolicyYear py = new PolicyYear(newCC, policyEffectiveDate);

    return cc.cve__Start__c >= py.policyYearStart &&
      cc.cve__Start__c <= py.policyYearEnd;
  }

  private static Boolean isAccidentDateMatch(
    cve__CoverageClaimed__c newCC,
    cve__CoverageClaimed__c cc
  ) {
    if (
      newCC.cve__BenefitClaimed__r?.IncurredDate__c == null ||
      cc.cve__BenefitClaimed__r?.IncurredDate__c == null
    ) {
      return false;
    }

    return newCC.cve__BenefitClaimed__r.IncurredDate__c ==
      cc.cve__BenefitClaimed__r.IncurredDate__c;
  }

  private static Boolean isClaimantMatch(
    cve__CoverageClaimed__c newCC,
    cve__CoverageClaimed__c cc
  ) {
    return newCC.cve__BenefitClaimed__r.cve__Claim__r.cve__ClaimantInsured__c ==
      cc.cve__BenefitClaimed__r.cve__Claim__r.cve__ClaimantInsured__c;
  }

  private static Boolean isPeriodMatch(
    cve__CoverageClaimed__c newCC,
    cve__CoverageClaimed__c cc,
    usal__CoverageLimitation__c cl
  ) {
    if (
      cc?.cve__Start__c == null ||
      newCC?.cve__Start__c == null ||
      cl?.usal__PeriodLengthDays__c == null
    ) {
      return false;
    }

    Date periodStart =
      newCC.cve__Start__c - Integer.valueOf(cl.usal__PeriodLengthDays__c);
    Date periodEnd =
      newCC.cve__Start__c + Integer.valueOf(cl.usal__PeriodLengthDays__c);

    return cc.cve__Start__c >= periodStart && cc.cve__Start__c < periodEnd;
  }

  class PolicyYear {
    public cve__CoverageClaimed__c cc;
    public Date policyEffectiveDate;
    public Date policyYearStart;
    public Date policyYearEnd;

    public PolicyYear(cve__CoverageClaimed__c cc, Date policyEffectiveDate) {
      this.cc = cc;
      this.policyEffectiveDate = policyEffectiveDate;

      getPolicyStartAndEnd();
    }

    private void getPolicyStartAndEnd() {
      Date policyYearStartDate = Date.newInstance(
        cc.cve__Start__c.year() - 1,
        policyEffectiveDate.month(),
        policyEffectiveDate.day()
      );
      Date policyYearEndDate =
        Date.newInstance(
          cc.cve__Start__c.year(),
          policyEffectiveDate.month(),
          policyEffectiveDate.day()
        ) - 1;

      if (
        cc.cve__Start__c >= policyYearStartDate &&
        cc.cve__Start__c <= policyYearEndDate
      ) {
        policyYearStart = policyYearStartDate;
        policyYearEnd = policyYearEndDate;
      } else {
        policyYearStart = policyYearStartDate.addYears(1);
        policyYearEnd = policyYearEndDate.addYears(1);
      }
    }
  }
}