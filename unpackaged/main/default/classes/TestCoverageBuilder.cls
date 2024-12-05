@IsTest
public class TestCoverageBuilder extends TestSObjectBuilder {
  // keeps count of Instances to allow differentiating objects built;
  // e.g. 'Test Account 1', 'Test Account 2'
  // specifically, increments when build() is called.
  static Integer iteration = 0;

  public TestCoverageBuilder() {
    setSObjectAndDefaultRecordType('cve__Coverage__c', 'VariableAmount');
    retrieveRecordtypes();

    this.values.put('builderId', iteration + 1);
  }

  private TestCoverageBuilder(TestCoverageBuilder oldBuilder) {
    this.values = oldBuilder.values;
    this.SOBJECT_TYPE = oldBuilder.SOBJECT_TYPE;
    this.DEFAULT_SOBJECT_RECORD_TYPE = oldBuilder.DEFAULT_SOBJECT_RECORD_TYPE;
  }

  protected override void addDefaultFieldsToValuesMap() {
    this.withName('Test VariableAmount Coverage')
      .withBenefit(null)
      .withRecordTypeId(getDefaultRecordTypeId())
      .withCoveredRelationshipsString(
        'Child;Domestic Partner;Same Person;Spouse'
      );
  }

  // candidate for abstract class (??)... or candidate for required method?
  protected override TestSObjectBuilder cloneBuilder() {
    TestCoverageBuilder newBuilder = new TestCoverageBuilder(this);

    Integer newBuilderId = (Integer) newBuilder.values.get('builderId');
    newBuilder.values.put('builderId', newBuilderId + 1);
    return newBuilder;
  }

  // candidate for abstract class -- using Type.forName() ??
  protected override void iterate() {
    TestCoverageBuilder.iteration += 1;
  }

  public TestCoverageBuilder withName(String name) {
    values.put('Name', name);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withBenefit(cve__Benefit__c benefit) {
    return withBenefitId(benefit.Id);
  }

  public TestCoverageBuilder withBenefitId(String benefitId) {
    values.put('cve__Benefit__c', benefitId);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withAmount(Decimal amount) {
    values.put('cve__Amount__c', amount);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withCoveredRelationships(
    List<String> coveredRelationships
  ) {
    return withCoveredRelationshipsString(
      String.join(coveredRelationships, ';')
    );
  }

  public TestCoverageBuilder withCoveredRelationshipsString(
    String coveredRelationshipsString
  ) {
    values.put('cve__CoveredRelationships__c', coveredRelationshipsString);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withMaximumAmount(Decimal maximumAmount) {
    values.put('cve__MaximumAmount__c', maximumAmount);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withMaximumUnits(Integer maximumUnits) {
    values.put('cve__MaximumUnits__c', maximumUnits);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withAmountPerUnit(Decimal amountPerUnit) {
    values.put('cve__AmountPerUnit__c', amountPerUnit);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withUnitName(String unitName) {
    values.put('cve__UnitName__c', unitName);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withRecordTypeId(Id rtId) {
    values.put('RecordTypeId', rtId);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withPercentageOf(Id per) {
    values.put('cve__PercentageOf__c', per);
    return (TestCoverageBuilder) cloneBuilder();
  }

  public TestCoverageBuilder withPercentage(Decimal per) {
    values.put('cve__Percentage__c', per);
    return (TestCoverageBuilder) cloneBuilder();
  }
}