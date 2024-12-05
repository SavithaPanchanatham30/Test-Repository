@IsTest
public class TestContactBuilder extends TestSObjectBuilder {
  // keeps count of Instances to allow differentiating objects built;
  // e.g. 'Test Account 1', 'Test Account 2'
  // specifically, increments when build() is called.
  static Integer iteration = 0;

  public TestContactBuilder() {
    setSObjectAndDefaultRecordType('Contact', 'Member');
    retrieveRecordtypes();

    this.values.put('builderId', iteration + 1);
    addDefaultFieldsToValuesMap();
  }

  private TestContactBuilder(TestContactBuilder oldBuilder) {
    this.values = oldBuilder.values;
    this.SOBJECT_TYPE = oldBuilder.SOBJECT_TYPE;
    this.DEFAULT_SOBJECT_RECORD_TYPE = oldBuilder.DEFAULT_SOBJECT_RECORD_TYPE;
  }

  protected override TestSObjectBuilder cloneBuilder() {
    TestContactBuilder newBuilder = new TestContactBuilder(this);

    Integer newBuilderId = (Integer) newBuilder.values.get('builderId');
    newBuilder.values.put('builderId', newBuilderId + 1);

    return newBuilder;
  }

  // default values that apply to all instances across all tests
  protected override void addDefaultFieldsToValuesMap() {
    this.withRecordTypeId(getDefaultRecordTypeId())
      .withFirstName('Test')
      .withLastName('Contact ' + values.get('builderId'))
      .withBirthDate('2000-01-1')
      .withDateOfHire('2020-01-01')
      .withEarnings(100000)
      .withEarningsPeriod('Yearly')
      .withOverPayment(false);
  }

  // candidate for abstract class -- using Type.forName() ??
  protected override void iterate() {
    TestContactBuilder.iteration += 1;
  }

  // setters
  public TestContactBuilder withRecordTypeId(Id rtId) {
    values.put('RecordTypeId', rtId);
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withRecordTypeName(String rtName) {
    values.put('RecordTypeId', getRecordTypeIdByName(rtName));
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withFirstName(String firstName) {
    values.put('FirstName', firstName);
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withLastName(String lastName) {
    values.put('LastName', lastName);
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withBirthDate(Date birthDate) {
    values.put('BirthDate', birthDate);
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withBirthDate(String birthDate) {
    values.put('BirthDate', Date.valueOf(birthDate));
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withDateOfHire(Date dateOfHire) {
    values.put('cvab__DateOfHire__c', dateOfHire);
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withDateOfHire(String dateOfHire) {
    values.put('cvab__DateOfHire__c', Date.valueOf(dateOfHire));
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withEarnings(Integer earnings) {
    values.put('cvab__Earnings__c', earnings);
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withEarningsPeriod(String earningsPeriod) {
    values.put('cvab__EarningsPeriod__c', earningsPeriod);
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withAccountId(Id accountId) {
    values.put('AccountId', accountId);
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withGroupId(Id groupId) {
    values.put('Group__c', groupId);
    return (TestContactBuilder) cloneBuilder();
  }

  public TestContactBuilder withOverpayment(Boolean hasOverpayment) {
    values.put('HasOverPayment__c', hasOverpayment);
    return (TestContactBuilder) cloneBuilder();
  }
}