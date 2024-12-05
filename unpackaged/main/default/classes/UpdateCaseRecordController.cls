public with sharing class UpdateCaseRecordController {
  @AuraEnabled(cacheable=true)
  public static Case getCaseRecord(Id recordId) {
    try {
      return [
        SELECT id, ContactId
        FROM Case
        WHERE id = :recordId
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void updateClaimIntakeLastRunByUserField(Id recordId) {
    try {
      Case currRecord = [
        SELECT id, ClaimIntakeLastRunByUser__c
        FROM Case
        WHERE id = :recordId
      ];
      User currUser = [
        SELECT id
        FROM User
        WHERE id = :UserInfo.getUserId()
      ];
      currRecord.ClaimIntakeLastRunByUser__c = currUser.id;
      handleUpdate(new List<Case>{ currRecord });
    } catch (Exception e) {
      throw new CustomException(e);
    }
  }

  public static void handleUpdate(List<SObject> sobjectList) {
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

  public class CustomException extends Exception {
  }
}