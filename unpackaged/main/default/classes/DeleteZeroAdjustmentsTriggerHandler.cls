public with sharing class DeleteZeroAdjustmentsTriggerHandler extends TriggerHandler {
  private List<DeleteZeroAdjustments__e> newList;
  private DeleteZeroAdjustmentsTriggerHelper helper;

  public DeleteZeroAdjustmentsTriggerHandler() {
    this(DeleteZeroAdjustmentsTriggerHelper.getInstance(), Trigger.New);
  }

  @TestVisible
  private DeleteZeroAdjustmentsTriggerHandler(
    DeleteZeroAdjustmentsTriggerHelper helper,
    List<DeleteZeroAdjustments__e> eventList
  ) {
    this.helper = helper;
    this.newList = eventList;
  }

  public override void afterInsert() {
    List<cve__UnallocatedPayment__c> upToBeDeleted = helper.getUpayToBeDeleted(
      newList
    );
    if (upToBeDeleted != null && upToBeDeleted.size() > 0) {
      handleDelete(upToBeDeleted);
    }
    List<cve__Adjustment__c> adjToBeDeleted = helper.getAdjToBeDeleted(newList);
    if (adjToBeDeleted != null && adjToBeDeleted.size() > 0) {
      handleDelete(adjToBeDeleted);
    }
    List<cve__PaymentSpecification__c> psList = helper.resetRecoupOverpaymentField(
      newList
    );
    if (psList != null && psList.size() > 0) {
      handleUpdate(psList);
    }
  }

  public void handleDelete(List<SObject> sobjectList) {
    try {
      List<Database.DeleteResult> results = Database.delete(sobjectList);
      handleErrors(results);
    } catch (Exception e) {
      throw new CustomException(
        'Exception while deleting zero adjustments :- ' + e
      );
    }
  }

  public void handleUpdate(List<SObject> sobjectList) {
    try {
      List<Database.SaveResult> results = Database.update(sobjectList);
      handleErrors(results);
    } catch (Exception e) {
      throw new CustomException(
        'Exception while resetting Recoup Overpayment Checkbox :- ' + e
      );
    }
  }

  public void handleErrors(List<Database.DeleteResult> results) {
    for (Database.DeleteResult result : results) {
      if (!result.isSuccess()) {
        String s = '';
        for (Database.Error err : result.getErrors()) {
          s += 'Error: ' + err.getStatusCode() + ' ' + err.getMessage();
        }
        throw new CustomException(s);
      }
    }
  }

  public void handleErrors(List<Database.SaveResult> results) {
    for (Database.SaveResult result : results) {
      if (!result.isSuccess()) {
        String s = '';
        for (Database.Error err : result.getErrors()) {
          s += 'Error: ' + err.getStatusCode() + ' ' + err.getMessage();
        }
        throw new CustomException(s);
      }
    }
  }

  public class CustomException extends Exception {
  }
}