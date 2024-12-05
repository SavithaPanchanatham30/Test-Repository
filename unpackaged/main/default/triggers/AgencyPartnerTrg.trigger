/*
Name        : AgencyPartnerTrg
Author      : Munazza Ahmed
Date        : 9/2/2016
Purpose : - On creation of agency partner record, mark relevant region checkboxes for partner account and agent contact.
 
*/
trigger AgencyPartnerTrg on Agency_Partner__c (after insert, after update)
{
    if(Trigger.isInsert && Trigger.isAfter)
    {
        //initializing variables
        set<Id> setOfAgentsAccIds = new set<Id>();
        
        list<Account> listOfPartnersToUpdate = new list<Account>();
        list<Account> listOfAgenciesToUpdate = new list<Account>();
        list<Contact> listOfContactsToUpdate = new list<Contact>();
        
        map<Id,Id> mapOfAgencyIdandPartnerId = new map<Id,Id>();
        map<string, string> mapOfNameandPartnerIdAPIfield = new map<string, string> ();
        
        //traverse custom setting of blue rep fields
        for(Blue_Rep_Fields__c blueRepFields :  [SELECT Name, API_Name_of_field__c, Partner_Id__c, Name_of_field__c
                                                FROM Blue_Rep_Fields__c])
        {
            if(blueRepFields.Partner_Id__c != null && blueRepFields.API_Name_of_field__c != null)
            {
                mapOfNameandPartnerIdAPIfield.put(blueRepFields.Name, blueRepFields.Partner_Id__c+'-'+blueRepFields.API_Name_of_field__c);  //custom setting name against partner id and respective field api name
            }
        }                                             
       
        for(Agency_Partner__c agencyPartner : Trigger.new)
        {
            mapOfAgencyIdandPartnerId.put(agencyPartner.Master_Agency_ID__c,agencyPartner.Master_Partner_ID__c);    //store agencyId and partnerId in a map that is being inserted
        }
        
        if(mapOfAgencyIdandPartnerId.size()>0)
        {
            //traverse partner accounts that are being related with agency
            for(Account partnerAcc : [SELECT Id, name
                                      FROM Account
                                      WHERE Id IN: mapOfAgencyIdandPartnerId.values()])
            {
                //traverse for each custom setting record
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    //check for matching partner Id
                    if((mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == partnerAcc.Id)
                    {
                       
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        partnerAcc.put(fieldName,true); //mark the field true
                        
                    }
                    
                }
                listOfPartnersToUpdate.add(partnerAcc); //account partners to be updated with checkbox
                
            }
        }
        if(listOfPartnersToUpdate.size()>0)
        {
            update listOfPartnersToUpdate;
        }
        if(mapOfAgencyIdandPartnerId.size()>0)
        {
            //traverse agency accounts that are being related with partners
            for(Account agencyAcc : [SELECT Id, name
                                      FROM Account
                                      WHERE Id IN: mapOfAgencyIdandPartnerId.keyset()])
            {
                //traverse for each custom setting record
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    //check for matching partner Id
                    if((mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == mapOfAgencyIdandPartnerId.get(agencyAcc.Id))
                    {
                       
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        agencyAcc.put(fieldName,true); //mark the field true
                        
                    }
                    
                }
                listOfAgenciesToUpdate.add(agencyAcc); //account partners to be updated with checkbox
                
            }
        }
        if(listOfAgenciesToUpdate.size()>0)
        {
            update listOfAgenciesToUpdate;
        }
        
        if(mapOfAgencyIdandPartnerId.size()>0)
        {
            //contact update functionality
            for(account agentAcc : [SELECT Id,Partner__c
                                    FROM Account
                                    WHERE Id IN: mapOfAgencyIdandPartnerId.keyset()])
            {
                setOfAgentsAccIds.add(agentAcc.Id);
            }
        }
        // These lines are added by Zaid
        Map <Id,Id> MapOfContactAndAgencyID = new Map <Id, Id>();
        Map <Id,Id> MapOfContactAndAgencyBranchId = new Map <Id, Id>();
        Map <Id,Id> MapOfAgencyBranchIdAndContactId = New Map <Id, Id>();
        // Zaid's added lines end here
        if(setOfAgentsAccIds.size()>0)
        {
            //traverse agent contacts that are being related with agency
            for(contact con : [SELECT id,accountId, Agency_Branch__c
                               FROM contact
                               WHERE accountId in: setOfAgentsAccIds])
            {
                //check for matching partner Id
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    if( (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == mapOfAgencyIdandPartnerId.get(con.accountId))
                    {
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        con.put(fieldName,true);    //mark the field true
                        
                        MapOfContactAndAgencyID.put(con.id,con.accountId);
                        MapOfContactAndAgencyBranchId.put(con.id,con.Agency_Branch__c);
                        MapOfAgencyBranchIdAndContactId.put(con.Agency_Branch__c,con.id);
                    }
                
                }
                listOfContactsToUpdate.add(con);    //contact agents to be updated with checkbox
            }
        }
        // update listOfContactsToUpdate; //This line is commented by Zaid 
        
        // Zaid code modification starts here
        
        for(contact cont : [SELECT id,accountId, Agency_Branch__c
                           FROM contact
                           WHERE accountId in: MapOfAgencyBranchIdAndContactId.keyset()])
        {
            for(string mapKey1 : mapOfNameandPartnerIdAPIfield.keyset())
            {
                if( (mapOfNameandPartnerIdAPIfield.get(mapKey1)).substringbefore('-') == mapOfAgencyIdandPartnerId.get(MapOfContactAndAgencyID.get(MapOfAgencyBranchIdAndContactId.get(cont.AccountId))))
                {
                    string fieldName1 = (mapOfNameandPartnerIdAPIfield.get(mapKey1)).substringafter('-'); //get field api name
                    cont.put(fieldName1,true);    //mark the field true
                }
            }
            listOfContactsToUpdate.add(cont);
        }   
        update listOfContactsToUpdate;
        // Zaid code modification starts here
      
    }
    
    if(Trigger.isUpdate && Trigger.isAfter)
    {
        //initializing variables
        set<Id> setOfAgentsAccIds = new set<Id>();
        
        list<Account> listOfPartnersToUpdate = new list<Account>();
        list<Account> listOfAgenciesToUpdate = new list<Account>();
        //list<Account> listOfPartnersToReset = new list<Account>();
        //list<Account> listOfAgenciesToReset = new list<Account>();
        list<Contact> listOfContactsToUpdate = new list<Contact>();
        //list<Contact> listOfContactsToReset = new list<Contact>();
        //list<Contact> listOfBranchContactsToReset = new list<Contact>();
        list<Contact> listOfBranchContactsToUpdate = new list<Contact>();
        
        map<Id,Id> mapOfAgencyIdandPartnerId = new map<Id,Id>();
        map<string, string> mapOfNameandPartnerIdAPIfield = new map<string, string> ();
        
        set<Contact> setOfContacts = new set<Contact>();
        
        //traverse custom setting of blue rep fields
        for(Blue_Rep_Fields__c blueRepFields :  [SELECT Name, API_Name_of_field__c, Partner_Id__c, Name_of_field__c
                                                FROM Blue_Rep_Fields__c])
        {
            if(blueRepFields.Partner_Id__c != null && blueRepFields.API_Name_of_field__c != null)
            {
                mapOfNameandPartnerIdAPIfield.put(blueRepFields.Name, blueRepFields.Partner_Id__c+'-'+blueRepFields.API_Name_of_field__c);  //custom setting name against partner id and respective field api name
                
            }
        }  
                                                    
       
        for(Agency_Partner__c agencyPartner : Trigger.new)
        {
            if(Trigger.oldMap.get(agencyPartner.Id).Master_Agency_ID__c != agencyPartner.Master_Agency_ID__c || Trigger.oldMap.get(agencyPartner.Id).Master_Partner_ID__c != agencyPartner.Master_Partner_ID__c)
            {
                if(agencyPartner.Master_Agency_ID__c !=  null && agencyPartner.Master_Partner_ID__c != null)
                {
                    mapOfAgencyIdandPartnerId.put(agencyPartner.Master_Agency_ID__c,agencyPartner.Master_Partner_ID__c);    //store agencyId and partnerId in a map that is being inserted
                }
            }
        }
        
        
        /*
        if(mapOfAgencyIdandPartnerId.size()>0)
        {
            //traverse partner accounts that are being related with agency
            for(Account partnerAcc : [SELECT Id, name
                                      FROM Account
                                      WHERE Id IN: mapOfAgencyIdandPartnerId.values()])
            {
                //traverse for each custom setting record
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                    partnerAcc.put(fieldName,false); //mark the field false
                }
                listOfPartnersToReset.add(partnerAcc); //account partners to be updated with checkbox
                //system.debug('listOfPartnersToReset '+listOfPartnersToReset);
                
            }
        }
        if(listOfPartnersToReset.size()>0)
        {
            update listOfPartnersToReset;
        }
        */
        if(mapOfAgencyIdandPartnerId.size()>0)
        {
            //traverse partner accounts that are being related with agency
            for(Account partnerAcc : [SELECT Id, name
                                      FROM Account
                                      WHERE Id IN: mapOfAgencyIdandPartnerId.values()])
            {
                //traverse for each custom setting record
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    //check for matching partner Id
                    if((mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == partnerAcc.Id)
                    {
                       
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        partnerAcc.put(fieldName,true); //mark the field true
                        
                    }
                    
                }
                listOfPartnersToUpdate.add(partnerAcc); //account partners to be updated with checkbox
                
            }
            if(listOfPartnersToUpdate.size()>0)
            {
                update listOfPartnersToUpdate;
            }
        }
        
        
        /*
        //reset agency accounts that are being related with partners
        for(Account agencyAcc : [SELECT Id, name
                                  FROM Account
                                  WHERE Id IN: mapOfAgencyIdandPartnerId.keyset()])
        {
            //traverse for each custom setting record
            for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
            { 
                string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                agencyAcc.put(fieldName,false); //mark the field false
                
            }
            listOfAgenciesToReset.add(agencyAcc); //account partners to be updated with checkbox
            
        }
        //system.debug('listOfAgenciesToReset '+listOfAgenciesToReset);
        if(listOfAgenciesToReset.size()>0)
        {
            update listOfAgenciesToReset;
        }
        */
       
        if(mapOfAgencyIdandPartnerId.size()>0)
        {
            //traverse agency accounts that are being related with partners
            for(Account agencyAcc : [SELECT Id, name
                                      FROM Account
                                      WHERE Id IN: mapOfAgencyIdandPartnerId.keyset()])
            {
                //traverse for each custom setting record
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    //check for matching partner Id
                    if((mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == mapOfAgencyIdandPartnerId.get(agencyAcc.Id))
                    {
                       
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        agencyAcc.put(fieldName,true); //mark the field true
                        
                    }
                    
                }
                listOfAgenciesToUpdate.add(agencyAcc); //account partners to be updated with checkbox
                
            }
            if(listOfAgenciesToUpdate.size()>0)
            {
                update listOfAgenciesToUpdate;
            }
        }
        
        
        //contact update functionality
        for(account agentAcc : [SELECT Id,Partner__c
                                FROM Account
                                WHERE Id IN: mapOfAgencyIdandPartnerId.keyset()])
        {
            setOfAgentsAccIds.add(agentAcc.Id);
        }
        if(setOfAgentsAccIds.size()>0)
        {
            for(contact con : [SELECT id,accountId, Agency_Branch__c
                               FROM contact
                               WHERE accountId in: setOfAgentsAccIds])
            {
                setOfContacts.add(con);
                
            }
        }
        
        // These lines are added by Zaid
            Map <Id,Id> MapOfContactAndAgencyID = new Map <Id, Id>();
            Map <Id,Id> MapOfContactAndAgencyBranchId = new Map <Id, Id>();
            Map <Id,Id> MapOfAgencyBranchIdAndContactId = New Map <Id, Id>();
        // Zaid's added lines end here
        
        /*
        //reset agent contacts that are being related with agency
        for(contact con : setOfContacts)
        {
            system.debug('inside reset of agent');
            //check for matching partner Id
            for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
            {
                string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                con.put(fieldName,false);    //mark the field false
            }
            listOfContactsToReset.add(con);    //contact agents to be updated with checkbox
            
            //Populating branch contacts
            if(con.Agency_Branch__c != null)
            {
                setOfBranchContacts.add(con.Agency_Branch__c);
                mapOfAgencyIdandBranchId.put(con.AccountId, con.Agency_Branch__c);
            }
            if(listOfContactsToReset.size()>0)
            {
                update listOfContactsToReset;
            }
        }
        
        */
        if(setOfContacts.size()>0)
        {
            //traverse agent contacts that are being related with agency
            for(contact con : setOfContacts)
            {
                system.debug('inside update of agent');
                //check for matching partner Id
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    if( (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == mapOfAgencyIdandPartnerId.get(con.accountId))
                    {
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        con.put(fieldName,true);    //mark the field true
                        
                        MapOfContactAndAgencyID.put(con.id,con.accountId);
                        MapOfContactAndAgencyBranchId.put(con.id,con.Agency_Branch__c);
                        MapOfAgencyBranchIdAndContactId.put(con.Agency_Branch__c,con.id);
                    }
                
                }
                listOfContactsToUpdate.add(con);    //contact agents to be updated with checkbox
            }
            if(listOfContactsToUpdate.size()>0)
            {
                update listOfContactsToUpdate;
            }
        }
        /*
        for(contact cont : [SELECT id,accountId, Agency_Branch__c
                           FROM contact
                           WHERE accountId in: MapOfAgencyBranchIdAndContactId.keyset()])
        {
            for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
            {
                string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                cont.put(fieldName,false);    //mark the field true
                
            }
            listOfBranchContactsToReset.add(cont);
        }   
        if(listOfBranchContactsToReset.size()>0)
        {
            update listOfBranchContactsToReset;
        }
        */
        if(MapOfAgencyBranchIdAndContactId.size()>0)
        {
            //updating branch agency with relevant checkbox
            for(contact cont : [SELECT id,accountId, Agency_Branch__c
                               FROM contact
                               WHERE accountId in: MapOfAgencyBranchIdAndContactId.keyset()])
            {
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    if( (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == mapOfAgencyIdandPartnerId.get(MapOfContactAndAgencyID.get(MapOfAgencyBranchIdAndContactId.get(cont.AccountId))))
                    {
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        cont.put(fieldName,true);    //mark the field true
                    }
                }
                listOfBranchContactsToUpdate.add(cont);
            }   
            if(listOfBranchContactsToUpdate.size()>0)
            {
                update listOfBranchContactsToUpdate;
            }
        }
    }
}