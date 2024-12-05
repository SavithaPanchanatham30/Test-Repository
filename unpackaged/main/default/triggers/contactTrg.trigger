/*
Purpose : Contact Trigger (Before insert and update) 
          
Created Date : 2014-02-12
Modified Date: 
Author : Muhammad Asif (Sakonent)
Version : 1.0

*/

trigger contactTrg on Contact (after insert, after update) {
    List<Member__c> lstMember = new List<Member__c>();
    List<Member__c> lstMemberDelete = new List<Member__c>();
    
    set<Id> setOfMemberIds = new set<Id>();
    
    for(Contact contactItem : Trigger.New){
        setOfMemberIds.add(contactItem.Id);
    }
    
    //Maintaining map for existing members
    Map<Id, Member__c> mapOfMember = null;
    Map<string, Id> mapOfMemberGroup = new Map<string, Id>();
    
    if (setOfMemberIds.size() > 0){
        mapOfMember = new Map<Id, Member__c>([Select m.Member__c, m.Id, m.Group__c From Member__c m Where m.Member__c =: setOfMemberIds]);
        
        for (Id itemId : mapOfMember.keySet()){
            mapOfMemberGroup.put(mapOfMember.get(itemId).Member__c+'-'+mapOfMember.get(itemId).Group__c, itemId);
        }
    }
    
    for(Contact contactItem : Trigger.New){
        if (Trigger.isInsert && contactItem.Group__c != null){
        
            if (mapOfMemberGroup.get(contactItem.Id+'-'+contactItem.Group__c) == null){
                lstMember.add(new Member__c(Member__c=contactItem.Id, Group__c = contactItem.Group__c));
            }                   
        
        } else if (Trigger.isUpdate && contactItem.Group__c != null
                                    && contactItem.Group__c != Trigger.oldMap.get(contactItem.Id).Group__c){
            
            if (mapOfMemberGroup.get(contactItem.Id+'-'+contactItem.Group__c) == null){
                
                lstMember.add(new Member__c(Member__c=contactItem.Id, 
                                            Group__c = contactItem.Group__c));
                                            
                if (mapOfMemberGroup.get(contactItem.Id+'-'+Trigger.oldMap.get(contactItem.Id).Group__c) != null) {
                    lstMemberDelete.add(mapOfMember.get(mapOfMemberGroup.get(contactItem.Id+'-'+Trigger.oldMap.get(contactItem.Id).Group__c)));
                }               
            } 
        } 
        
        if (lstMember.size() > 0) {
            upsert lstMember Id;
        }
        
        if (lstMemberDelete.size() > 0 ) {
            delete lstMemberDelete;
        }
        
    }
}