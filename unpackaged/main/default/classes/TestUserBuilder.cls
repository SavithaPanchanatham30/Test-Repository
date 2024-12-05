@IsTest
public class TestUserBuilder extends TestSObjectBuilder {
  // keeps count of Instances to allow differentiating objects built;
  // e.g. 'Test Account 1', 'Test Account 2'
  // specifically, increments when build() is called.
  static Integer iteration = 0;

  public TestUserBuilder() {
    setSObjectAndDefaultRecordType('User', null);

    this.values.put('builderId', iteration + 1);
    addDefaultFieldsToValuesMap();
  }

  private TestUserBuilder(TestUserBuilder oldBuilder) {
    this.values = oldBuilder.values;
    this.SOBJECT_TYPE = oldBuilder.SOBJECT_TYPE;
    this.DEFAULT_SOBJECT_RECORD_TYPE = oldBuilder.DEFAULT_SOBJECT_RECORD_TYPE;
  }

  // candidate for abstract class (??)... or candidate for required method?
  protected override TestSObjectBuilder cloneBuilder() {
    TestUserBuilder newBuilder = new TestUserBuilder(this);

    Integer newBuilderId = (Integer) newBuilder.values.get('builderId');
    newBuilder.values.put('builderId', newBuilderId + 1);
    return newBuilder;
  }

  // default values that apply to all instances across all tests
  protected override void addDefaultFieldsToValuesMap() {
    this.copyRunningUser();
  }

  // candidate for abstract class -- using Type.forName() ??
  protected override void iterate() {
    TestUserBuilder.iteration += 1;
  }

  // setters
  public TestUserBuilder copyRunningUser() {
    User u = [
      SELECT
        LastName,
        FirstName,
        Alias,
        Email,
        Username,
        ProfileId,
        TimeZoneSidKey,
        LanguageLocaleKey,
        EmailEncodingKey,
        LocaleSidKey
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];
    values.put('LastName', u.LastName);
    values.put('FirstName', u.FirstName);
    values.put('Alias', 'tus' + (Math.roundToLong(Math.random() * 100)));
    values.put('Email', 'testuser@example.com');
    values.put(
      'Username',
      u.Username + String.valueOf(Math.roundToLong(Math.random() * 100000))
    );
    values.put('ProfileId', u.ProfileId);
    values.put('TimeZoneSidKey', u.TimeZoneSidKey);
    values.put('LanguageLocaleKey', u.LanguageLocaleKey);
    values.put('EmailEncodingKey', u.EmailEncodingKey);
    values.put('LocaleSidKey', u.LocaleSidKey);
    values.put('AbsenceClaimsLOARole__c', 'Claims Director');
    values.put('DisabilityClaimsLOARole__c', 'Claims Director');
    values.put('SupplementalClaimsLOARole__c', 'Claims Director');
    return (TestUserBuilder) cloneBuilder();
  }

  public TestUserBuilder withProfileName(String profileName) {
    Id profileId = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1]
    .Id;
    values.put('ProfileId', profileId);
    return (TestUserBuilder) cloneBuilder();
  }

  public TestUserBuilder withLastName(String lastName) {
    values.put('LastName', lastName);
    return (TestUserBuilder) cloneBuilder();
  }

  public TestUserBuilder withAbsenceLOARole(String role) {
    values.put('AbsenceClaimsLOARole__c', role);
    return (TestUserBuilder) cloneBuilder();
  }

  public TestUserBuilder withDisabilityLOARole(String role) {
    values.put('DisabilityClaimsLOARole__c', role);
    return (TestUserBuilder) cloneBuilder();
  }

  public TestUserBuilder withSupplementalLOARole(String role) {
    values.put('SupplementalClaimsLOARole__c', role);
    return (TestUserBuilder) cloneBuilder();
  }
}