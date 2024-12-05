/*
Created by: Munazza Ahmed
Created Date: 8/15/2016
Purpose: - Ensure the change in hierarchy fields is updated in related opportunities.

Modified by: Munazza Ahmed
Modification Date: 9/3/2016
Purpose: 
    - Setting Contact 'FL' check TRUE, when Contact
        - RecordType is 'Partner Rep' AND its Account is 'Blue Cross Blue Shield of Florida' AND its Account RecordType is 'Partner'
        - RecordType is 'Group Contact' AND its Agency Partner is 'Blue Cross Blue Shield of Florida' and its Account RecordType is 'Master group'
        - RecordType is 'Agent' AND its Account Agency branch is not NULL AND Contact Agency branch 'FL' check is 'TRUE' 
        
    - Setting Contact 'LSV_Master_ID_Agency_Branch__c'and 'LSV_Master_Account_ID__c' for contact duplication needs.

    -  When an agency/partner relationship is created, find the Partner Id in the custom setting and then update the field indicated in API_Name_of_field__c to TRUE. Update the field on both the Agency record and its contact records.

    - Limit the ability of users to update contact fields that are populated by ETL.

    - Partner rep. update on contact affects opportunity partner rep info.

    

    Last Modified By    :   Mansoor Ahmad (Tectonic LLC)
    Date                :   02/06/2019
    Description         :   [Case#5165] For every contact that is inserted or updated, get its Account's LSV_Master_ID__c and set this value on the Contact.LSV_Master_Account_Id__c.


*/

