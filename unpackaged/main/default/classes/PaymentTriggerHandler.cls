public with sharing class PaymentTriggerHandler extends TriggerHandler {
  PaymentTriggerHelper helper;
  HandlerContext contxt;
  @TestVisible
  private List<cve__Payment__c> payments;

  public PaymentTriggerHandler() {
    this(PaymentTriggerHelper.getInstance());
  }

  @TestVisible
  private PaymentTriggerHandler(PaymentTriggerHelper helper) {
    this(
      helper,
      (List<cve__Payment__c>) Trigger.old,
      (List<cve__Payment__c>) Trigger.new,
      (Map<Id, cve__Payment__c>) Trigger.oldMap,
      (Map<Id, cve__Payment__c>) Trigger.newMap
    );
  }

  @TestVisible
  private PaymentTriggerHandler(
    PaymentTriggerHelper helper,
    List<cve__Payment__c> oldPayments,
    List<cve__Payment__c> newPayments,
    Map<Id, cve__Payment__c> oldMap,
    Map<Id, cve__Payment__c> newMap
  ) {
    this.contxt = new HandlerContext(oldPayments, newPayments, oldMap, newMap);
    this.helper = helper.setContext(contxt);
  }

  public override void beforeInsert() {
    payments = helper.populateClaimantLookups();
    payments = helper.updateStatusToSubmittedForApproval();
    helper.updatePayableAndIssueDate();
  }

  public override void beforeUpdate() {
    List<Approval.ProcessSubmitRequest> requests = helper.validateApproval();
    processApprovalRequests(requests);
    helper.updatePayableAndIssueDate();
  }

  public override void afterUpdate() {
    List<cve__Adjustment__c> adjList = helper.lockRecoupOverpaymentAdjustment(
      contxt.newPayments,
      contxt.oldPaymentsMap
    );
    if (adjList != null && adjList.size() > 0) {
      handleUpdate(adjList);
    }

    /*adjList = helper.unlockRecoupOverpaymentAdjustment(contxt.newPayments, contxt.oldPaymentsMap);
        if(adjList != null && adjList.size() > 0){
            handleUpdate(adjList);
        }*/
  }

  private void processApprovalRequests(
    List<Approval.ProcessSubmitRequest> requests
  ) {
    List<Approval.ProcessResult> approvalResults = Approval.process(requests);
    List<Approval.ProcessResult> errors = new List<Approval.ProcessResult>();
    for (Approval.ProcessResult result : approvalResults) {
      if (!result.isSuccess()) {
        errors.add(result);
      }
    }
    handleErrors(errors);
  }

  private void handleErrors(List<Approval.ProcessResult> errors) {
    if (errors.size() > 0) {
      throw new CustomException('Failed to raise a Approval Request');
    }
  }

  public void handleUpdate(List<SObject> sobjectList) {
    try {
      List<Database.SaveResult> results = Database.update(sobjectList, false);
      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          String s = '';
          for (Database.Error err : result.getErrors()) {
            s += 'Error: ' + err.getStatusCode() + ' ' + err.getMessage();
          }
          throw new CustomException(s);
        }
      }
    } catch (Exception e) {
      throw new CustomException(
        'Exception while updating cve Contacts :- ' + e
      );
    }
  }

  public class HandlerContext {
    public List<cve__Payment__c> oldPayments;
    public List<cve__Payment__c> newPayments;
    public Map<Id, cve__Payment__c> oldPaymentsMap;
    public Map<Id, cve__Payment__c> newPaymentsMap;

    public HandlerContext(
      List<cve__Payment__c> oldPayments,
      List<cve__Payment__c> newPayments,
      Map<Id, cve__Payment__c> oldPaymentsMap,
      Map<Id, cve__Payment__c> newPaymentsMap
    ) {
      this.oldPayments = oldPayments;
      this.newPayments = newPayments;
      this.oldPaymentsMap = oldPaymentsMap;
      this.newPaymentsMap = newPaymentsMap;
    }
  }
  public class CustomException extends Exception {
  }
}