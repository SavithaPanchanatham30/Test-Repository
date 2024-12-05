public with sharing class HandleApprovalProcessAssistant {
  public static final List<String> SUPPLEMENTALRECORDTYPES = new List<String>{
    'Accident',
    'Critical Illness',
    'Hospital Indemnity'
  };
  public static final List<String> QUEUENAMES = new List<String>{
    'Absence Review',
    'Group Disability Review',
    'Supplemental Claims Review',
    'Claims Director',
    'VP Claims'
  };

  public Map<String, PaymentApprovalLimit__mdt> getApprovalLimits() {
    List<PaymentApprovalLimit__mdt> limits = [
      SELECT
        AbsenceReleaseLimit__c,
        DisabilityAdHocPaymentLimit__c,
        DisabilityRecurringPaymentsLimit__c,
        DisabilityReleaseLimitDays__c,
        RoleName__c,
        SupplementalReleaseLimitsAccident__c,
        SupplementalReleaseLimitsCritical__c
      FROM PaymentApprovalLimit__mdt
    ];
    Map<String, PaymentApprovalLimit__mdt> result = new Map<String, PaymentApprovalLimit__mdt>();
    for (PaymentApprovalLimit__mdt data : limits) {
      result.put(data.RoleName__c, data);
    }
    return result;
  }

  public User getCurrentUser() {
    return [
      SELECT
        id,
        name,
        email,
        UserName,
        UserType,
        AbsenceClaimsLOARole__c,
        DisabilityClaimsLOARole__c,
        SupplementalClaimsLOARole__c
      FROM User
      WHERE id = :UserInfo.getUserId()
    ];
  }

  public Map<String, Id> getQueueIds() {
    Map<String, Id> result = new Map<String, Id>();
    List<Group> queues = [
      SELECT id, Name
      FROM Group
      WHERE Name IN :QUEUENAMES AND Type = 'Queue'
    ];
    if (queues.size() != QUEUENAMES.size()) {
      throw new CustomException('Queue is missing');
    }
    for (Group queue : queues) {
      result.put(queue.Name, queue.id);
    }
    return result;
  }

  public Map<String, Id> getSupplementalRecordTypeIds() {
    Map<String, Id> result = new Map<String, Id>();
    for (String recordType : SUPPLEMENTALRECORDTYPES) {
      Id typeID = Schema.getGlobalDescribe()
        .get('cve__PaymentSpecification__c')
        .getDescribe()
        .getRecordTypeInfosByName()
        .get(recordType)
        .getRecordTypeId();
      result.put(recordType, typeId);
    }
    return result;
  }

  public Boolean checkAdhocPayments(
    cve__PaymentSpecification__c ps,
    Decimal amount
  ) {
    if (amount == null) {
      return false;
    }
    Id typeID = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Calculated')
      .getRecordTypeId();

    Decimal totalAmount = 0;
    for (cve__Payment__c pay : ps.cve__Payments__r) {
      if (pay.RecordTypeId != typeID) {
        totalAmount += pay.cve__Net__c;
      }
    }
    if (totalAmount > amount) {
      return false;
    }
    return true;
  }

  public Boolean checkPaymentAmount(
    cve__PaymentSpecification__c ps,
    Decimal amount
  ) {
    if (amount == null) {
      return false;
    }

    Id typeID = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Calculated')
      .getRecordTypeId();
    for (cve__Payment__c pay : ps.cve__Payments__r) {
      if (pay.RecordTypeId == typeID && pay.cve__Net__c > amount) {
        return false;
      }
    }
    return true;
  }

  public String checkIfSupplemental(
    cve__PaymentSpecification__c ps,
    Boolean sup
  ) {
    Id typeID = Schema.getGlobalDescribe()
      .get('cve__PaymentSpecification__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Critical Illness')
      .getRecordTypeId();
    String result = '';
    if (sup && ps.RecordTypeId == typeId) {
      result = 'Critical';
    } else if (sup && ps.RecordTypeId != typeId) {
      result = 'Accident';
    } else {
      result = 'Others';
    }
    return result;
  }

  public Boolean checkPaymentPeriod(
    cve__PaymentSpecification__c ps,
    Decimal period
  ) {
    if (period == null) {
      return false;
    }
    Decimal noOfDays = 0;
    Id typeID = Schema.getGlobalDescribe()
      .get('cve__Payment__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Calculated')
      .getRecordTypeId();
    for (cve__Payment__c pay : ps.cve__Payments__r) {
      if (pay.RecordTypeId == typeID) {
        noOfDays += pay.cve__Start__c.daysBetween(pay.cve__Through__c);
      }
    }
    if (noOfDays > period) {
      return false;
    }
    return true;
  }

  public void updatePaymentStatus(Id psId, Map<Id, cve__Payment__c> newMap) {
    for (cve__Payment__c newPay : newMap.values()) {
      if (newPay.cve__PaymentSpecification__c == psId) {
        newPay.cve__Status__c = 'Submitted for Approval';
      }
    }
  }

  public Map<Id, cve__PaymentSpecification__c> getPaymentSpecs(
    Map<Id, cve__Payment__c> newMap
  ) {
    Set<Id> psIds = new Set<Id>();
    for (cve__Payment__c pay : newMap.values()) {
      psIds.add(pay.cve__PaymentSpecification__c);
    }

    return new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT
          id,
          cve__Amount__c,
          cve__NumberOfPaymentPeriods__c,
          cve__AmountPeriod__c,
          cvint__AbsenceClaim__c,
          cve__Claim__c,
          RecordTypeId,
          RunApprovalAs__c,
          (
            SELECT
              id,
              cve__Status__c,
              cve__Net__c,
              cve__Start__c,
              cve__Through__c,
              RecordTypeId,
              cve__Contact__c,
              cve__Account__c
            FROM cve__Payments__r
          )
        FROM cve__PaymentSpecification__c
        WHERE id IN :psIds AND RunApprovalAs__c != 'ClaimBrain Integration User'
      ]
    );
  }

  public Boolean checkForPartialApprovals(
    cve__PaymentSpecification__c ps,
    Map<Id, cve__Payment__c> newMap
  ) {
    List<cve__Payment__c> payList = new List<cve__Payment__c>();
    List<cve__Payment__c> payListFromPaymentSpec = new List<cve__Payment__c>();
    String payee;
    for (cve__Payment__c pay : newMap.values()) {
      if (pay.cve__PaymentSpecification__c == ps.id) {
        payee = pay.cve__Contact__c != null
          ? pay.cve__Contact__c
          : pay.cve__Account__c;
        payList.add(pay);
      }
    }

    for (cve__Payment__c pay : ps.cve__Payments__r) {
      if (
        (pay.cve__Status__c == 'Pending' ||
        pay.cve__Status__c == 'Submitted For Approval') &&
        (pay.cve__Account__c == payee ||
        pay.cve__Contact__c == payee)
      ) {
        payListFromPaymentSpec.add(pay);
      }
    }
    if (payList.size() == payListFromPaymentSpec.size()) {
      return true;
    } else {
      return false;
    }
  }

  public void resetTheStatus(
    cve__PaymentSpecification__c ps,
    Map<Id, cve__Payment__c> oldMap,
    Map<Id, cve__Payment__c> newMap
  ) {
    for (cve__Payment__c newPay : newMap.values()) {
      if (newPay.cve__PaymentSpecification__c == ps.id) {
        cve__Payment__c oldPay = oldMap.get(newPay.id);
        newPay.cve__Status__c = oldPay.cve__Status__c;
      }
    }
  }

  public class CustomException extends Exception {
  }
}