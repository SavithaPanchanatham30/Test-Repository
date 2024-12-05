public with sharing class HandlePaymentApprovalHelper {
  private Map<String, PaymentApprovalLimit__mdt> approvalLimits;
  private User currentUser;
  private Map<String, Id> supplementalRecordTypeIds;
  private Map<String, Id> queueIds;
  private Map<Id, cve__Payment__c> newMap;
  private Map<Id, cve__Payment__c> oldMap;
  private HandleApprovalProcessAssistant assitant;

  public HandlePaymentApprovalHelper(
    Map<Id, cve__Payment__c> newMap,
    Map<Id, cve__Payment__c> oldMap
  ) {
    this.assitant = new HandleApprovalProcessAssistant();
    this.approvalLimits = assitant.getApprovalLimits();
    this.currentUser = assitant.getCurrentUser();
    this.supplementalRecordTypeIds = assitant.getSupplementalRecordTypeIds();
    this.queueIds = assitant.getQueueIds();
    this.newMap = newMap;
    this.oldMap = oldMap;
  }

  public List<Approval.ProcessSubmitRequest> validatePaymentApproval() {
    Map<Id, cve__PaymentSpecification__c> paymentSpecMap = assitant.getPaymentSpecs(
      this.newMap
    );
    Map<String, User> userInPaymentSpec = getUsersInPaymentSpec(
      paymentSpecMap.values()
    );
    List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
    for (cve__PaymentSpecification__c ps : paymentSpecMap.values()) {
      User validationUser = determineTheUser(ps, userInPaymentSpec);
      Approval.ProcessSubmitRequest req = checkPayments(ps, validationUser);
      if (req != null) {
        requests.add(req);
      }
    }
    return requests;
  }

  private Boolean lookForCalculatedPayments(Id paymentSpecId) {
    Id typeID = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Calculated')
      .getRecordTypeId();

    for (cve__Payment__c pay : newMap.values()) {
      if (
        pay.RecordTypeId == typeID &&
        pay.cve__PaymentSpecification__c == paymentSpecId
      ) {
        return true;
      }
    }
    return false;
  }

  private Boolean lookForAdhocPayments(Id paymentSpecId) {
    Id typeID = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Calculated')
      .getRecordTypeId();

    for (cve__Payment__c pay : newMap.values()) {
      if (
        pay.RecordTypeId != typeID &&
        pay.cve__PaymentSpecification__c == paymentSpecId
      ) {
        return true;
      }
    }
    return false;
  }

  private Boolean validateCurrentUser() {
    if (this.currentUser.UserType == 'Standard') {
      return true;
    } else {
      return false;
    }
  }

  private Map<String, User> getUsersInPaymentSpec(
    List<cve__PaymentSpecification__c> paymentSpecList
  ) {
    Set<String> userNames = new Set<String>();
    for (cve__PaymentSpecification__c ps : paymentSpecList) {
      userNames.add(ps.RunApprovalAs__c);
    }

    List<User> userList = [
      SELECT
        id,
        name,
        email,
        UserType,
        UserName,
        AbsenceClaimsLOARole__c,
        DisabilityClaimsLOARole__c,
        SupplementalClaimsLOARole__c
      FROM User
      WHERE UserName IN :userNames
    ];

    Map<String, User> result = new Map<String, User>();

    for (User u : userList) {
      result.put(u.UserName, u);
    }
    return result;
  }

  private Id determineQueueId(cve__PaymentSpecification__c ps, String role) {
    if (role == 'Claims Director' || role == 'Claims Sr Director') {
      return queueIds.get('Claims Director');
    } else if (role == 'VP Claims') {
      return queueIds.get('VP Claims');
    } else if (ps.cvint__AbsenceClaim__c != null) {
      return queueIds.get('Absence Review');
    } else if (
      ps.cve__Claim__c != null &&
      !supplementalRecordTypeIds.values().contains(ps.RecordTypeId)
    ) {
      return queueIds.get('Group Disability Review');
    } else {
      return queueIds.get('Supplemental Claims Review');
    }
  }

  private User determineTheUser(
    cve__PaymentSpecification__c ps,
    Map<String, User> userInPaymentSpec
  ) {
    User validationUser = null;

    if (validateCurrentUser()) {
      validationUser = this.currentUser;
    } else if (userInPaymentSpec.containsKey(ps.RunApprovalAs__c)) {
      validationUser = userInPaymentSpec.get(ps.RunApprovalAs__c);
    } else {
      throw new CustomException('User to be used not found');
    }
    return validationUser;
  }

  private Approval.ProcessSubmitRequest checkPayments(
    cve__PaymentSpecification__c ps,
    User validationUser
  ) {
    Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
    approvalRequest.setComments('Payment Specification Submitted for approval');
    approvalRequest.setObjectId(ps.Id);
    approvalRequest.setProcessDefinitionNameOrId('Payment_Approval_Process');
    approvalRequest.setSkipEntryCriteria(true);
    if (!assitant.checkForPartialApprovals(ps, this.newMap)) {
      assitant.resetTheStatus(ps, this.oldMap, this.newMap);
    } else if (ps.cvint__AbsenceClaim__c != null) {
      return checkCvabPayments(ps, validationUser, approvalRequest);
    } else if (ps.cve__Claim__c != null) {
      return checkCvePayments(ps, validationUser, approvalRequest);
    }
    return null;
  }

  private Approval.ProcessSubmitRequest checkCvabPayments(
    cve__PaymentSpecification__c ps,
    User validationUser,
    Approval.ProcessSubmitRequest approvalRequest
  ) {
    if (
      lookForCalculatedPayments(ps.id) &&
      checkApprovalOfCvab(ps, validationUser.AbsenceClaimsLOARole__c)
    ) {
      assitant.updatePaymentStatus(ps.id, this.newMap);
      Id queueId = determineQueueId(ps, validationUser.AbsenceClaimsLOARole__c);
      approvalRequest.setNextApproverIds(new List<Id>{ queueId });
      return approvalRequest;
    }
    return null;
  }

  private Boolean checkApprovalOfCvab(
    cve__PaymentSpecification__c ps,
    String rule
  ) {
    return (rule == null ||
    !assitant.checkPaymentAmount(
      ps,
      approvalLimits.get(rule).AbsenceReleaseLimit__c
    ));
  }

  private Boolean checkApprovalOfDisability(
    cve__PaymentSpecification__c ps,
    String role
  ) {
    if (role == null) {
      return true;
    }
    PaymentApprovalLimit__mdt cveLimit = approvalLimits.get(role);
    return !assitant.checkPaymentPeriod(
        ps,
        cveLimit.DisabilityReleaseLimitDays__c
      ) &&
      !assitant.checkPaymentAmount(
        ps,
        cveLimit.DisabilityRecurringPaymentsLimit__c
      );
  }

  private Boolean checkApprovalOfAccident(
    cve__PaymentSpecification__c ps,
    String role
  ) {
    if (role == null) {
      return true;
    }
    PaymentApprovalLimit__mdt cveLimit = approvalLimits.get(role);
    return !assitant.checkPaymentAmount(
      ps,
      cveLimit.SupplementalReleaseLimitsAccident__c
    );
  }

  private Boolean checkApprovalOfCritical(
    cve__PaymentSpecification__c ps,
    String role
  ) {
    if (role == null) {
      return true;
    }
    PaymentApprovalLimit__mdt cveLimit = approvalLimits.get(role);
    return !assitant.checkPaymentAmount(
      ps,
      cveLimit.SupplementalReleaseLimitsCritical__c
    );
  }

  private Approval.ProcessSubmitRequest checkCvePayments(
    cve__PaymentSpecification__c ps,
    User validationUser,
    Approval.ProcessSubmitRequest approvalRequest
  ) {
    String supString = assitant.checkIfSupplemental(
      ps,
      supplementalRecordTypeIds.values().contains(ps.RecordTypeId)
    );
    if (
      lookForCalculatedPayments(ps.id) &&
      supString == 'Others' &&
      checkApprovalOfDisability(ps, validationUser.DisabilityClaimsLOARole__c)
    ) {
      assitant.updatePaymentStatus(ps.id, this.newMap);
      Id queueId = determineQueueId(
        ps,
        validationUser.DisabilityClaimsLOARole__c
      );
      approvalRequest.setNextApproverIds(new List<Id>{ queueId });
      return approvalRequest;
    } else if (
      lookForCalculatedPayments(ps.id) &&
      supString == 'Accident' &&
      checkApprovalOfAccident(ps, validationUser.SupplementalClaimsLOARole__c)
    ) {
      assitant.updatePaymentStatus(ps.id, this.newMap);
      Id queueId = determineQueueId(
        ps,
        validationUser.SupplementalClaimsLOARole__c
      );
      approvalRequest.setNextApproverIds(new List<Id>{ queueId });
      return approvalRequest;
    } else if (
      lookForCalculatedPayments(ps.id) &&
      supString == 'Critical' &&
      checkApprovalOfCritical(ps, validationUser.SupplementalClaimsLOARole__c)
    ) {
      assitant.updatePaymentStatus(ps.id, this.newMap);
      Id queueId = determineQueueId(
        ps,
        validationUser.SupplementalClaimsLOARole__c
      );
      approvalRequest.setNextApproverIds(new List<Id>{ queueId });
      return approvalRequest;
    } else if (
      lookForAdhocPayments(ps.id) &&
      !assitant.checkAdhocPayments(
        ps,
        approvalLimits.get(validationUser.AbsenceClaimsLOARole__c)
          .DisabilityAdHocPaymentLimit__c
      )
    ) {
      assitant.updatePaymentStatus(ps.id, this.newMap);
      Id queueId = determineQueueId(ps, validationUser.AbsenceClaimsLOARole__c);
      approvalRequest.setNextApproverIds(new List<Id>{ queueId });
      return approvalRequest;
    }
    return null;
  }

  public class CustomException extends Exception {
  }
}