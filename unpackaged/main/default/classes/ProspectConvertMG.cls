/*
Name        : ProspectConvertMG
Author      : Zaid Ali
Date        : 3/28/2017
Purpose     : To convert Prospect account into Master Group with reparenting
*/



Public without sharing class ProspectConvertMG {

    public static void ConverIntoMG(List <Account> lstAcc){
    
        system.debug('In Class for Conversion '+lstAcc);
        
        set <Id> setofAccountIds = new Set<Id>();
        List <Account> lstAccounts = new list <Account>();
        List <Opportunity> lstOpp = new List <Opportunity>();
        List <Opportunity> lstOppToUpdate = new List <Opportunity>();
        List <Contact> lstContacts = new List <Contact>();
        List <Contact> lstContactsToAdd = new List <Contact>();
        List <Task> lstEvents = new List <Task>();
        List <Task> lstEventsToAdd = new List <Task>();
        List <Id> lstAccIdToDelete = new List <Id>();
        
        Map <Id, Id> MapOfPIdAndMGId = new Map <Id, Id>(); 
        
        //Get all the Account and put them into respective lists
        For (Account AC : lstAcc)
        {
            setofAccountIds.add(AC.Id);
            MapOfPIdAndMGId.put(AC.Id,AC.Master_Group__c);
            lstAccounts.add(AC);
            lstAccIdToDelete.add(AC.Id);
        }
        
        // reparenting Opportunity Starts here
        
        // Query all the opportunities related to the account
        lstOpp = [Select Id, AccountId From Opportunity where AccountId IN : lstAcc];
        
        for(Opportunity Opp : lstOpp)
        {
            if (MapOfPIdAndMGId.containskey(Opp.AccountId))
            {
                Opp.AccountId = MapOfPIdAndMGId.get(Opp.AccountId); // reparent Opportunity
                lstOppToUpdate.add(Opp);
            }
        }
         update lstOppToUpdate;

        // reparenting Opportunity Ends here
        
        // reparenting Contacts Starts here
        lstContacts = [Select Id, AccountId from Contact where AccountId IN : lstAcc];
        for (Contact Con : lstContacts)
        {
            if (MapOfPIdAndMGId.containskey(Con.AccountId))
            {
                Con.AccountId = MapOfPIdAndMGId.get(Con.AccountId); //reparenting account here
                lstContactsToAdd.add(Con);
            }
        }
         update lstContactsToAdd;
        
        // reparenting Contacts ends here
        
        // creating chatter post data
        
        Id CurrentUserId = userinfo.getuserid();
        String CurrentUserFirstName = userinfo.getFirstName();
        if(CurrentUserFirstName == null)
        CurrentUserFirstName = '';
        
        String CurrentUserLastName = userinfo.getLastName(); 
        if(CurrentUserLastName == null)
        CurrentUserLastName = '';
        
        String CurrentUserName = CurrentUserFirstName +' '+ CurrentUserLastName;
        
        list <FeedItem> lstFeedItem = new List <FeedItem>();
        
        // creating chatter post for Master Group Accounts
        
        for (Account Acc : lstAccounts)
        {
            //Adding a Text post
            FeedItem post = new FeedItem();
            post.ParentId = MapOfPIdAndMGId.get(Acc.Id); //Accountid for mg account..
            post.Body = 'Prospect Account Merged :  '+Acc.name+'\r\n'+
            'Account Id : '+Acc.Id+'\r\n'+
            'Street : '+Acc.BillingStreet+'\r\n'+
            'BillingCity : '+Acc.BillingCity+'\r\n'+
            'Billing State : '+Acc.BillingState+'\r\n'+
            'Billing Country : '+Acc.BillingCountry+'\r\n'+
            'Billing Postal Code : '+Acc.BillingPostalCode+'\r\n'+
            'County : '+Acc.County_Name__c+'\r\n'+
            'Billing Postal Code : '+Acc.BillingPostalCode+'\r\n'+
            'Fax : '+Acc.Fax+'\r\n'+
            'Website : '+Acc.website+'\r\n'+
            'Key Client : '+Acc.Key_Client__c+'\r\n'+
            'Primary Agency : '+Acc.Primary_Agency_Name__c+'\r\n'+
            'SIC Code : '+Acc.Sic+'\r\n'+
            'Group Anniversary Date : '+Acc.Group_Anniversary_Date__c+'\r\n'+
            'Market Segment : '+Acc.Market_Segment__c+'\r\n'+
            'Sector : '+Acc.Sector__c+'\r\n'+
            'Account Owner : '+Acc.Account_Owner_Name__c+'\r\n'+
            'Blue Rep Name : '+Acc.Blue_Rep_Name_Text__c+'\r\n'+
            'Blue Rep Territory Code : '+Acc.Blue_Territory_Code__c+'\r\n'+
            'Master Group on Prospect Updated by : '+CurrentUserName+'\r\n'+
            'Master Group on Prospect Updated by Id : '+CurrentUserId+'\r\n';
            
            
            lstFeedItem.add(post);
           
        }
        insert lstFeedItem;
        
        ProspectConvertMG.processRecords(lstAccIdToDelete);
        
    }
    

    // This method is a future call which will delete the prospect account after reparenting
    @future
    public static void processRecords(List<ID> recordIds)
    {   
         // Get those records based on the IDs
         List<Account> accts = [SELECT Id, Name FROM Account WHERE Id IN :recordIds];
         // Delete records
         delete accts;
    }


}