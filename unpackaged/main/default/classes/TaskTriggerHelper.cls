public with sharing class TaskTriggerHelper {
  private static TaskTriggerHelper instance = null;

  public static TaskTriggerHelper getHelperInstance() {
    if (instance == null) {
      instance = new TaskTriggerHelper();
    }

    return instance;
  }

  public void validateComment(List<Task> newList) {
    Map<Id, cve__BenefitClaimed__c> benefitClaimedByTask = getBenefitClaimed(
      newList
    );
    Id groupDisabilityQueueId = getQueueId('Group Disability Review');
    Id supplementalQueueId = getQueueId('Supplemental Claims Review');
    for (Task t : newList) {
      if (
        newList[0].Subject == 'Requesting to review Benefit Claimed' &&
        (benefitClaimedByTask.get(t.WhatId).cve__RecordTypeName__c ==
        'CriticalIllness' ||
        benefitClaimedByTask.get(t.WhatId).cve__RecordTypeName__c ==
        'HospitalIndemnity' ||
        benefitClaimedByTask.get(t.WhatId).cve__RecordTypeName__c == 'Accident')
      ) {
        t.OwnerId = supplementalQueueId;
      } else if (
        newList[0].Subject == 'Requesting to review Benefit Claimed' &&
        (benefitClaimedByTask.get(t.WhatId).cve__RecordTypeName__c !=
        'CriticalIllness' &&
        benefitClaimedByTask.get(t.WhatId).cve__RecordTypeName__c !=
        'HospitalIndemnity' &&
        benefitClaimedByTask.get(t.WhatId).cve__RecordTypeName__c != 'Accident')
      ) {
        t.OwnerId = groupDisabilityQueueId;
      }
    }
  }

  public id getQueueId(String queueName) {
    return [
      SELECT Id, Type
      FROM Group
      WHERE Type = 'Queue' AND Name = :queueName
    ]
    .id;
  }

  public Map<Id, cve__BenefitClaimed__c> getBenefitClaimed(List<Task> newList) {
    Set<Id> tskIds = new Set<Id>();
    for (Task t : newList) {
      tskIds.add(t.WhatId);
    }
    Map<Id, cve__BenefitClaimed__c> benefitClaimedByTask = new Map<Id, cve__BenefitClaimed__c>(
      [
        SELECT Id, cve__RecordTypeName__c
        FROM cve__BenefitClaimed__c
        WHERE Id IN :tskIds
      ]
    );
    return benefitClaimedByTask;
  }
}