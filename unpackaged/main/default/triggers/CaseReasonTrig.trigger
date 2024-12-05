/*
Purpose : Case Trigger (Before insert and update) 
          1) Copies the Account and Contact field values in Member Group and Member
          
Created Date : 2013-12-10
Modified Date: 2014-02-12
Author : Laura McKevitt
Modify By : Muhammad Asif
Version : Version 5

*/

trigger CaseReasonTrig on Case (before insert, before update) {
    set<Id> setOfMemberIds = new set<Id>();
    for(Case caseItem : Trigger.New){ 
        setOfMemberIds.add(caseItem.Member__c);
    }
    
    Map<Id, Contact> mapOfContact = new map<Id, Contact>([Select c.Id, c.AccountId From Contact c WHERE c.Id =: setOfMemberIds]);
    
    for(Case caseItem : Trigger.New){   
        
        if ((trigger.isInsert && caseItem.Reason == 'Self') || 
            (trigger.isUpdate &&
                caseItem.Reason == 'Self' &&
                (caseItem.Reason != trigger.oldMap.get(caseItem.Id).Reason ||
                 caseItem.Master_Group__c != trigger.oldMap.get(caseItem.Id).Master_Group__c ||
                 caseItem.Member__c != trigger.oldMap.get(caseItem.Id).Member__c) )) {
                
                caseItem.Member__c = caseItem.ContactId;
                caseItem.Master_Group__c = caseItem.AccountId;                
        }
                
        if ((trigger.isInsert && caseItem.Reason == 'Agent/Member') || 
            (trigger.isUpdate &&
                caseItem.Reason == 'Agent/Member' &&
                (caseItem.Reason != trigger.oldMap.get(caseItem.Id).Reason ||
                 caseItem.Master_Group__c != trigger.oldMap.get(caseItem.Id).Master_Group__c ||
                 caseItem.Member__c != trigger.oldMap.get(caseItem.Id).Member__c) )) {
                
                if (mapOfContact.get(caseItem.Member__c) != null){
                    caseItem.Master_Group__c = mapOfContact.get(caseItem.Member__c).AccountId;
                } else {
                    caseItem.Master_Group__c = null;
                }                
        }
            
        if ((trigger.isInsert && caseItem.Reason == 'Group/Member') || 
            (trigger.isUpdate &&
                caseItem.Reason == 'Group/Member' &&
                (caseItem.Reason != trigger.oldMap.get(caseItem.Id).Reason ||
                 caseItem.Master_Group__c != trigger.oldMap.get(caseItem.Id).Master_Group__c ||
                 caseItem.Member__c != trigger.oldMap.get(caseItem.Id).Member__c) )) {
                
                caseItem.Master_Group__c = caseItem.AccountId;
        }
        
        if ((trigger.isInsert && caseItem.Reason == 'Group') || 
            (trigger.isUpdate &&
                caseItem.Reason == 'Group' &&
                (caseItem.Reason != trigger.oldMap.get(caseItem.Id).Reason ||
                 caseItem.Master_Group__c != trigger.oldMap.get(caseItem.Id).Master_Group__c ||
                 caseItem.Member__c != trigger.oldMap.get(caseItem.Id).Member__c) )) {
                
                caseItem.Master_Group__c = caseItem.AccountId;
        }
        
        if ((trigger.isInsert && caseItem.Reason == 'N/A') || 
            (trigger.isUpdate &&
                caseItem.Reason == 'N/A' &&
                (caseItem.Reason != trigger.oldMap.get(caseItem.Id).Reason ||
                 caseItem.Master_Group__c != trigger.oldMap.get(caseItem.Id).Master_Group__c ||
                 caseItem.Member__c != trigger.oldMap.get(caseItem.Id).Member__c) )) {
                
                caseItem.Member__c = null;
                caseItem.Master_Group__c = null;        
        }   
    }   
}