trigger contTrg on Contact (before update, before insert, after update, after insert)
{
    //WF replace code M. Asif April 07, 2017
    //if (Trigger.isBefore){

    if((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore) 
    {
        set<Id> sAccountId = new set<Id>();
        set<Id> sAgencyAccountId = new set<Id>();
        
        // [02/06/2019 - Mansoor - Case#5165] Create a new set for the Accounts of new inserted/Updated Contacts
        set<Id> sAllAccountIds = new set<Id>();
        
        for (Contact Con : trigger.new)
        {
            if (Con.AccountId != null && (con.Account_Record_Type_Name__c  == 'Master_Group' || con.Account_Record_Type_Name__c == 'Partner')) 
            { 
                sAccountId.add(Con.AccountId); 
            }
            
            if ((Con.AccountId != null || Con.Agency_Branch__c != null) && con.Account_Record_Type_Name__c  == 'Agency' ) 
            { 
                sAgencyAccountId.add(Con.AccountId);
                sAgencyAccountId.add(Con.Agency_Branch__c); 
            }
            
            
            // [02/06/2019 - Mansoor - Case#5165] Get the AccountId without any specific condition
            if (Con.AccountId != null){
                sAllAccountIds.add(Con.AccountId);
            }
        }
        
        Map<Id, String> mapBlueRepCS = new Map<Id, String>();
        string strRegions = '';
        
        for(Blue_Rep_Fields__c blueRepFieldCS : Blue_Rep_Fields__c.getAll().values())
        {
            mapBlueRepCS.put(blueRepFieldCS.Partner_Id__c, blueRepFieldCS.API_Name_of_field__c);
            strRegions += blueRepFieldCS.API_Name_of_field__c + ',';
        }        
        
        String strAgencyBranch = 'Select ' + strRegions + ' Id, LSV_Master_Id__c, Name, Partner__r.Name, RecordType.Name, RecordTypeId  from Account WHERE Id IN :sAgencyAccountId and Service_Master_Agency__c != null';
        List<Account> listAgencyBranch = Database.query(strAgencyBranch);
        
        String strServiceAgencyMaster = 'Select ' + strRegions + ' Id, Master_Agency_Record__c, RecordType.Name, RecordTypeId  from Account WHERE Id IN :sAgencyAccountId and Master_Agency_Record__c = true';
        List<Account> listSrvAgencyMaster = Database.query(strServiceAgencyMaster);
        
        
        
        // [02/06/2019 - Mansoor - Case#5165] Prepare a String Query for getting the Accounts with the field 'LSV_Master_Id' for the Contacts that are recently updated/inserted
        String strAccounts = 'SELECT Id, LSV_Master_Id__c FROM Account WHERE Id IN :sAllAccountIds AND LSV_Master_Id__c != null';
        List<Account> listAllAccounts = Database.query(strAccounts);
        
        // [02/06/2019 - Mansoor - Case#5165] Prepare a map of all Accounts' Ids with the Account records
        map<Id, Account> mapAllAccounts = new map<Id, Account>();
        if (listAllAccounts != null && listAllAccounts.size() > 0)
        {
            for (Account acct : listAllAccounts)
            {
                mapAllAccounts.put(acct.Id, acct);
            }
        }
        
        
                
        map<Id, Account> mapAgencyBranch = new map<Id, Account>();
        if (listAgencyBranch != null && listAgencyBranch.size() > 0)
        {
            for (Account acct : listAgencyBranch)
            {
                mapAgencyBranch.put(acct.Id, acct);
            }
        }
        
        map<Id, Account> mapSrvAgencyMaster = new map<Id, Account>();
        if (listSrvAgencyMaster != null && listSrvAgencyMaster.size() > 0)
        {
            for (Account acct : listSrvAgencyMaster)
            {
                mapSrvAgencyMaster.put(acct.Id, acct);
            }
        }        

        system.debug('ah::sAgencyAccountId ' + sAgencyAccountId);
        List<Agency_Partner__c> listAgencyPartner = [select id, Master_Partner_ID__c, Master_Agency_ID__c 
                                                     from Agency_Partner__c 
                                                     where Master_Agency_ID__c IN :sAgencyAccountId
                                                     and Master_Partner_ID__c != null 
                                                     and Master_Agency_ID__c != null];
        
        //Map<Id, Id> mapAgencyPartner = new Map<Id, Id>();
        Map<String, Id> mapAgencyPartner = new Map<String, Id>();
        if (listAgencyPartner != null && listAgencyPartner.size() > 0)
        {
            system.debug('ah::listAgencyPartner ' + listAgencyPartner);
            for (Agency_Partner__c AgencyPartner : listAgencyPartner)
            {
                    mapAgencyPartner.put(AgencyPartner.Master_Agency_ID__c + '' + AgencyPartner.Master_Partner_ID__c, AgencyPartner.Master_Partner_ID__c);
            }        
        }
        
        Map<ID,Schema.RecordTypeInfo> mapRT = Contact.sObjectType.getDescribe().getRecordTypeInfosById();
        for (Contact Con : trigger.new)
        {
            
            
            //Con.LSV_Master_Account_ID__c = null;
            Con.LSV_Master_ID_Agency_Branch__c = null;

                if (mapRT.get(Con.RecordTypeID).getName().containsIgnoreCase('Partner Rep') &&  mapBlueRepCS.containsKey(Con.AccountId) && con.Account_Record_Type_Name__c == 'Partner')
                {
                    for(Blue_Rep_Fields__c blueRepFieldCS : Blue_Rep_Fields__c.getAll().values())
                    {
                        Con.put(mapBlueRepCS.get(Con.AccountId), true);
                    }                        
                }
                else if (mapRT.get(Con.RecordTypeID).getName().containsIgnoreCase('Group Contact') && mapBlueRepCS.containsKey(con.Account_Partner_Id__c) && con.Account_Record_Type_Name__c == 'Master_Group')                     
                {
                    for(Blue_Rep_Fields__c blueRepFieldCS : Blue_Rep_Fields__c.getAll().values())
                    {
                        Con.put(mapBlueRepCS.get(con.Account_Partner_Id__c), true);
                    }                        
                }
                else if (mapRT.get(Con.RecordTypeID).getName().containsIgnoreCase('Group Contact') && mapBlueRepCS.containsKey(con.Account_Partner_Id__c) && con.Account_Record_Type_Name__c == 'Prospect')                     
                {
                    for(Blue_Rep_Fields__c blueRepFieldCS : Blue_Rep_Fields__c.getAll().values())
                    {
                        Con.put(mapBlueRepCS.get(con.Account_Partner_Id__c), true);
                     }                        
                }            
                else if (mapRT.get(Con.RecordTypeID).getName().containsIgnoreCase('Agent') && (Con.AccountId != null || Con.Agency_Branch__c != null))
                {
                    for(Blue_Rep_Fields__c blueRepFieldCS : Blue_Rep_Fields__c.getAll().values())
                    {
                        if (mapAgencyPartner.containsKey(con.AccountId + blueRepFieldCS.Partner_Id__c) && mapBlueRepCS.containsKey(mapAgencyPartner.get(con.AccountId + blueRepFieldCS.Partner_Id__c)))
                        {
                            Con.put(mapBlueRepCS.get(mapAgencyPartner.get(con.AccountId + blueRepFieldCS.Partner_Id__c)), true);
                        }
                        if (Con.Agency_Branch__c != null)
                        {
                            if (mapAgencyPartner.containsKey(con.Agency_Branch__c + blueRepFieldCS.Partner_Id__c) && mapBlueRepCS.containsKey(mapAgencyPartner.get(con.Agency_Branch__c + blueRepFieldCS.Partner_Id__c)))
                            {
                                Con.put(mapBlueRepCS.get(mapAgencyPartner.get(con.Agency_Branch__c + blueRepFieldCS.Partner_Id__c)), true);
                            }
                        }
                    }
                }

            if (Con.Agency_Branch__c != null && mapAgencyBranch.ContainsKey(Con.Agency_Branch__c)){
                Con.LSV_Master_ID_Agency_Branch__c = mapAgencyBranch.get(Con.Agency_Branch__c).LSV_Master_Id__c;
            }
            
            
            
            // [02/06/2019 - Mansoor - Case#5165] Now get the Account's LSV Master ID in the Contact's LSV Master Account Id
            if (Con.AccountId != null && mapAllAccounts.ContainsKey(Con.AccountId)){
                Con.LSV_Master_Account_ID__c = mapAllAccounts.get(Con.AccountId).LSV_Master_Id__c;
            }
        } 
    }
  
    
/*    
    if(Trigger.isBefore && Trigger.isInsert)
    {
        // Zaid Code Added Here
        list <Contact> lstContacts = new list <Contact>();
        list <Blue_Rep_Fields__c> lstBlueRep = new list <Blue_Rep_Fields__c>();
        list <Agency_Partner__c> lstAgencyPartner = New list <Agency_Partner__c>();
        list <Contact> listOfContactsToUpdate = new list <Contact>();
        
        Map <Id,Id> MapofContactAndAgency = new Map <Id,Id>(); 
        Map <Id,Id> MapofAgencyAndPartner = new Map <Id,Id>(); 
        Map <Id,Blue_Rep_Fields__c> MapofAccountIdAndBlueRepFields = new Map <Id,Blue_Rep_Fields__c>();
        Map<contact,Id>  MapofContactAndpartner = new Map<contact,Id>();
        Map<contact,Id>  MapofGroupAndMaterGrp = new Map<contact,Id>();
        Map<Id,Id>  mapOfGrpContactAndPartner = new Map<Id,Id>();
        Map<string, string> mapOfNameandPartnerIdAPIfield = new map<string, string>();
        
        // These lines are added by Zaid for agency branch modification
        Map <Id,Id> MapOfContactAndAgencyID = new Map <Id, Id>();
        Map <Id,Id> MapOfContactAndAgencyBranchId = new Map <Id, Id>();
        Map <Id,Id> MapOfAgencyBranchIdAndContactId = New Map <Id, Id>();
        // agency branch modification added lines end here
        map<Id, Id> mapOfBranchAgencyAndAgency = new map<Id,Id>();
        
        set<id> setOfAgencyBranchIds = new set<id>();
        set<id> setOfPartnerIds = new set<id>();
        set<Id> setOfContactId = new set<Id>();
        set<Id> setOfAgencyIdFromContact = new set<Id>();
        set<Id> setOfPartnersWithMasterGrp = new set<Id>();
        ID AgentRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        ID PartnerRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner Rep').getRecordTypeId();
        ID GroupRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeId();
        
        // 
        //Code Modification starts by Munazza Ahmed for Agency Branch contact insert 
        //
        //query all contacts that have branch agency
        for(contact con : [SELECT Id, Agency_Branch__c, AccountId 
                           FROM contact
                           WHERE Agency_Branch__c <> null])
        {
            setOfAgencyBranchIds.add(con.Agency_Branch__c);     //get the agency branch account ids
            mapOfBranchAgencyAndAgency.put(con.Agency_Branch__c, con.AccountId);        //get the agency and branch agency id
        }
        // 
        //Code Modification ends by Munazza Ahmed for Agency Branch contact insert 
        //
        // 
        //Code Modification starts by Zaid
        //
        for (Contact Con : trigger.new)
        {
            
            if(con.RecordtypeId == PartnerRtId)
            {
                MapofContactAndpartner.put(con,con.AccountId);
                setOfPartnerIds.add(con.AccountId);
            }
            if(con.RecordtypeId == GroupRtId)
            {
                MapofGroupAndMaterGrp.put(con,con.AccountId);
            }
            
            if(con.RecordtypeId == AgentRtId)
            {
                
                setOfContactId.add(con.Id);
                //lstContacts.add(con);
                setOfAgencyIdFromContact.add(con.AccountId);
                MapofContactAndAgency.put(con.Id,con.AccountId);
                
            
            }
        }
        
        
        for (Agency_Partner__c AgencyPartner : [select id,name, Master_Partner_ID__c, Master_Agency_ID__c from Agency_Partner__c where Master_Agency_ID__c IN: setOfAgencyIdFromContact OR Master_Agency_ID__c IN: mapOfBranchAgencyAndAgency.values()])
        {
            if(AgencyPartner.Master_Partner_ID__c != null && AgencyPartner.Master_Agency_ID__c != null)
            {
                MapofAgencyAndPartner.put(AgencyPartner.Master_Agency_ID__c, AgencyPartner.Master_Partner_ID__c);
                lstAgencyPartner.add(AgencyPartner);
            }
        }
        
        for(Blue_Rep_Fields__c blueRepFields :  [SELECT Name, API_Name_of_field__c, Partner_Id__c, Name_of_field__c FROM Blue_Rep_Fields__c])
        {
             if(blueRepFields.Partner_Id__c != null && blueRepFields.API_Name_of_field__c != null)
            {
                MapofAccountIdAndBlueRepFields.put(blueRepFields.Partner_Id__c,blueRepFields);
                lstBlueRep.add(blueRepFields);
                mapOfNameandPartnerIdAPIfield.put(blueRepFields.Name, blueRepFields.Partner_Id__c+'-'+blueRepFields.API_Name_of_field__c);  //added by Munazza
                }
        }
        
        for (Contact Cont : trigger.new)
        {
            if(cont.RecordtypeId == AgentRtId)
            {
               
                
                if(setOfAgencyBranchIds.contains(cont.AccountId) && lstAgencyPartner.size() > 0 && MapofAccountIdAndBlueRepFields.size()>0)
                {
                    //traverse for each custom setting record
                    for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                    {
                        //check for matching partner Id
                        if((mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == MapofAgencyAndPartner.get(mapOfBranchAgencyAndAgency.get(cont.AccountId)))
                        {
                           
                            string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                            Cont.put(fieldName,true); //mark the field true
                            
                        }
                        
                    }
                    
                }
                else
                {
                    //traverse for each custom setting record
                    for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                    {
                        //check for matching partner Id
                        if(mapOfNameandPartnerIdAPIfield.get(mapKey).substringbefore('-') == MapofAgencyAndPartner.get(cont.AccountId))
                        {
                           
                            string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                            Cont.put(fieldName,true); //mark the field true
                            
                        }
                        
                    }
                    
                }
            }
        }
        
        //update lstContacts;
        
        for(contact cont1 : [SELECT id,accountId, Agency_Branch__c, RecordtypeId 
                           FROM contact
                           WHERE accountId in: MapOfAgencyBranchIdAndContactId.keyset()])
        {
            if(cont1.RecordtypeId == AgentRtId)
            {
                Blue_Rep_Fields__c BRF1 = new Blue_Rep_Fields__c ();
                if(MapofAgencyAndPartner.get(cont1.AccountId) != null)
                {
                    // adding lines for multiple checkboxes
                    for (Blue_Rep_Fields__c Blue1 : lstBlueRep)
                    {
                        for (Agency_Partner__c AP1 : lstAgencyPartner)
                        {
                            if(MapofAccountIdAndBlueRepFields.get(AP1.Master_Partner_ID__c).Partner_Id__c != null)
                            {
                                if (Blue1.Partner_Id__c == MapofAccountIdAndBlueRepFields.get(MapofAgencyAndPartner.get(MapOfContactAndAgencyID.get(MapOfAgencyBranchIdAndContactId.get(cont1.AccountId)))).Partner_Id__c)
                                {
                                    string FieldName = '';
                                    FieldName = Blue1.API_Name_of_field__c;
                                    Cont1.put(FieldName,true);
                                }
                            }
                        }
                    }
                }
                lstContacts.add(cont1);
            }
        }
        
        // Zaid Code Ends Here
        
        //Munazza modification starts here
        for(account acc : [SELECT Id, Partner__c
                           FROM Account
                           WHERE Id IN: MapofGroupAndMaterGrp.values()])
        {
            for(contact groupCont : MapofGroupAndMaterGrp.keySet())
            {
                if(acc.Partner__c != null)
                {
                    mapOfGrpContactAndPartner.put(groupCont.Id,acc.Partner__c);
                    setOfPartnersWithMasterGrp.add(acc.Partner__c);
                }
            }
        }
        
        for(contact con : Trigger.new)
        {
            if(con.RecordtypeId == PartnerRtId)
            {
                //traverse for each custom setting record
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    //check for matching partner Id
                    if((mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == con.AccountId)
                    {
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        con.put(fieldName,true); //mark the field true
                    }
                    
                }
                
            }
            else if(con.RecordtypeId == GroupRtId)
            {
                //traverse for each custom setting record
                for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                {
                    //check for matching partner Id
                    if((mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == mapOfGrpContactAndPartner.get(con.Id))
                    {
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        con.put(fieldName,true); //mark the field true
                    }
                    
                }
                
            }
        }
        //Munazza modification ends
        
        
    }
    
 */   
    
    //if(Trigger.IsUpdate && Trigger.isBefore)
    if(Trigger.isUpdate && Trigger.isBefore && UserInfo.getUserType() != 'AutomatedProcess')
    {
        //Initializing variables
        set<string> setOfEtlFields = new set<string>(); 
        set<string> setOfNonEtlFields = new set<string>();
        
        //get current user's profile id
        Id profileId = userinfo.getProfileId();
        
        //get current user's profile name
        string currentProfile = [SELECT Id, Name
                                 FROM Profile
                                 WHERE Id =: profileId].Name;
        
        //traverse custom setting for etl and non-etl fields of contact
        for(ETL_and_Non_ETL_fields_for_Contact__c fields : [SELECT Id,ETL__c, Field_API_Name__c
                                                            FROM ETL_and_Non_ETL_fields_for_Contact__c])
        {
            //check if etl field and populate respective set
            if(fields.ETL__c == true)
            {
                setOfEtlFields.add(fields.Field_API_Name__c);
            }
            //check if non-etl field and populate respective set
            if(fields.ETL__c == false)
            {
                setOfNonEtlFields.add(fields.Field_API_Name__c);
            }
            
            
            
            for(string etlField : setOfEtlFields)
            {
                for(contact con : Trigger.new)
                {
                    if(con.Admin_System_Record__c == true)
                    {
                        if(currentProfile == Label.USAble_Sales_User_Profile_Name && Trigger.oldMap.get(con.Id).get(etlField) != Trigger.newMap.get(con.Id).get(etlField))
                        {
                            con.addError('You cannot update'+etlField);
                        }
                    }
                }
                    
            }
            for(string nonEtlField : setOfNonEtlFields)
            {
                for(contact con : Trigger.new)
                {
                    if(currentProfile == Label.USAble_EDI_User_Profile_Name && Trigger.oldMap.get(con.Id).get(nonEtlField) != Trigger.newMap.get(con.Id).get(nonEtlField))
                    {
                        con.addError('Sales fields cannot be updated');
                    }
                }
            }
        
        }
        
    }
    
    if(Trigger.IsUpdate && Trigger.isAfter)
    {
        //initializing variables to be used in trigger
        set<Id> setOfContactId = new set<Id>();
        set<Id> setOfContactAccIds = new set<Id>();
        set<Id> setOfAgencyBranchIds = new set<Id>();
        
        map<Id,Id> mapOfBranchAgencyAndAgency = new map<Id,Id>();
        map<Id,Id> MapofAgencyAndPartner = new map<Id,Id>();
        map<Id, Blue_Rep_Fields__c> MapofAccountIdAndBlueRepFields = new map<Id, Blue_Rep_Fields__c>();
        map<string, string> mapOfNameandPartnerIdAPIfield = new map<string, string>();
        
        list<Blue_Rep_Fields__c> lstBlueRep = new list<Blue_Rep_Fields__c>();
        list<Opportunity> listOfOpp = new list<Opportunity>();
        list<Contact> listOfContacts = new list<Contact>();
        list<Contact> lstContacts = new list<Contact>();
        list<Contact> lstContactsToReset = new list<Contact>();
        list<Agency_Partner__c> lstAgencyPartner = new list<Agency_Partner__c>();
        
        ID AgentRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        
        for(Contact cont : Trigger.new)
        {
            //check if hierarchy fields or territoty code is updated on contact
            if(cont.Partner_Rep_Manager__c !=  Trigger.oldMap.get(cont.Id).Partner_Rep_Manager__c  || cont.Partner_Rep_Director__c != Trigger.oldMap.get(cont.Id).Partner_Rep_Director__c  || cont.Partner_Rep_VP__c != Trigger.oldMap.get(cont.Id).Partner_Rep_VP__c || cont.Partner_Rep_Territory_Code__c !=  Trigger.oldMap.get(cont.Id).Partner_Rep_Territory_Code__c)
            {
                setOfContactId.add(cont.Id);
            }
            /*
            if(cont.RecordtypeId == AgentRtId && cont.Agency_Branch__c != Trigger.oldmap.get(cont.Id).Agency_Branch__c)
            {
                setOfAgencyBranchIds.add(cont.Agency_Branch__c);
                mapOfBranchAgencyAndAgency.put(cont.Agency_Branch__c, cont.AccountId);
            }
            */
        }
        /*
        //get the contacts with branch agency account
        if(setOfAgencyBranchIds.size() > 0)
        {
            for(contact con : [SELECT Id, AccountId, Agency_Branch__c
                               FROM Contact
                               WHERE AccountId IN: setOfAgencyBranchIds])
            {
                listOfContacts.add(con);
            }
        }
        */
        //storing agency partner record details
        if(mapOfBranchAgencyAndAgency.size()>0)
        {
            for (Agency_Partner__c AgencyPartner : [select id,name, Master_Partner_ID__c, Master_Agency_ID__c from Agency_Partner__c where Master_Agency_ID__c IN: mapOfBranchAgencyAndAgency.values()])
            {
                if(AgencyPartner.Master_Partner_ID__c != null && AgencyPartner.Master_Agency_ID__c != null)
                {
                    MapofAgencyAndPartner.put(AgencyPartner.Master_Agency_ID__c, AgencyPartner.Master_Partner_ID__c);
                    lstAgencyPartner.add(AgencyPartner);
                }
            }
        }
        //store the custom settings data
        for(Blue_Rep_Fields__c blueRepFields :  [SELECT Name, API_Name_of_field__c, Partner_Id__c, Name_of_field__c FROM Blue_Rep_Fields__c])
        {
             if(blueRepFields.Partner_Id__c != null && blueRepFields.API_Name_of_field__c != null)
            {
                MapofAccountIdAndBlueRepFields.put(blueRepFields.Partner_Id__c,blueRepFields);
                lstBlueRep.add(blueRepFields);
                mapOfNameandPartnerIdAPIfield.put(blueRepFields.Name, blueRepFields.Partner_Id__c+'-'+blueRepFields.API_Name_of_field__c);  //added by Munazza
            }
        }
        /*
        if(listOfContacts.size()>0)
        {
            for(contact cont : listOfContacts)
            {
                if(setOfAgencyBranchIds.contains(cont.AccountId) && lstAgencyPartner.size() > 0 && MapofAccountIdAndBlueRepFields.size()>0)
                {
                    //traverse for each custom setting record
                    for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                    {  
                        string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                        Cont.put(fieldName,false); //mark the field true
                        
                    }
                    
                }
                lstContactsToReset.add(cont);
            }
            if(lstContactsToReset.size()>0)
            {
                update lstContactsToReset;
            }
            
            for(contact cont : listOfContacts)
            {
                if(setOfAgencyBranchIds.contains(cont.AccountId) && lstAgencyPartner.size() > 0 && MapofAccountIdAndBlueRepFields.size()>0)
                {
                    //traverse for each custom setting record
                    for(string mapKey : mapOfNameandPartnerIdAPIfield.keyset())
                    {  
                        //check for matching partner Id
                        if((mapOfNameandPartnerIdAPIfield.get(mapKey)).substringbefore('-') == MapofAgencyAndPartner.get(mapOfBranchAgencyAndAgency.get(cont.AccountId)))
                        {
                            string fieldName = (mapOfNameandPartnerIdAPIfield.get(mapKey)).substringafter('-'); //get field api name
                            Cont.put(fieldName,true); //mark the field true
                        }
                    }
                    
                }
                lstContacts.add(cont);
            }
            if(lstContacts.size()>0)
            {
                update lstContacts;
            }
        }
        */
        if(setOfContactId.size()>0)
        {
            //get the accounts having blue rep with updated information
            for(account acc : [SELECT Id
                               FROM Account
                               WHERE Blue_Rep_Name__c IN: setOfContactId])
            {
                setOfContactAccIds.add(acc.Id);
            }
        }
        if(setOfContactAccIds.size()>0)
        {
            //get the opportunitites of related blue repcontact's accounts
            for(opportunity Opp : [SELECT Id, AccountId, StageName
                                   FROM opportunity
                                   WHERE AccountId IN: setOfContactAccIds])
            {
                listOfOpp.add(Opp);
            }
        }
        //update all the relevant opportunities with latest data
        if (listOfOpp != null && listOfOpp.size() > 0)
        {
            OpportunityTrgUtil.UpdateOpportunityReps(listOfOpp);
            OpportunityTrgUtil.ResetOpportunityTeam(listOfOpp);
        }
    }
    
}