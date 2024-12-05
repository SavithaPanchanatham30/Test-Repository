@isTest
private class PaymentSpecificationFlowTest {
  @TestSetup
  static void testSetup() {
    cve__Claim__c cveClaim = new cve__Claim__c();
    insert cveClaim;
    cvab__Claim__c cvabClaim = new cvab__Claim__c();
    insert cvabClaim;
  }

  @isTest
  static void adding_paymentspec_to_disabilityonly_claim_updates_addtlincomepaymentspec() {
    cve__Claim__c disabilityClaim = queryDisabilityClaim();

    Test.startTest();
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cve__Claim__c = disabilityClaim.id
    );
    insert ps;

    disabilityClaim = queryDisabilityClaim();
    Test.stopTest();

    Assert.areEqual(
      ps.id,
      disabilityClaim.AdditionalIncomePaymentSpecification__c,
      'Did not find expected Payment Spec Id for Disability Claim\'s AdditionalIncomePaymentSpecification__c'
    );
  }

  @isTest
  static void adding_paymentspec_to_absenceonly_claim_updates_addtlincomepaymentspec() {
    cvab__Claim__c absenceClaim = queryAbsenceClaim();

    Test.startTest();
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = absenceClaim.id
    );
    insert ps;

    absenceClaim = queryAbsenceClaim();
    Test.stopTest();

    Assert.areEqual(
      ps.id,
      absenceClaim.AdditionalIncomePaymentSpecification__c,
      'Did not find expected Payment Spec Id for Absence Claim\'s AdditionalIncomePaymentSpecification__c'
    );
  }

  @isTest
  static void adding_paymentspec_to_cveclaim_in_integrated_claim_updates_both() {
    cvab__Claim__c absenceClaim = queryAbsenceClaim();
    cve__Claim__c disabilityClaim = queryDisabilityClaim();

    disabilityClaim.cvint__AbsenceClaim__c = absenceClaim.Id;
    update disabilityClaim;

    absenceClaim.cvint__DisabilityClaim__c = disabilityClaim.Id;
    update absenceClaim;

    Test.startTest();

    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cve__Claim__c = disabilityClaim.Id
    );
    insert ps;

    disabilityClaim = queryDisabilityClaim();
    absenceClaim = queryAbsenceClaim();

    Test.stopTest();

    Assert.areEqual(
      ps.Id,
      disabilityClaim.AdditionalIncomePaymentSpecification__c,
      'Did not find expected Payment Spec Id for Disability Claim\'s AdditionalIncomePaymentSpecification__c'
    );

    Assert.areEqual(
      ps.Id,
      absenceClaim.AdditionalIncomePaymentSpecification__c,
      'Did not find expected Payment Spec Id for Absence Claim\'s AdditionalIncomePaymentSpecification__c'
    );
  }

  @isTest
  static void adding_paymentspec_to_absence_in_integrated_claim_updates_neither() {
    cvab__Claim__c absenceClaim = queryAbsenceClaim();
    cve__Claim__c disabilityClaim = queryDisabilityClaim();

    disabilityClaim.cvint__AbsenceClaim__c = absenceClaim.Id;
    update disabilityClaim;

    absenceClaim.cvint__DisabilityClaim__c = disabilityClaim.Id;
    update absenceClaim;

    cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
      cve__Claim__c = disabilityClaim.Id
    );
    insert ps1;

    Test.startTest();

    cve__PaymentSpecification__c ps2 = new cve__PaymentSpecification__c(
      cvint__AbsenceClaim__c = absenceClaim.Id
    );
    insert ps2;

    disabilityClaim = queryDisabilityClaim();
    absenceClaim = queryAbsenceClaim();

    Test.stopTest();

    Assert.areEqual(
      ps1.Id,
      disabilityClaim.AdditionalIncomePaymentSpecification__c,
      'Did not find expected Payment Spec Id for Disability Claim\'s AdditionalIncomePaymentSpecification__c'
    );

    Assert.areEqual(
      ps1.Id,
      absenceClaim.AdditionalIncomePaymentSpecification__c,
      'Did not find expected Payment Spec Id for Absence Claim\'s AdditionalIncomePaymentSpecification__c'
    );
  }

  static cve__Claim__c queryDisabilityClaim() {
    return [
      SELECT Id, AdditionalIncomePaymentSpecification__c
      FROM cve__Claim__c
      LIMIT 1
    ];
  }

  static cvab__Claim__c queryAbsenceClaim() {
    return [
      SELECT Id, AdditionalIncomePaymentSpecification__c
      FROM cvab__Claim__c
      LIMIT 1
    ];
  }
}