public class RecalculatePaymentSpecHelper {
  @TestVisible
  private List<String> result = new List<String>();

  public static RecalculatePaymentSpecHelper getInstance() {
    return new RecalculatePaymentSpecHelper();
  }

  public List<RecalculatePayments__e> recalculatePaymentSpecs(
    List<RecalculatePaymentSpec__e> newList
  ) {
    List<RecalculatePayments__e> eventList = new List<RecalculatePayments__e>();
    Set<Id> paymentSpecIds = new Set<Id>();
    Set<Id> psRecalculationSuccess = new Set<Id>();
    for (RecalculatePaymentSpec__e event : newList) {
      paymentSpecIds.add(event.PaymentSpecificationId__c);
    }

    Map<Id, cve__PaymentSpecification__c> psMap = new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT id, cve__BenefitClaimed__r.ClaimBrainIntegrationStatus__c
        FROM cve__PaymentSpecification__c
        WHERE id IN :paymentSpecIds
      ]
    );

    for (RecalculatePaymentSpec__e event : newList) {
      cve__PaymentSpecification__c ps = psMap.get(
        event.PaymentSpecificationId__c
      );
      if (
        ps.cve__BenefitClaimed__r.ClaimBrainIntegrationStatus__c == null ||
        (ps.cve__BenefitClaimed__r.ClaimBrainIntegrationStatus__c != null &&
        event.ClaimBrainCalculation__c == true)
      ) {
        String returnStatus = cve.PaymentSpecificationActions.calculate(ps.Id);
        if (returnStatus == 'Success') {
          psRecalculationSuccess.add(ps.Id);
          result.add(returnStatus);
        }
      }
    }

    for (RecalculatePaymentSpec__e event : newList) {
      if (
        psRecalculationSuccess.contains(event.PaymentSpecificationId__c) &&
        event.RecalculatePaymentRequired__c
      ) {
        if (event.ClaimBrainCalculation__c) {
          eventList.add(
            new RecalculatePayments__e(
              PaymentSpecificationId__c = event.PaymentSpecificationId__c,
              ClaimBrainCalculation__c = true
            )
          );
        } else {
          eventList.add(
            new RecalculatePayments__e(
              PaymentSpecificationId__c = event.PaymentSpecificationId__c
            )
          );
        }
      }
    }

    return eventList;
  }
}