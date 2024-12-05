@IsTest
public class TestCoverageClaimedBuilder extends TestSObjectBuilder {
  // keeps count of Instances to allow differentiating objects built;
  // e.g. 'Test Account 1', 'Test Account 2'
  // specifically, increments when build() is called.
  static Integer iteration = 0;

  public TestCoverageClaimedBuilder() {
    setSObjectAndDefaultRecordType('cve__CoverageClaimed__c', null);

    this.values.put('builderId', iteration + 1);
  }

  private TestCoverageClaimedBuilder(TestCoverageClaimedBuilder oldBuilder) {
    this.values = oldBuilder.values;
    this.SOBJECT_TYPE = oldBuilder.SOBJECT_TYPE;
    this.DEFAULT_SOBJECT_RECORD_TYPE = oldBuilder.DEFAULT_SOBJECT_RECORD_TYPE;
  }

  // candidate for abstract class (??)... or candidate for required method?
  protected override TestSObjectBuilder cloneBuilder() {
    TestCoverageClaimedBuilder newBuilder = new TestCoverageClaimedBuilder(
      this
    );

    Integer newBuilderId = (Integer) newBuilder.values.get('builderId');
    newBuilder.values.put('builderId', newBuilderId + 1);
    return newBuilder;
  }

  protected override void addDefaultFieldsToValuesMap() {
  }
  // candidate for abstract class -- using Type.forName() ??
  protected override void iterate() {
    TestCoverageClaimedBuilder.iteration += 1;
  }

  public TestCoverageClaimedBuilder withCoverage(cve__Coverage__c coverage) {
    values.put('cve__Coverage__r', coverage);
    return withCoverageId(coverage.Id);
  }

  public TestCoverageClaimedBuilder withCoverageId(String coverageId) {
    values.put('cve__Coverage__c', coverageId);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withBenefitClaimed(
    cve__BenefitClaimed__c benefitClaimed
  ) {
    values.put('cve__BenefitClaimed__r', benefitClaimed);
    return withBenefitClaimedId(benefitClaimed.Id);
  }

  public TestCoverageClaimedBuilder withBenefitClaimedId(Id benefitClaimedId) {
    values.put('cve__BenefitClaimed__c', benefitClaimedId);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withAmountFields(Decimal amount) {
    withPayableAmount(amount);
    withCalculatedAmount(amount);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withPayableAmount(Decimal payableAmount) {
    values.put('cve__PayableAmount__c', payableAmount);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withCalculatedAmount(
    Decimal calculatedAmount
  ) {
    values.put('cve__CalculatedAmount__c', calculatedAmount);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withUnitsFields(Integer units) {
    withPayableUnits(units);
    withClaimedUnits(units);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withPayableUnits(Integer payableUnits) {
    values.put('cve__PayableUnits__c', payableUnits);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withClaimedUnits(Integer claimedUnits) {
    values.put('cve__ClaimedUnits__c', claimedUnits);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withStartDate(Date startDate) {
    values.put('cve__Start__c', startDate);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withUnits(Integer units) {
    values.put('cve__Units__c', units);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }

  public TestCoverageClaimedBuilder withAmount(Decimal amount) {
    values.put('cve__Amount__c', amount);
    return (TestCoverageClaimedBuilder) cloneBuilder();
  }
}