public with sharing class ClaimLeaveTriggerHelper {
  private static final String APPROVED = 'Approved';
  private static final String DENIED = 'Denied';
  private static final String PENDING = 'Pending';
  private static final String WAITING = 'Waiting';

  private ClaimLeaveTriggerHandler.ContextVariables contxtVars;
  private static ClaimLeaveTriggerHelper instance = null;

  public static ClaimLeaveTriggerHelper getInstance() {
    if (instance == null) {
      instance = new ClaimLeaveTriggerHelper();
    }
    return instance;
  }

  public ClaimLeaveTriggerHelper withContextVars(
    ClaimLeaveTriggerHandler.ContextVariables contxtVars
  ) {
    this.contxtVars = contxtVars;
    return this;
  }

  public List<cve__PaymentSpecification__c> updateStatusOnPaymentSpecs(
    List<cvab__ClaimLeave__c> newList,
    Map<Id, cvab__ClaimLeave__c> oldMap
  ) {
    Set<Id> clList = new Set<Id>();
    for (cvab__ClaimLeave__c cl : newList) {
      cvab__ClaimLeave__c oldCl = oldMap.get(cl.id);
      if (cl.cvab__Status__c != oldCl.cvab__Status__c) {
        clList.add(cl.id);
      }
    }

    List<cve__PaymentSpecification__c> psList = [
      SELECT
        id,
        ClaimLeaveStatus__c,
        cvint__AbsenceClaimLeave__r.cvab__Status__c
      FROM cve__PaymentSpecification__c
      WHERE cvint__AbsenceClaimLeave__c IN :clList
    ];

    for (cve__PaymentSpecification__c ps : psList) {
      ps.ClaimLeaveStatus__c = ps.cvint__AbsenceClaimLeave__r.cvab__Status__c;
    }

    return psList;
  }

  public List<cvab__Claim__c> cvabClaimTATcalculation(
    List<cvab__ClaimLeave__c> newList,
    Map<Id, cvab__ClaimLeave__c> oldMap
  ) {
    List<cvab__Claim__c> cvabClaimsToUpdate = new List<cvab__Claim__c>();
    try {
      for (cvab__ClaimLeave__c bc : [
        SELECT
          Id,
          cvab__Status__c,
          cvab__Claim__r.StatusChangedDate__c,
          cvab__Claim__r.FinalStatusChangedDate__c,
          cvab__Claim__r.InitialDecisionDate__c,
          cvab__Claim__r.FinalDecisionDate__c
        FROM cvab__ClaimLeave__c
        WHERE Id IN :newList
      ]) {
        if (oldMap.get(bc.Id).cvab__Status__c != bc.cvab__Status__c) {
          cvabClaimsToUpdate = benefitClaimedCveClaimCreation(bc, oldMap);
        }
      }
    } catch (Exception e) {
      throw new CustomException(
        'Exception caught at :: ' + e.getLineNumber() + ' :: ' + e.getMessage()
      );
    }
    return cvabClaimsToUpdate;
  }

  public List<cvab__Claim__c> benefitClaimedCveClaimCreation(
    cvab__ClaimLeave__c bc,
    Map<Id, cvab__ClaimLeave__c> oldMap
  ) {
    Set<String> bcStatusSet = new Set<String>{ APPROVED, DENIED };
    Set<String> absenceStatusSet = new Set<String>{ PENDING, WAITING };
    List<cvab__Claim__c> cvabClaimsList = new List<cvab__Claim__c>();

    Date initialDecisionDate = bc.cvab__Claim__r.InitialDecisionDate__c;
    Date finalDecisionDate = bc.cvab__Claim__r.FinalDecisionDate__c;
    cvab__Claim__c claim = new cvab__Claim__c(Id = bc.cvab__Claim__c);
    claim.InitialDecisionDate__c = (bc.cvab__Claim__r.StatusChangedDate__c ==
      null &&
      !absenceStatusSet.contains(bc.cvab__Status__c) &&
      initialDecisionDate == null)
      ? system.today()
      : initialDecisionDate;
    claim.FinalDecisionDate__c = (bc.cvab__Claim__r.FinalStatusChangedDate__c ==
      null &&
      bcStatusSet.contains(bc.cvab__Status__c) &&
      finalDecisionDate == null)
      ? system.today()
      : finalDecisionDate;
    cvabClaimsList.add(claim);
    return cvabClaimsList;
  }

  public class CustomException extends Exception {
  }
}