@IsTest
public class TestClaimBuilder extends TestSObjectBuilder {
  // keeps count of Instances to allow differentiating objects built;
  // e.g. 'Test Account 1', 'Test Account 2'
  // specifically, increments when build() is called.
  static Integer iteration = 0;

  public TestClaimBuilder() {
    setSObjectAndDefaultRecordType('cve__Claim__c', null);

    this.values.put('builderId', iteration + 1);
    addDefaultFieldsToValuesMap();
  }

  private TestClaimBuilder(TestClaimBuilder oldBuilder) {
    this.values = oldBuilder.values;
    this.SOBJECT_TYPE = oldBuilder.SOBJECT_TYPE;
  }

  // candidate for abstract class (??)... or candidate for required method?
  protected override TestSObjectBuilder cloneBuilder() {
    TestClaimBuilder newBuilder = new TestClaimBuilder(this);

    Integer newBuilderId = (Integer) newBuilder.values.get('builderId');
    newBuilder.values.put('builderId', newBuilderId + 1);
    return newBuilder;
  }

  // default values that apply to all instances across all tests
  protected override void addDefaultFieldsToValuesMap() {
    this.withStatus('Open');
  }

  // candidate for abstract class -- using Type.forName() ??
  protected override void iterate() {
    TestClaimBuilder.iteration += 1;
  }

  // setters
  public TestClaimBuilder withPolicy(cve__Policy__c policy) {
    values.put('cve__Policy__r', policy);
    return (TestClaimBuilder) withPolicyId(policy.Id);
  }

  public TestClaimBuilder withPolicyId(Id policyId) {
    values.put('cve__Policy__c', policyId);
    return (TestClaimBuilder) cloneBuilder();
  }

  public TestClaimBuilder withPolicyRelationship(
    cve__Policy__c policy,
    Contact con
  ) {
    return (TestClaimBuilder) withPolicyRelationship(
      policy,
      con,
      'Policyholder'
    );
  }

  public TestClaimBuilder withPolicyRelationship(
    cve__Policy__c policy,
    Contact con,
    String relationship
  ) {
    relationship = relationship != null ? relationship : 'Policyholder';
    cve__PolicyRelationship__c pr = [
      SELECT Id
      FROM cve__PolicyRelationship__c
      WHERE
        cve__Policy__c = :policy.Id
        AND cve__Contact__c = :con.Id
        AND cve__Type__c = :relationship
      LIMIT 1
    ];
    values.put('cve__PolicyRelationship__r', pr);
    return (TestClaimBuilder) withPolicyRelationshipId(pr.Id)
      .withPolicy(policy)
      .withClaimantInsured(con);
  }

  public TestClaimBuilder withPolicyRelationshipId(Id prId) {
    values.put('cve__PolicyRelationship__c', prId);
    return (TestClaimBuilder) cloneBuilder();
  }

  public TestClaimBuilder withClaimantInsured(Contact con) {
    values.put('cve__ClaimantInsured__r', con);
    return (TestClaimBuilder) withClaimantInsuredId(con.Id);
  }

  public TestClaimBuilder withClaimantInsuredId(Id claimantId) {
    values.put('cve__ClaimantInsured__c', claimantId);
    return (TestClaimBuilder) cloneBuilder();
  }

  public TestClaimBuilder withStatus(String status) {
    values.put('cve__Status__c', status);
    return (TestClaimBuilder) cloneBuilder();
  }
}