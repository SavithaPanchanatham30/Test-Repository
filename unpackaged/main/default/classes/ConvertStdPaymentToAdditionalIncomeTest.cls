@isTest
public class ConvertStdPaymentToAdditionalIncomeTest {
  @TestSetup
  static void makeData() {
    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;

    cve__Claim__c cveClaim = new cve__Claim__c();
    insert cveClaim;

    cve__PaymentSpecification__c paymentSpec = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = cvabClaim.Id
    );
    insert paymentSpec;

    cveClaim.HasStateIncomeOffset__c = false;
    update cveClaim;

    cvabClaim.cvint__DisabilityClaim__c = cveClaim.Id;
    cvabClaim.HasOffsetLanguage__c = true;
    update cvabClaim;
  }

  @IsTest
  static void cve_paymentspec_does_not_convert_to_income_if_incomplete() {
    cve__Claim__c cveClaim = queryCveClaim();
    cve__PaymentSpecification__c paymentSpec = new cve__PaymentSpecification__c(
      cve__Start__c = Date.valueOf('2024-01-01'),
      cve__Through__c = Date.valueOf('2024-02-01'),
      cve__Amount__c = 1000,
      cve__Claim__c = cveClaim.Id
    );

    Test.startTest();

    insert paymentSpec;

    Test.stopTest();

    List<AdditionalIncome__c> additionalIncomes = queryAdditionalIncomes();

    Assert.areEqual(
      0,
      additionalIncomes.size(),
      'Found unexpected Additional Income records after inserting incomplete Payment Spec'
    );
  }

  @IsTest
  static void cve_paymentspec_does_not_convert_to_income_if_not_idam_claim() {
    cve__Claim__c cveClaim = new cve__Claim__c();
    insert cveClaim;

    cve__PaymentSpecification__c paymentSpec = new cve__PaymentSpecification__c(
      cve__Start__c = Date.valueOf('2024-01-01'),
      cve__Through__c = Date.valueOf('2024-02-01'),
      cve__Amount__c = 1000,
      cve__Claim__c = cveClaim.Id,
      cve__Period__c = 'Weekly'
    );

    Test.startTest();

    insert paymentSpec;

    Test.stopTest();

    List<AdditionalIncome__c> additionalIncomes = queryAdditionalIncomes();

    Assert.areEqual(
      0,
      additionalIncomes.size(),
      'Found unexpected Additional Income records after inserting Payment Spec on non-IDAM claim'
    );
  }

  @IsTest
  static void paymentspec_does_not_convert_to_income_if_not_disability_claim() {
    cvab__Claim__c cvabClaim = queryCvabClaim();
    cvabClaim.cvint__DisabilityClaim__c = queryCveClaim().Id;
    cve__PaymentSpecification__c paymentSpec = new cve__PaymentSpecification__c(
      cve__Start__c = Date.valueOf('2024-01-01'),
      cve__Through__c = Date.valueOf('2024-02-01'),
      cve__Amount__c = 1000,
      cvint__AbsenceClaim__c = cvabClaim.Id,
      cve__Period__c = 'Weekly'
    );

    Test.startTest();

    insert paymentSpec;

    Test.stopTest();

    List<AdditionalIncome__c> additionalIncomes = queryAdditionalIncomes();

    Assert.areEqual(
      0,
      additionalIncomes.size(),
      'Found unexpected Additional Income records after inserting Payment Spec on cve Claim of IDAM claim'
    );
  }

  @IsTest
  static void adding_paymentspec_to_cve_side_of_idam_claim_generates_additionalincome_on_cvabclaim() {
    cve__Claim__c cveClaim = queryCveClaim();
    cve__PaymentSpecification__c paymentSpec = new cve__PaymentSpecification__c(
      cve__Start__c = Date.valueOf('2024-01-01'),
      cve__Through__c = Date.valueOf('2024-02-01'),
      cve__Amount__c = 1000,
      cve__Claim__c = cveClaim.Id,
      cve__Period__c = 'Weekly'
    );

    Test.startTest();
    insert paymentSpec;
    Test.stopTest();

    cvab__Claim__c cvabClaim = queryCvabClaim();
    List<AdditionalIncome__c> actualAdditionalIncomes = queryAdditionalIncomes();
    AdditionalIncome__c expectedAdditionalIncome = new AdditionalIncome__c(
      Name = 'STD Income: 2024-01-01 - 2024-02-01',
      Amount__c = 1000.00,
      EndDate__c = Date.valueOf('2024-02-01'),
      IncomeType__c = 'STD Income',
      PaymentSpecification__c = cvabClaim.AdditionalIncomePaymentSpecification__c,
      Period__c = 'Weekly',
      StartDate__c = Date.valueOf('2024-01-01'),
      STDClaim__c = cveClaim.Id
    );

    Assert.areEqual(
      1,
      actualAdditionalIncomes.size(),
      'Found unexpected number of AdditionalIncome records'
    );
    assertSObjectEquality(
      getAdditionalIncomeFields(),
      expectedAdditionalIncome,
      actualAdditionalIncomes[0],
      'The created AdditionalIncome record does not match the expected record'
    );
  }

  @IsTest
  static void cve_paymentspec_does_not_convert_to_income_if_cvab_hasoffset_equals_fals() {
    cve__Claim__c cveClaim = queryCveClaim();
    cve__PaymentSpecification__c paymentSpec = new cve__PaymentSpecification__c(
      cve__Start__c = Date.valueOf('2024-01-01'),
      cve__Through__c = Date.valueOf('2024-02-01'),
      cve__Amount__c = 1000,
      cve__Claim__c = cveClaim.Id,
      cve__Period__c = 'Weekly'
    );

    cvab__Claim__c cvabClaim = queryCvabClaim();
    cvabClaim.HasOffsetLanguage__c = false;
    update cvabClaim;

    Test.startTest();
    insert paymentSpec;
    Test.stopTest();

    List<AdditionalIncome__c> actualAdditionalIncomes = queryAdditionalIncomes();

    Assert.areEqual(
      0,
      actualAdditionalIncomes.size(),
      'Found unexpected number of AdditionalIncome records'
    );
  }

  @IsTest
  static void updating_paymentspec_on_idam_std_claim_does_not_duplicate_additionalincomes() {
    cve__Claim__c cveClaim = queryCveClaim();
    cve__PaymentSpecification__c paymentSpec = new cve__PaymentSpecification__c(
      cve__Start__c = Date.valueOf('2024-01-01'),
      cve__Through__c = Date.valueOf('2024-02-01'),
      cve__Amount__c = 500,
      cve__Claim__c = cveClaim.Id,
      cve__Period__c = 'Weekly'
    );

    insert paymentSpec;

    Test.startTest();

    paymentSpec.cve__Amount__c = 1000;
    update paymentSpec;

    Test.stopTest();

    cvab__Claim__c cvabClaim = queryCvabClaim();
    List<AdditionalIncome__c> actualAdditionalIncomes = queryAdditionalIncomes();
    AdditionalIncome__c expectedAdditionalIncome = new AdditionalIncome__c(
      Name = 'STD Income: 2024-01-01 - 2024-02-01',
      Amount__c = 1000.00,
      EndDate__c = Date.valueOf('2024-02-01'),
      IncomeType__c = 'STD Income',
      PaymentSpecification__c = cvabClaim.AdditionalIncomePaymentSpecification__c,
      Period__c = 'Weekly',
      StartDate__c = Date.valueOf('2024-01-01'),
      STDClaim__c = cveClaim.Id
    );

    Assert.areEqual(
      1,
      actualAdditionalIncomes.size(),
      'Found unexpected number of AdditionalIncome records'
    );
    assertSObjectEquality(
      getAdditionalIncomeFields(),
      expectedAdditionalIncome,
      actualAdditionalIncomes[0],
      'The created AdditionalIncome record does not match the expected record'
    );
  }

  static cvab__Claim__c queryCvabClaim() {
    return [
      SELECT
        Id,
        AdditionalIncomePaymentSpecification__c,
        OwnerId,
        cvint__DisabilityClaim__c
      FROM cvab__Claim__c
      LIMIT 1
    ];
  }

  static cve__Claim__c queryCveClaim() {
    return [
      SELECT Id, AdditionalIncomePaymentSpecification__c, OwnerId
      FROM cve__Claim__c
      LIMIT 1
    ];
  }

  static List<AdditionalIncome__c> queryAdditionalIncomes() {
    return [
      SELECT
        Name,
        Amount__c,
        EndDate__c,
        IncomeType__c,
        PaymentSpecification__c,
        Period__c,
        PFMLClaim__c,
        STDClaim__c,
        StartDate__c
      FROM AdditionalIncome__c
    ];
  }

  static List<String> getAdditionalIncomeFields() {
    return new List<String>{
      'Name',
      'Amount__c',
      'EndDate__c',
      'IncomeType__c',
      'PaymentSpecification__c',
      'Period__c',
      'PFMLClaim__c',
      'STDClaim__c',
      'StartDate__c'
    };
  }

  static void assertSObjectEquality(
    List<String> fields,
    SObject expectedSObj,
    SObject actualSObj,
    String errorMessage
  ) {
    Map<String, Object> expectedValues = expectedSObj.getPopulatedFieldsAsMap();
    Map<String, ObjecT> actualValues = actualSObj.getPopulatedFieldsAsMap();

    expectedValues.keySet().retainAll(fields);
    actualValues.keySet().retainAll(fields);

    Assert.areEqual(expectedValues, actualValues, errorMessage);
  }
}