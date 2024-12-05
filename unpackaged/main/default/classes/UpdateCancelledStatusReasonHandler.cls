public with sharing class UpdateCancelledStatusReasonHandler extends TriggerHandler {
  UpdateCancelledStatusReasonHelper helper;
  List<UpdateCancelledStatusReason__e> newList;

  public UpdateCancelledStatusReasonHandler() {
    this(UpdateCancelledStatusReasonHelper.getInstance(), Trigger.New);
  }

  @TestVisible
  private UpdateCancelledStatusReasonHandler(
    UpdateCancelledStatusReasonHelper helper,
    List<UpdateCancelledStatusReason__e> newList
  ) {
    this.helper = helper;
    this.newList = newList;
  }

  public override void afterInsert() {
    List<cvab__DateRange__c> dateRangeList = helper.updateStatusReasonOfDateRange(
      newList
    );
    handleUpdate(dateRangeList);
  }

  public void handleUpdate(List<SObject> sobjectList) {
    try {
      List<Database.SaveResult> results = Database.update(sobjectList, false);
      handleErrors(results);
    } catch (Exception e) {
      throw new CustomException('Exception while  :- ' + e);
    }
  }

  public void handleErrors(List<Database.SaveResult> result) {
    for (Database.SaveResult sr : result) {
      if (!sr.isSuccess()) {
        String s = '';
        for (Database.Error err : sr.getErrors()) {
          s += ('Error returned : ' +
          err.getStatusCode() +
          ' - ' +
          err.getMessage());
        }
        throw new CustomException(s);
      }
    }
  }

  public class CustomException extends Exception {
  }
}