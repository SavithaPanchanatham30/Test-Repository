/**
 * This class was added to increase readability and decrease development complexity
 * involved with setting up test data for Policies, Benefits, PolicyBenefits,
 * PolicyRelationships, and MemberBenefits by poulating default values and override
 * methods for PolicyRelaionship and MemberBenefit records
 */
@isTest
public class TestEnrollment {
  Contact con;
  cve__Policy__c policy;
  cve__Benefit__c benefit;
  cve__PolicyBenefit__c pb;
  cve__PolicyRelationship__c pr;
  usal__MemberBenefit__c mb;
  Date defaultDate = Date.newInstance(2000, 1, 1);
  static Map<String, cve__PolicyBenefit__c> pbMap = new Map<String, cve__PolicyBenefit__c>();

  public TestEnrollment(Contact con) {
    this.con = con;
  }

  public TestEnrollment withPolicy(cve__Policy__c policy) {
    this.policy = policy;
    checkPolicyBenefit();
    checkPolicyRelationship();
    return this;
  }

  public TestEnrollment withBenefit(cve__Benefit__c benefit) {
    this.benefit = benefit;
    checkPolicyBenefit();
    checkMemberBenefit();
    return this;
  }

  public TestEnrollment withPolicyRelationship(cve__PolicyRelationship__c pr) {
    this.pr = pr;
    return this;
  }

  public TestEnrollment withPolicyRelationshipType(
    String policyRelationshipType
  ) {
    this.pr.cve__Type__c = policyRelationshipType;
    return this;
  }

  private TestEnrollment withPolicyRelationshipStartDate(Date startDate) {
    this.pr.cve__Start__c = startDate;
    return this;
  }

  private TestEnrollment withPolicyRelationshipEndDate(Date endDate) {
    this.pr.cve__Through__c = endDate;
    return this;
  }

  private TestEnrollment withMemberBenefitStartDate(Date startDate) {
    this.mb.usal__StartDate__c = startDate;
    return this;
  }

  private TestEnrollment withMemberBenefitEndDate(Date endDate) {
    this.mb.usal__EndDate__c = endDate;
    return this;
  }

  private TestEnrollment withMemberBenefitAmount(Decimal amount) {
    this.mb.usal__Amount__c = amount;
    return this;
  }

  private void checkPolicyBenefit() {
    if (policy != null && benefit != null) {
      String identifier = '';
      identifier += policy.Id;
      identifier += benefit.Id;
      pbMap.put(
        identifier,
        new cve__PolicyBenefit__c(
          cve__Benefit__c = benefit.Id,
          cve__Policy__c = policy.Id,
          cve__Benefit__r = benefit,
          cve__Policy__r = policy
        )
      );
    }
  }

  private void checkPolicyRelationship() {
    if (policy != null && con != null) {
      pr = new cve__PolicyRelationship__c(
        cve__Contact__c = con.Id,
        cve__Policy__c = policy.Id,
        cve__Type__c = 'Policyholder',
        cve__Start__c = defaultDate,
        cve__Through__c = Date.today(),
        cve__Account__c = null
      );
    }
  }

  private void checkMemberBenefit() {
    if (con != null && benefit != null) {
      mb = new usal__MemberBenefit__c(
        usal__BenefitId__c = benefit.Id,
        usal__ContactId__c = con.Id,
        usal__StartDate__c = defaultDate,
        usal__EndDate__c = Date.today(),
        usal__Amount__c = 100
      );
    }
  }

  public static void insertEnrollments(List<TestEnrollment> enrollments) {
    List<SObject> sobjs = new List<SObject>();
    List<cve__PolicyRelationship__c> prs = new List<cve__PolicyRelationship__c>();
    List<usal__MemberBenefit__c> mbs = new List<usal__MemberBenefit__c>();

    for (TestEnrollment enrollment : enrollments) {
      prs.add(enrollment.pr);
      mbs.add(enrollment.mb);
    }

    sobjs.addAll(pbMap.values());
    sobjs.addAll(prs);
    sobjs.addAll(mbs);

    insert sobjs;
  }
}