@IsTest
public class TestAccountBuilder extends TestSObjectBuilder {
  // keeps count of Instances to allow differentiating objects built;
  // e.g. 'Test Account 1', 'Test Account 2'
  // specifically, increments when build() is called.
  static Integer iteration = 0;

  public TestAccountBuilder() {
    setSObjectAndDefaultRecordType('Account', 'Master_Group');
    retrieveRecordtypes();

    this.values.put('builderId', iteration + 1);
    addDefaultFieldsToValuesMap();
  }

  private TestAccountBuilder(TestAccountBuilder oldBuilder) {
    this.values = oldBuilder.values;
    this.SOBJECT_TYPE = oldBuilder.SOBJECT_TYPE;
    this.DEFAULT_SOBJECT_RECORD_TYPE = oldBuilder.DEFAULT_SOBJECT_RECORD_TYPE;
  }

  // candidate for abstract class (??)... or candidate for required method?
  protected override TestSObjectBuilder cloneBuilder() {
    TestAccountBuilder newBuilder = new TestAccountBuilder(this);

    Integer newBuilderId = (Integer) newBuilder.values.get('builderId');
    newBuilder.values.put('builderId', newBuilderId + 1);
    return newBuilder;
  }

  // default values that apply to all instances across all tests
  protected override void addDefaultFieldsToValuesMap() {
    this.withAccountName('Test Account ' + values.get('builderId'))
      .withEmployees(100)
      .withBillingState('MA')
      .withRecordTypeId(getDefaultRecordTypeId());
  }

  // candidate for abstract class -- using Type.forName() ??
  protected override void iterate() {
    TestAccountBuilder.iteration += 1;
  }

  // setters
  public TestAccountBuilder withAccountName(String accountName) {
    values.put('Name', accountName);
    return (TestAccountBuilder) cloneBuilder();
  }

  public TestAccountBuilder withEmployees(Integer numberOfEmployees) {
    values.put('NumberOfEmployees', numberOfEmployees);
    return (TestAccountBuilder) cloneBuilder();
  }

  public TestAccountBuilder withBillingState(String billingState) {
    values.put('BillingState', billingState);
    return (TestAccountBuilder) cloneBuilder();
  }

  public TestAccountBuilder withRecordTypeName(String rtName) {
    values.put('RecordTypeId', getRecordTypeIdByName(rtName));
    return (TestAccountBuilder) cloneBuilder();
  }

  public TestAccountBuilder withRecordTypeId(Id rtId) {
    values.put('RecordTypeId', rtId);
    return (TestAccountBuilder) cloneBuilder();
  }
}