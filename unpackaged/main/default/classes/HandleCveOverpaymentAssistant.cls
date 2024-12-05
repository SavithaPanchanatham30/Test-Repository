public with sharing class HandleCveOverpaymentAssistant {
  List<cve__PaymentSpecification__c> paymentSpecs;

  public HandleCveOverpaymentAssistant(
    List<cve__PaymentSpecification__c> psList
  ) {
    this.paymentSpecs = psList;
  }

  public Map<Id, List<cve__PaymentSpecification__c>> getPriorPaymentSpecs() {
    Map<Id, List<cve__PaymentSpecification__c>> result = new Map<Id, List<cve__PaymentSpecification__c>>();
    if (paymentSpecs == null || paymentSpecs.size() == 0) {
      return result;
    }
    Map<Id, cve__Claim__c> currentClaim = getCurrentClaims(paymentSpecs);
    Map<Id, List<cve__PaymentSpecification__c>> pastPs = getPastPs(
      currentClaim
    );
    for (cve__PaymentSpecification__c ps : paymentSpecs) {
      cve__Claim__c curr = currentClaim.get(ps.cve__Claim__c);
      if (pastPs.containsKey(curr.cve__Policy__r.cve__Product__c)) {
        result.put(ps.id, pastPs.get(curr.cve__Policy__r.cve__Product__c));
      } else {
        result.put(ps.id, new List<cve__PaymentSpecification__c>());
      }
    }
    return result;
  }

  public Map<Id, cve__Claim__c> getCurrentClaims(
    List<cve__PaymentSpecification__c> psList
  ) {
    Set<Id> claimIds = new Set<Id>();
    for (cve__PaymentSpecification__c ps : psList) {
      claimIds.add(ps.cve__Claim__c);
    }

    return new Map<Id, cve__Claim__c>(
      [
        SELECT id, cve__Policy__r.cve__Product__c, cve__ClaimantInsured__c
        FROM cve__Claim__c
        WHERE id IN :claimIds
        WITH SECURITY_ENFORCED
      ]
    );
  }

  public Map<Id, List<cve__PaymentSpecification__c>> getPastPs(
    Map<Id, cve__Claim__c> claims
  ) {
    Set<Id> productIds = new Set<Id>();
    Set<Id> contactIds = new Set<Id>();

    for (cve__Claim__c cveClaim : claims.values()) {
      productIds.add(cveClaim.cve__Policy__r.cve__Product__c);
      contactIds.add(cveClaim.cve__ClaimantInsured__c);
    }
    List<cve__Claim__c> previousClaims = [
      SELECT
        id,
        cve__Policy__r.cve__Product__c,
        (
          SELECT
            id,
            cve__OverpaymentBeforeTax__c,
            cve__Claim__r.cve__ClaimantInsured__c
          FROM cve__PaymentSpecifications__r
          WHERE cve__OverpaymentBeforeTax__c > 0
        )
      FROM cve__Claim__c
      WHERE
        cve__Policy__r.cve__Product__c IN :productIds
        AND cve__ClaimantInsured__c IN :contactIds
      WITH SECURITY_ENFORCED
    ];
    Map<Id, List<cve__PaymentSpecification__c>> result = new Map<Id, List<cve__PaymentSpecification__c>>();
    for (cve__Claim__c claim : previousClaims) {
      if (result.containsKey(claim.cve__Policy__r.cve__Product__c)) {
        List<cve__PaymentSpecification__c> value = result.get(
          claim.cve__Policy__r.cve__Product__c
        );
        value.addAll(claim.cve__PaymentSpecifications__r);
        result.put(claim.cve__Policy__r.cve__Product__c, value);
      } else {
        result.put(
          claim.cve__Policy__r.cve__Product__c,
          claim.cve__PaymentSpecifications__r
        );
      }
    }
    return result;
  }
}