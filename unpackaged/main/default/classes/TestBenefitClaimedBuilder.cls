@IsTest
public class TestBenefitClaimedBuilder extends TestSObjectBuilder {
  // keeps count of Instances to allow differentiating objects built;
  // e.g. 'Test Account 1', 'Test Account 2'
  // specifically, increments when build() is called.
  static Integer iteration = 0;

  public TestBenefitClaimedBuilder() {
    setSObjectAndDefaultRecordType(
      'cve__BenefitClaimed__c',
      'ShortTermDisability'
    );
    retrieveRecordtypes();

    this.values.put('builderId', iteration + 1);
    addDefaultFieldsToValuesMap();
  }

  private TestBenefitClaimedBuilder(TestBenefitClaimedBuilder oldBuilder) {
    this.values = oldBuilder.values;
    this.SOBJECT_TYPE = oldBuilder.SOBJECT_TYPE;
    this.DEFAULT_SOBJECT_RECORD_TYPE = oldBuilder.DEFAULT_SOBJECT_RECORD_TYPE;
    this.recordTypes = oldBuilder.recordTypes;
  }

  // candidate for abstract class (??)... or candidate for required method?
  protected override TestSObjectBuilder cloneBuilder() {
    TestBenefitClaimedBuilder newBuilder = new TestBenefitClaimedBuilder(this);

    Integer newBuilderId = (Integer) newBuilder.values.get('builderId');
    newBuilder.values.put('builderId', newBuilderId + 1);
    return newBuilder;
  }

  // default values that apply to all instances across all tests
  protected override void addDefaultFieldsToValuesMap() {
    this.withDates(Date.newInstance(2024, 1, 1))
      .withStatus('Approved')
      .withRecordTypeId(getDefaultRecordTypeId());
  }

  // candidate for abstract class -- using Type.forName() ??
  protected override void iterate() {
    TestBenefitClaimedBuilder.iteration += 1;
  }

  // setters
  public TestBenefitClaimedBuilder withClaim(cve__Claim__c claim) {
    values.put('cve__Claim__r', claim);
    return (TestBenefitClaimedBuilder) withClaimId(claim.Id)
      .withClaimantInsuredId(claim.cve__ClaimantInsured__c)
      .withPolicyId(claim.cve__Policy__c);
  }

  public TestBenefitClaimedBuilder withClaimId(Id claimId) {
    values.put('cve__Claim__c', claimId);
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }

  public TestBenefitClaimedBuilder withPolicyId(Id policyId) {
    values.put('cve__Policy__c', policyId);
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }

  public TestBenefitClaimedBuilder withClaimantInsured(Contact con) {
    values.put('cve__ClaimantInsured__r', con);
    return (TestBenefitClaimedBuilder) withClaimantInsuredId(con.Id);
  }

  public TestBenefitClaimedBuilder withClaimantInsuredId(Id claimantId) {
    values.put('cve__ClaimantInsured__c', claimantId);
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }

  public TestBenefitClaimedBuilder withBenefit(cve__Benefit__c benefit) {
    return (TestBenefitClaimedBuilder) withBenefitId(benefit.Id);
  }

  public TestBenefitClaimedBuilder withBenefitId(Id benefitId) {
    values.put('cve__Benefit__c', benefitId);
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }

  public TestBenefitClaimedBuilder withDates(Date bcDate) {
    return (TestBenefitClaimedBuilder) withDisabilityDate(bcDate)
      .withIncurredDate(bcDate);
  }

  public TestBenefitClaimedBuilder withDisabilityDate(Date bcDate) {
    values.put('cve__DateOfDisability__c', bcDate);
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }

  public TestBenefitClaimedBuilder withIncurredDate(Date bcDate) {
    values.put('IncurredDate__c', bcDate);
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }

  public TestBenefitClaimedBuilder withBenefitAmount(Decimal benefitAmount) {
    values.put('cve__BenefitAmount__c', benefitAmount);
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }

  public TestBenefitClaimedBuilder withStatus(String status) {
    values.put('cve__Status__c', status);
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }

  public TestBenefitClaimedBuilder withRecordTypeDeveloperName(String rtName) {
    values.put('RecordTypeId', getRecordTypeIdByName(rtName));
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }

  public TestBenefitClaimedBuilder withRecordTypeId(Id rtId) {
    values.put('RecordTypeId', rtId);
    return (TestBenefitClaimedBuilder) cloneBuilder();
  }
}