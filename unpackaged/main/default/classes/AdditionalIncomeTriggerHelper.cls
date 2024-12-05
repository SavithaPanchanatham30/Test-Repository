public class AdditionalIncomeTriggerHelper {
  private static AdditionalIncomeTriggerHelper instance = null;

  public static AdditionalIncomeTriggerHelper getHelperInstance() {
    if (instance == null) {
      instance = new AdditionalIncomeTriggerHelper();
    }

    return instance;
  }

  public List<AdditionalIncomeOffset__e> generatePlatformEvents(
    List<AdditionalIncome__c> incomeList
  ) {
    Set<Id> paymentSpecIds = new Set<id>();
    for (AdditionalIncome__c obj : incomeList) {
      paymentSpecIds.add(obj.PaymentSpecification__c);
    }
    Map<Id, cve__PaymentSpecification__c> paymentSpecificationMap = getAllPaymentSpecification(
      paymentSpecIds
    );

    List<String> stringList = generateJsonFromObjects(paymentSpecificationMap);

    List<AdditionalIncomeOffset__e> events = new List<AdditionalIncomeOffset__e>();
    for (String json : stringList) {
      AdditionalIncomeOffset__e event = new AdditionalIncomeOffset__e();
      event.OffsetIncomeData__c = json;
      events.add(event);
    }

    return events;
  }

  public Map<id, cve__PaymentSpecification__c> getAllPaymentSpecification(
    Set<id> paymentSpecIds
  ) {
    Map<id, cve__PaymentSpecification__c> result = new Map<id, cve__PaymentSpecification__c>(
      [
        SELECT
          Id,
          cvint__AbsenceClaim__c,
          cve__Claim__c,
          cve__Claim__r.cvint__AbsenceClaim__c,
          (
            SELECT
              Id,
              Name,
              Amount__c,
              EndDate__c,
              IncomeType__c,
              PaymentSpecification__c,
              Period__c,
              StartDate__c,
              PFMLClaim__c,
              STDClaim__c
            FROM AdditionalIncomes__r
          )
        FROM cve__PaymentSpecification__c
        WHERE ID IN :paymentSpecIds
      ]
    );
    return result;
  }

  public List<String> generateJsonFromObjects(
    Map<id, cve__PaymentSpecification__c> paymentSpecMap
  ) {
    List<String> result = new List<String>();

    for (Id psId : paymentSpecMap.keySet()) {
      cve__PaymentSpecification__c ps = null;
      cve__Claim__c cveClaim = null;
      cvab__Claim__c cvabClaim = null;
      List<AdditionalIncome__c> incomeList = null;

      ps = paymentSpecMap.get(psId);
      incomeList = ps.AdditionalIncomes__r;
      cveClaim = buildCveClaim(ps);
      cvabClaim = buildCvabClaim(ps);
      result.add(
        JSON.serialize(new OffsetEvent(ps, cveClaim, cvabClaim, incomeList))
      );
    }
    system.debug(result);
    return result;
  }

  private cve__Claim__c buildCveClaim(
    cve__PaymentSpecification__c paymentSpec
  ) {
    cve__Claim__c cveClaim;

    if (paymentSpec.cve__Claim__c != null) {
      cveClaim = new cve__Claim__c(
        Id = paymentSpec.cve__Claim__c,
        cvint__AbsenceClaim__c = paymentSpec.cve__Claim__r
          ?.cvint__AbsenceClaim__c
      );
    }

    return cveClaim;
  }
  private cvab__Claim__c buildCvabClaim(
    cve__PaymentSpecification__c paymentSpec
  ) {
    cvab__Claim__c cvabClaim;

    if (paymentSpec.cvint__AbsenceClaim__c != null) {
      cvabClaim = new cvab__Claim__c(Id = paymentSpec.cvint__AbsenceClaim__c);
    } else if (paymentSpec.cve__Claim__r.cvint__AbsenceClaim__c != null) {
      cvabClaim = new cvab__Claim__c(
        Id = paymentSpec.cve__Claim__r.cvint__AbsenceClaim__c
      );
    }

    return cvabClaim;
  }
}