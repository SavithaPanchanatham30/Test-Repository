public with sharing class RecalculatePaymentTriggerHandler extends TriggerHandler {
  private List<RecalculatePayments__e> newList;
  private RecalculatePaymentTriggerHelper helper;
  @TestVisible
  public List<String> results;
  @TestVisible
  public List<cve__Payment__c> consolidatedPayments;
  private EventPublisher event;
  public RecalculatePaymentTriggerHandler() {
    this(
      RecalculatePaymentTriggerHelper.getHelperInstance(),
      Trigger.New,
      EventPublisher.getInstance()
    );
  }

  @TestVisible
  private RecalculatePaymentTriggerHandler(
    RecalculatePaymentTriggerHelper helper,
    List<RecalculatePayments__e> newList,
    EventPublisher event
  ) {
    this.helper = helper;
    this.newList = newList;
    this.event = event;
  }

  public override void afterInsert() {
    List<Id> paySpecIds = new List<Id>();

    paySpecIds = helper.getPaymentSpecIds(newList);

    // protect against infinite loop
    TriggerHandler.bypass('AdditionalIncomeTriggerHandler');
    // WARNING:  includes multiple DML operations + many soql queries per payment spec
    results = helper.calculatePaymentsByPaymentSpecIds(paySpecIds);
    TriggerHandler.clearBypass('AdditionalIncomeTriggerHandler');
    System.debug(
      [
        SELECT Id
        FROM cve__Payment__c
        WHERE cve__PaymentSpecification__c IN :paySpecIds
      ]
    );

    List<Id> expressPaySpecIds = helper.getExpressPayClaims(paySpecIds);
    if (expressPaySpecIds.size() > 0) {
      List<cve__Payment__c> payments = helper.approvePaymentsByPaymentSpecIds(
        expressPaySpecIds
      );
      handleDmlUpdate(payments);
      List<Id> paymentSpecWithApprovedPayment = helper.filterPaymentSpecs(
        expressPaySpecIds
      );
      System.debug(
        [
          SELECT Id
          FROM cve__Payment__c
          WHERE cve__PaymentSpecification__c IN :expressPaySpecIds
        ]
      );
      System.debug(
        [
          SELECT Id
          FROM cve__Payment__c
          WHERE cve__PaymentSpecification__c IN :paymentSpecWithApprovedPayment
        ]
      );
      // includes dml to create a new payment, update existing payments, and insert paymentassociations
      if (
        paymentSpecWithApprovedPayment != null &&
        paymentSpecWithApprovedPayment.size() > 0
      ) {
        consolidatedPayments = helper.consolidatePaymentsByPaymentSpecIds(
          paymentSpecWithApprovedPayment
        );
      }
    }

    List<cve__BenefitClaimed__c> bcToBeUpdated = helper.updateBenefitClaimed(
      newList
    );
    if (bcToBeUpdated != null && bcToBeUpdated.size() > 0) {
      handleDmlUpdate(bcToBeUpdated);
    }
    List<RecoupOverpayment__e> eventList = helper.generateOverpaymentEvents(
      newList
    );
    publishEvents(eventList);

    List<DeleteZeroAdjustments__e> deleteEvent = helper.generateDeleteAdjustmentEvent(
      newList
    );
    publishEvents(deleteEvent);
  }

  public void handleDmlUpdate(List<SObject> sobjs) {
    List<Database.SaveResult> srs = Database.update(sobjs, true);
    handleErrors(srs);
  }

  public void publishEvents(List<SObject> events) {
    if (events.size() == 0) {
      return;
    }
    List<Database.SaveResult> result = event.publish(events);
    handleErrors(result);
  }

  public void handleErrors(List<Database.SaveResult> result) {
    for (Database.SaveResult sr : result) {
      if (!sr.isSuccess()) {
        String s = '';
        for (Database.Error err : sr.getErrors()) {
          s +=
            'Error returned : ' +
            err.getStatusCode() +
            ' - ' +
            err.getMessage();
        }
        throw new CustomException(s);
      }
    }
  }

  public class CustomException extends Exception {
  }
}