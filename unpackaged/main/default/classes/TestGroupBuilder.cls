@IsTest
public with sharing class TestGroupBuilder extends TestSObjectBuilder {
  // keeps count of Instances to allow differentiating objects built;
  // e.g. 'Test Account 1', 'Test Account 2'
  // specifically, increments when build() is called.
  static Integer iteration = 0;

  public TestGroupBuilder() {
    setSObjectAndDefaultRecordType('Group__c', null);

    this.values.put('builderId', iteration + 1);
    addDefaultFieldsToValuesMap();
  }

  private TestGroupBuilder(TestGroupBuilder oldBuilder) {
    this.values = oldBuilder.values;
    this.SOBJECT_TYPE = oldBuilder.SOBJECT_TYPE;
    this.DEFAULT_SOBJECT_RECORD_TYPE = oldBuilder.DEFAULT_SOBJECT_RECORD_TYPE;
  }

  protected override TestSObjectBuilder cloneBuilder() {
    TestGroupBuilder newBuilder = new TestGroupBuilder(this);

    Integer newBuilderId = (Integer) newBuilder.values.get('builderId');
    newBuilder.values.put('builderId', newBuilderId + 1);
    return newBuilder;
  }

  // default values that apply to all instances across all tests
  protected override void addDefaultFieldsToValuesMap() {
    this.withName('Test Group ' + values.get('builderId'))
      .withMasterGroupId(null);
  }

  // candidate for abstract class -- using Type.forName() ??
  protected override void iterate() {
    TestGroupBuilder.iteration += 1;
  }

  // setters
  public TestGroupBuilder withName(String groupName) {
    values.put('Name', groupName);
    return (TestGroupBuilder) cloneBuilder();
  }

  public TestGroupBuilder withMasterGroupId(String accountId) {
    if (accountId != null) {
      values.put('Master_Group__c', accountId);
    }
    TestGroupBuilder returnBuilder = (TestGroupBuilder) cloneBuilder();
    return returnBuilder;
  }
}