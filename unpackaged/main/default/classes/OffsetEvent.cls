public class OffsetEvent {
  public cve__PaymentSpecification__c paymentSpec;
  public cve__Claim__c cveClaim;
  public cvab__Claim__c cvabClaim;
  public List<AdditionalIncome__c> additionalIncomeList;

  public OffsetEvent(
    cve__PaymentSpecification__c paymentSpec,
    cve__Claim__c cveClaim,
    cvab__Claim__c cvabClaim,
    List<AdditionalIncome__c> additionalIncomeList
  ) {
    this.paymentSpec = paymentSpec;
    this.cveClaim = cveClaim;
    this.cvabClaim = cvabClaim;
    this.additionalIncomeList = additionalIncomeList;
  }
}