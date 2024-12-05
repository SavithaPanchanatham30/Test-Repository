/*
Name        : AccountTrgUtil
Author      : Munazza Ahmed
Date        : 8/2/2016
Purpose : Utility class for Account Trigger with following functionality:
          - check for conditions in account assignment object for creation of account team
          - check for exceptions from custom settings to stop creation of particular account team role
          - create account team along with account share for account records meeting all appropriate conditions.
 
*/

public without sharing class AccountTrgUtil
{   
    
    //get record type id for master group record type on account
    public static id GetAccountRecordtypeId(string recordTypeName)
    {
        
        id RecordTypeId;
        /*
        for(Recordtype rt : [SELECT Name, Id
                             FROM Recordtype
                             WHERE Sobjecttype = 'Account'])
        if(rt.Name == recordTypeName)
        {
            RecordTypeId = rt.Id;
        }
        */
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordtypename).getRecordTypeId();
        return RecordTypeId;
    }
    //method that creates account team for the list of accounts passed
    public static void AutoCreateAccountTeam(list<Account> listOfAccounts)
    {
        
        //initializing variables to be used in method
        set<Id> setOfActiveUsers = new set<Id>();
        
        List<string> lstStringValues;
        List<AccountTeamMember> acctMembers = new List<AccountTeamMember>();
        List<AccountTeamMember> accMembersToInsert = new list<AccountTeamMember>();
        List<AccountShare> accShareToInsert = new List<AccountShare>();
        List<Account_Team_Assignment__c> listOfAssignments = new List<Account_Team_Assignment__c>();
        
        map<string,list<string>> mapOfTerritoryAssignment = new map<string,list<string>>();
        map<string,list<string>> mapOfCountyAssignment= new map<string,list<string>>();
        map<AccountTeamMember,Account> mapOfMemberAndAcc = new map<AccountTeamMember,Account>();
        
        //store list of active users in set
        for(User memberUser : [SELECT Id,IsActive
                                   FROM User
                                   WHERE IsActive = true])
        {
            setOfActiveUsers.add(memberUser.Id);
        }
        //list to store exception conditions from custom settings
        list<Account_Team_Assignment_Exception__c> listOfExceptionCondition = [SELECT Account_field__c,Active__c,Do_Not_Assign__c,
                                                                       Partner_Id__c, Team_Role__c, Value__c
                                                                       FROM Account_Team_Assignment_Exception__c
                                                                       WHERE Active__c = True AND Do_Not_Assign__c = True];
        Map<String, Id> mapReturnPartner = new Map<String, Id>();
        //populate maps with appropriate assignment method and values from account assignment custom object
        for(Account_Team_Assignment__c ats : [SELECT id, Blue_Partner__c, BC_Rep_Code__c,
                                                         Group_Segment__c, County__c, User__c, 
                                                         Team_Role__c,Assignment_Method__c
                                                         FROM Account_Team_Assignment__c])
        {
            listOfAssignments.add(ats);
            lstStringValues = new List<string>();
            
            mapReturnPartner.put(ats.User__c + '-' +  ats.Team_Role__c, ats.Blue_Partner__c);
            
            if(ats.Assignment_Method__c == 'Blue Territory' && ats.Blue_Partner__c != null && ats.BC_Rep_Code__c != null && ats.Team_Role__c != null && ats.User__c != null)
            {   
                //creating list of string
                if (mapOfTerritoryAssignment.containsKey(ats.Blue_Partner__c+'-'+ats.BC_Rep_Code__c)){
                    lstStringValues = mapOfTerritoryAssignment.get(ats.Blue_Partner__c+'-'+ats.BC_Rep_Code__c);
                } 
                lstStringValues.add(ats.User__c+'-'+ats.Team_Role__c);
                //maintaining map
                mapOfTerritoryAssignment.put(ats.Blue_Partner__c+'-'+ats.BC_Rep_Code__c,lstStringValues);
            }
            else if(ats.Assignment_Method__c == 'Market Segment & County' && ats.Blue_Partner__c != null && ats.Group_Segment__c != null && ats.County__c != null && ats.Team_Role__c != null && ats.User__c != null)
            {
                //creating list of string
                if (mapOfCountyAssignment.containsKey(ats.Blue_Partner__c+'-'+ats.Group_Segment__c+'-'+ats.County__c)){
                    lstStringValues = mapOfCountyAssignment.get(ats.Blue_Partner__c+'-'+ats.Group_Segment__c+'-'+ats.County__c);
                } 
                lstStringValues.add(ats.User__c+'-'+ats.Team_Role__c);
                mapOfCountyAssignment.put(ats.Blue_Partner__c+'-'+ats.Group_Segment__c+'-'+ats.County__c,lstStringValues);
            }
        }
        
        //create account team member for the account record matching account assignment record
        AccountTeamMember accMember;
        
       
        
        for(account acc : listOfAccounts)
        {
            for(Account_Team_Assignment__c ats : listOfAssignments)
            {
                if(ats.Assignment_Method__c == 'Blue Territory' && ats.BC_Rep_Code__c == acc.Blue_Territory_Code__c
                && ats.Blue_Partner__c == acc.Partner__c)
                {
                    if(mapOfTerritoryAssignment.containsKey(acc.Partner__c+'-'+acc.Blue_Territory_Code__c)){
                        //iteration on list string return from map
                        for(string value: mapOfTerritoryAssignment.get(acc.Partner__c+'-'+acc.Blue_Territory_Code__c))
                        {
                                accMember = new AccountTeamMember();
                                accMember.AccountId = acc.Id;
                                accMember.TeamMemberRole = value.substringAfter('-');   //trim and store the role
                                accMember.UserId = value.substringBefore('-');  //trim and store the User Id
                                acctMembers.add(accMember);
                                
                        }   
                    }
                }
                else if(ats.Assignment_Method__c == 'Market Segment & County' && ats.Blue_Partner__c == acc.Partner__c && ats.Group_Segment__c == acc.market_segment__c && ats.County__c == acc.County__c)
                {
                    if (mapOfCountyAssignment.containsKey(acc.Partner__c+'-'+acc.market_segment__c+'-'+acc.County__c)){
                        //iteration on list string return from map
                        for(string value: mapOfCountyAssignment.get(acc.Partner__c+'-'+acc.market_segment__c+'-'+acc.County__c))
                        {
                                accMember = new AccountTeamMember();
                                accMember.AccountId = acc.Id;
                                accMember.TeamMemberRole = value.substringAfter('-');   //trim and store the role
                                accMember.UserId = value.substringBefore('-');      //trim and store the User Id
                                acctMembers.add(accMember);                               
                        }   
                    }
                }
            } 
        }
        
        
        //store account team member against it relevant account in a map
        for(AccountTeamMember atm : acctMembers)
        {
            for(account acc: listOfAccounts)
            {
                if(atm.AccountId == acc.Id)
                {
                    mapOfMemberAndAcc.put(atm,acc);
                }
            }
        } 
        
        //check for exception and eliminate account member records falling here
        if(listOfExceptionCondition.size()>0 && mapOfMemberAndAcc.size()>0)
        {
            set<boolean> setOfinsertInTeam;
            //loop on list of account members to be checked
            for(AccountTeamMember accMem : mapOfMemberAndAcc.keyset())
            {
                setOfinsertInTeam = new set<boolean>();
                //nested loop for exceptions to be checked on each member
                for(Account_Team_Assignment_Exception__c ex : listOfExceptionCondition )
                {
                    string fieldName = ex.Account_field__c;
                    if(!((mapOfMemberAndAcc.get(accMem)).get(fieldName) == ex.Value__c && mapOfMemberAndAcc.get(accMem).Partner__c == ex.Partner_Id__c && accMem.TeamMemberRole == ex.Team_Role__c))
                    {
                        //account member passes the exception
                        setOfinsertInTeam.add(true);
                    }
                    else
                    {
                        //account member donot pass the exception
                        setOfinsertInTeam.add(false);
                    }
                }
                //checking if the account member pass the exception and assigned user is active
                if(!setOfinsertInTeam.contains(false) && setOfActiveUsers.contains(accMem.UserId))
                {
                    //list of filtered account members
                    accMembersToInsert.add(accMem);
                }
            }
        }
        else
        {
            for(AccountTeamMember atm : acctMembers)
            {
                accMembersToInsert.add(atm);
            }
        }
        
        if(accMembersToInsert.size()>0)
        {
            //create account share for each account member to be inserted
            for(AccountTeamMember accountMember : accMembersToInsert)
            {
                AccountShare accSharingRule = new AccountShare();
                accSharingRule.AccountId = accountMember.AccountId;
                accSharingRule.OpportunityAccessLevel = 'Edit';     //edit access to opportunities for team member
                //accSharingRule.CaseAccessLevel = 'Read';        //Read access to cases for team member
                accSharingRule.CaseAccessLevel = 'None';        //Read access to cases for team member changed access from read to none by zaid so that it can be private.
                accSharingRule.AccountAccessLevel = 'Edit';     //edit access to account for team member
                accSharingRule.UserOrGroupId = accountMember.UserId;
                accShareToInsert.add(accSharingRule);
                
            }
        }
        
        //if (Trigger.isUpdate)
        //{
            List<Account_Team_Assignment_Additional_Rule__c> listATAAR = [select Blue_Partner_Id__c, Group_Size_Lower_Limit__c, Group_Size_Upper_Limit__c, 
                                                                           Have_Asset__c, Key_Client__c, Override__c, Role__c, User_Id__c 
                                                                           from Account_Team_Assignment_Additional_Rule__c where Active__c = true
                                                                           and User_Id__c in :setOfActiveUsers];
            
            List<Asset> listAssets = [select Id, Product2.Family, AccountId from Asset where AccountId in :listOfAccounts and Active_Formula__c = true];
            Map<Id, List<String>> mapAsset = new Map<Id, List<String>>();
            
            system.debug('ah::listATAAR ' + listATAAR);
            system.debug('ah::listAssets ' + listAssets);
            
            
            if (listAssets != null && listAssets.size() > 0)
            {
                for (Asset asst : listAssets)
                {
                    if(mapAsset.containsKey(asst.AccountId)) 
                    {
                        List<String> listAssetName = mapAsset.get(asst.AccountId);
                        listAssetName.add(asst.Product2.Family);
                        mapAsset.put(asst.AccountId, listAssetName);
                    } 
                    else 
                    {
                        mapAsset.put(asst.AccountId, new List<String> { asst.Product2.Family });
                    }
                }
            }
            
            system.debug('ah::mapAsset ' + mapAsset);
            system.debug('ah::listOfAccounts ' + listOfAccounts);
            
            // map to hold filtered ATA additional rules records to create account team member
            Map<Id, Account_Team_Assignment_Additional_Rule__c> mapUsersToInsert = new Map<Id, Account_Team_Assignment_Additional_Rule__c>();
            
            List<AccountTeamMember> listATM = new List<AccountTeamMember>();
            
            Map <String, Schema.SObjectField> accountFieldMap = Account.sObjectType.getDescribe().fields.getMap();
            
            if (listATAAR != null && listATAAR.size() > 0 && listOfAccounts != null && listOfAccounts.size() > 0)
            {   
                Map<Id, List<Account_Team_Assignment_Exception__c>> mapATAException = new Map<Id, List<Account_Team_Assignment_Exception__c>>();
                Map<String, Account_Team_Assignment_Exception__c> mapException = new Map<String, Account_Team_Assignment_Exception__c>();
                
                
                if (listOfExceptionCondition != null && listOfExceptionCondition.size() > 0)
                {
                    for(Account_Team_Assignment_Exception__c atae : listOfExceptionCondition) 
                    {
                        if(mapATAException.containsKey(atae.Partner_Id__c)) 
                        {
                            List<Account_Team_Assignment_Exception__c> ataExp = mapATAException.get(atae.Partner_Id__c);
                            ataExp.add(atae);
                            mapATAException.put(atae.Partner_Id__c, ataExp);
                        } 
                        else 
                        {
                            mapATAException.put(atae.Partner_Id__c, new List<Account_Team_Assignment_Exception__c> { atae });
                        }
                        
                        mapException.put(atae.Partner_Id__c + '-' + atae.Team_Role__c + '-' + atae.Account_field__c + '-' + atae.Value__c, atae);                    
                    }                
                }
                
                Map<String, AccountTeamMember> mapAccMembersToInsert = new Map<String, AccountTeamMember>();
                
                if (accMembersToInsert != null && accMembersToInsert.size() > 0)
                {
                    for (AccountTeamMember atmem : accMembersToInsert)
                    {
                        mapAccMembersToInsert.put(atmem.AccountId + '-' + atmem.UserId, atmem);
                    }                
                }
    
                
                for (Account_Team_Assignment_Additional_Rule__c ataar : listATAAR)    
                {
                    for (Account acct : listOfAccounts)
                    {
                        if (ataar.Blue_Partner_Id__c == acct.Partner__c && ataar.Key_Client__c == acct.Key_Client__c
                            && (acct.LSV_Group_Size__c >= ataar.Group_Size_Lower_Limit__c && acct.LSV_Group_Size__c <= ataar.Group_Size_Upper_Limit__c))
                        {
                            if (mapAsset.containsKey(acct.Id))
                            {
                                List<String> lstAsst = mapAsset.get(acct.Id);
                                List<String> lstHaveAssets = ataar.Have_Asset__c.split('\\|');
                                
                                system.debug('ah::lstAsst ' + lstAsst);
                                system.debug('ah::lstHaveAssets ' + lstHaveAssets);
                                
                                if (lstHaveAssets != null && lstHaveAssets.size() > 0)
                                {
                                    for (String str : lstHaveAssets)
                                    {
                                        //check to see whether account is having assets defined in custom setting
                                        if (lstAsst.contains(str))
                                        {
                                            system.debug('ah::check exception');
                                            if (mapATAException.containsKey(ataar.Blue_Partner_Id__c))
                                            {
                                                system.debug('ah::exception exists');
                                                
                                                boolean bolCreate = true;
                                                //check any exceptions
                                                for(Account_Team_Assignment_Exception__c ex : mapATAException.get(ataar.Blue_Partner_Id__c) )
                                                {
                                                    string fieldName = ex.Account_field__c;
    
                                                    
                                                    system.debug('ah::acct.Partner__c ' + acct.Partner__c);
                                                    system.debug('ah::ataar.Role__c ' + ataar.Role__c);
                                                    system.debug('ah::acct.get(fieldName) ' + acct.get(fieldName));
                                                    
                                                    
                                                    system.debug('ah::check... ' + mapException.containsKey(acct.Partner__c + '-' + ataar.Role__c + '-' + fieldName + '-' + acct.get(fieldName)));
                                                    
                                                    if (mapException.containsKey(acct.Partner__c + '-' + ataar.Role__c + '-' + fieldName + '-' + acct.get(fieldName))) {
                                                           bolCreate = false;
                                                           break;
                                                    }
                                                }   
                                                
                                                if (bolCreate)
                                                {
                                                    system.debug('ah::accMembersToInsert ' + accMembersToInsert);
                                                    
                                                    //account member passes the exception
                                                    if (accMembersToInsert != null && accMembersToInsert.size() > 0)
                                                    {
                                                        for (integer atm=0; atm<accMembersToInsert.size(); atm++)
                                                        {
                                                            if(mapAccMembersToInsert.containsKey(acct.Id + '-' + ataar.User_Id__c))
                                                            {
                                                                if (ataar.Override__c == true)
                                                                {
                                                                    system.debug('ah::1 ');
                                                                    for (integer at=0; at<accMembersToInsert.size(); at++)
                                                                    {
                                                                        if (mapAccMembersToInsert.get(acct.Id + '-' + ataar.User_Id__c).AccountId == accMembersToInsert[at].AccountId 
                                                                            && mapAccMembersToInsert.get(acct.Id + '-' + ataar.User_Id__c).UserId == accMembersToInsert[at].UserId 
                                                                            && acct.Partner__c == ataar.Blue_Partner_Id__c)
                                                                        {
                                                                            accMembersToInsert.remove(at);
                                                                            
                                                                            //update team member from ataar record
                                                                            AccountTeamMember acctTeamMember = new AccountTeamMember();
                                                                            acctTeamMember.AccountId = acct.Id;
                                                                            acctTeamMember.TeamMemberRole = ataar.Role__c;   
                                                                            acctTeamMember.UserId = ataar.User_Id__c;  
                                                                            listATM.add(acctTeamMember);                                                                            
                                                                        }
                                                                    }
                                                                }                                                                
                                                                
                                                            }
                                                            else
                                                            {
                                                                system.debug('ah::2 ');
                                                                AccountTeamMember acctTeamMember = new AccountTeamMember();
                                                                acctTeamMember.AccountId = acct.Id;
                                                                acctTeamMember.TeamMemberRole = ataar.Role__c;   
                                                                acctTeamMember.UserId = ataar.User_Id__c;  
                                                                listATM.add(acctTeamMember);                                                    
                                                            }                                                            
                                                        }
                                                    }
                                                    
                                                    else
                                                    {
                                                        system.debug('ah::3 ');
                                                        AccountTeamMember acctTeamMember = new AccountTeamMember();
                                                        acctTeamMember.AccountId = acct.Id;
                                                        acctTeamMember.TeamMemberRole = ataar.Role__c;   
                                                        acctTeamMember.UserId = ataar.User_Id__c;  
                                                        listATM.add(acctTeamMember);                                                    
                                                    }
                                                    //break;
                                                }                                  
                                            }
                                            else
                                            {
                                                system.debug('ah::NO exception exists');
                                                        if (accMembersToInsert != null && accMembersToInsert.size() > 0)
                                                        //if(mapAccMembersToInsert.containsKey(acct.Id + '-' + ataar.User_Id__c))
                                                        {
                                                            system.debug('ah::ATA custom object has records ' + accMembersToInsert);
                                                                if(mapAccMembersToInsert.containsKey(acct.Id + '-' + ataar.User_Id__c))
                                                                {
                                                                    system.debug('ah::101 ');
                                                                    if (ataar.Override__c == true)
                                                                    {
                                                                        system.debug('ah::102 ');
                                                                        for (integer atm=0; atm<accMembersToInsert.size(); atm++)
                                                                        {
                                                                            if (mapAccMembersToInsert.get(acct.Id + '-' + ataar.User_Id__c).AccountId == accMembersToInsert[atm].AccountId 
                                                                                && mapAccMembersToInsert.get(acct.Id + '-' + ataar.User_Id__c).UserId == accMembersToInsert[atm].UserId 
                                                                                && acct.Partner__c == ataar.Blue_Partner_Id__c)
                                                                            {
                                                                                accMembersToInsert.remove(atm);
                                                                                //update team member from ataar record
                                                                                
                                                                                AccountTeamMember acctTeamMember = new AccountTeamMember();
                                                                                acctTeamMember.AccountId = acct.Id;
                                                                                acctTeamMember.TeamMemberRole = ataar.Role__c;   
                                                                                acctTeamMember.UserId = ataar.User_Id__c;  
                                                                                listATM.add(acctTeamMember);                                                                            
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                else
                                                                {
    
                                                                    AccountTeamMember acctTeamMember = new AccountTeamMember();
                                                                    acctTeamMember.AccountId = acct.Id;   
                                                                    acctTeamMember.TeamMemberRole = ataar.Role__c;
                                                                    acctTeamMember.UserId = ataar.User_Id__c; 
                                                                    listATM.add(acctTeamMember);
                                                                }
                                                               
                                                            ///} //end of for
                                                        }
                                                        else
                                                        {
                                                            system.debug('ah::44 ');
                                                            AccountTeamMember acctTeamMember = new AccountTeamMember();
                                                            acctTeamMember.AccountId = acct.Id;
                                                            acctTeamMember.TeamMemberRole = ataar.Role__c;   
                                                            acctTeamMember.UserId = ataar.User_Id__c;
                                                            listATM.add(acctTeamMember);                                                    
                                                        }                                           
                                                ///////////////////////////////////////////////////
                                            }
                                        }
                                    }
                                }
                            }                        
                        }
                    }
                }
            }
            
            if (listATM != null && listATM.size() > 0 )
            {
                system.debug('ah::listATM ' + listATM);
                
                Set<AccountTeamMember> setATM = new Set<AccountTeamMember>();
                setATM.addAll(listATM);
                
                accMembersToInsert.addAll(setATM);  
                
                //create account share for each account member to be inserted
                for(AccountTeamMember accountMember : setATM)
                {
                    AccountShare accSharingRule = new AccountShare();
                    accSharingRule.AccountId = accountMember.AccountId;
                    accSharingRule.OpportunityAccessLevel = 'Edit';     //edit access to opportunities for team member
                    accSharingRule.CaseAccessLevel = 'None';        //Set to none so that it can be private.
                    accSharingRule.ContactAccessLevel = 'None';        //Set to none so that it can be private.
                    accSharingRule.AccountAccessLevel = 'Edit';     //edit access to account for team member
                    accSharingRule.UserOrGroupId = accountMember.UserId;
                    accShareToInsert.add(accSharingRule);
                    
                }
            }
           
            //insert account members
            if(accMembersToInsert.size()>0)
            {
                insert accMembersToInsert;
            }
            
            //insert account share
            if(accShareToInsert.size()>0)
            {
                insert accShareToInsert;
            }
        //}
    } 
    //method that clears account team for list of accounts passed
    public static void ClearAccountTeam(list<Account> listOfAccounts)
    {
        List <AccountTeamMember> listOfAccTeamMembers = new list <AccountTeamMember>();
        List <AccountTeamMember> listOfAccTeamMembersTemp = new list <AccountTeamMember>();
        List <AccountShare> listOfAccTeamShareMembers = new list <AccountShare>();
        List <AccountShare> listOfAccTeamShareMembersTemp = new list <AccountShare>();
        Map <Id,Id> MapofAccountAndOwner = new Map <Id,Id>(); //added by zaid
        
        set<id> setOfAccIds = new set<id>();
        
        for(Account acc : listOfAccounts)
        {
            setOfAccIds.add(acc.Id);
            MapofAccountAndOwner.put(acc.id,acc.ownerId); //added by zaid
        }
        //fetching list of account team members to delete
        listOfAccTeamMembersTemp = [SELECT Id, UserId, Accountid
                                FROM AccountTeamMember
                                WHERE AccountId IN: setOfAccIds];
                                
        Set<Id> setOfATMAccountIds = new Set<Id>();
        
       if (listOfAccTeamMembersTemp != null && listOfAccTeamMembersTemp.size() > 0)
       {
            For (AccountTeamMember ATM : listOfAccTeamMembersTemp )
            {
                If(ATM.userid != MapofAccountAndOwner.get(ATM.accountid))
                {
                    listOfAccTeamMembers.add(ATM);
                    system.debug('ATM '+ATM);
                    
                    setOfATMAccountIds.add(ATM.accountid);
                }
            }           
       }

        system.debug('listOfAccTeamMembers '+listOfAccTeamMembers);
        
        if (setOfATMAccountIds != null && setOfATMAccountIds.size() > 0)
        {
            //fetching list of account share members to delete 
            listOfAccTeamShareMembersTemp = [SELECT Id,accountid, userorgroupid
                                         FROM AccountShare
                                         WHERE AccountId IN: setOfATMAccountIds];
                                        //WHERE AccountId IN: setOfAccIds];
                        
        }

        if (listOfAccTeamShareMembersTemp != null && listOfAccTeamShareMembersTemp.size() > 0)
        {
            For (AccountShare AccShare : listOfAccTeamShareMembersTemp)
            {
                If(AccShare.userorgroupid != MapofAccountAndOwner.get(AccShare.accountid))
                {
                    listOfAccTeamShareMembers.add(AccShare);
                    system.debug('adding listOfAccTeamShareMembers ' + AccShare);
                }
            }            
        }

        system.debug('listOfAccTeamShareMembers '+listOfAccTeamShareMembers);
        /* commented by Zaid as it was giving error for deleting account owner from account share
        listOfAccTeamShareMembers = [SELECT Id
                                     FROM AccountShare
                                     WHERE AccountId IN: setOfAccIds];
        */                    
        
        system.debug('ah::listOfAccTeamMembers ' + listOfAccTeamMembers);
        
        //delete list of account team members
        if(listOfAccTeamMembers != null && listOfAccTeamMembers.size()>0)
        {
            delete listOfAccTeamMembers;
        }        //delete list of account share members
        if(listOfAccTeamShareMembers != null && listOfAccTeamShareMembers.size()>0)
        {
            delete listOfAccTeamShareMembers;
        }
    }
    //method that updates reset account team checkbox for list of accounts passed
    public static void UpdateResetAccountTeamCheckBox(list<Account> listOfAccounts)
    {
        //query records to avoid exception "System.FinalException: Record is read-only"
        List<Account> listAcct = [select Id, Reset_Account_Team__c from Account where Id in :listOfAccounts];
        List<Account> listAccount = new List<Account>();
        
        for(Account acc : listAcct)
        {
            acc.Reset_Account_Team__c = false;      //revert to false
            listAccount.add(acc);
        }
        
        if (listAccount != null && listAccount.size() > 0)
        {
            update listAccount;
        }
    }
    
    //added by zaid to update asset aniv date on assets functionality
    //method to update assets' anniversery date from account 
    public static void AssetAnivDate(list<Account> lstOfAccountswithAnvDateChange)
    {
    
    list <Asset> lstAssetsToUpdate  = new list <Asset>();
    list <Asset> lstAssets = new list <Asset>([select id, accountid, Master_Group_Anniversary_Date__c, Renewal_Date__c, Active_Formula__c from asset where AccountId IN : lstOfAccountswithAnvDateChange]);
    Map <Id, Asset> MapOfAccountAndAsset = new Map <Id, Asset>();
        
        For(Account acc : lstOfAccountswithAnvDateChange)
        {
            for(Asset asst : lstAssets)
            {
                if(asst.AccountId == acc.id)
                {
                    //if(asst.Renewal_Date__c >= acc.Group_Anniversary_Date__c && asst.Active_Formula__c == true)
                    if(asst.Active_Formula__c == true)
                    {
                        asst.Master_Group_Anniversary_Date__c = acc.Group_Anniversary_Date__c;
                        lstAssetsToUpdate.add(asst);
                    }
                }
            }
        }
        
        If(lstAssetsToUpdate.size() > 0 )
        update lstAssetsToUpdate;
    }
    
    public static void SendKeyClientChangeAlert(list<Account> listOfAccounts)
    {
        List<GroupMember> listGroupMember = [select Id, UserOrGroupId From GroupMember where Group.Name = 'Key Client Alert Recipients'];
        
        String[] alertRecipients = new String[]{};
        
        Set<Id> setUserIds = new Set<Id>();
        if (listGroupMember != null && listGroupMember.size() > 0)
        {
            for (GroupMember gm : listGroupMember)
            {
                setUserIds.add(gm.UserOrGroupId);
            }
            
            List<User> listUsers = [select Id, Email from User where Id in :setUserIds];  
            
            if (listUsers != null && listUsers.size() > 0)
            {
                for (User usr : listUsers)
                {
                    alertRecipients.add(usr.Email);    
                }
            }
        }
        
        system.debug('ah::alertRecipients ' + alertRecipients);
        system.debug('ah::listOfAccounts ' + listOfAccounts);
        
        if (alertRecipients != null && alertRecipients.size() > 0 && listOfAccounts != null && listOfAccounts.size() > 0)
        {
            User usrSenderInfo = [select FirstName, LastName from User where id =:Userinfo.getuserid()];
            String orgURL = System.URL.getSalesforceBaseUrl().toExternalForm();
            
            //List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();
            
            String strBody = 'Dear System Admin,<br/><br/>' + 
                             'Please set the Reset Account Team field to TRUE on the master group account(s).<br/><br/>' +
                             'Please click on the following link(s) to view a particular account in Salesforce.<br/><br/>';
            
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setBccSender(false); 
            message.toAddresses = alertRecipients;
            message.subject = 'Reset Account Team of Master Group(s)';            
            
            for (Account act : listOfAccounts)
            {
                strBody +=       act.Name + '<br/><a href="' + orgURL + '/' + act.ID + '">' + orgURL + '/' + act.ID + '</a><br/><br/>' ;
            }
            
            strBody += '<br/><br/>Regards,<br/>' + usrSenderInfo.FirstName + ' ' + usrSenderInfo.LastName;
                
            message.setHtmlBody(strBody);
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            //listEmails.add(message);
            //
            system.debug('ah::calling sendEmail ' + messages);
            //Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            try
            {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                system.debug('ah::results ' + results);
                
                if (results[0].success) 
                {
                    System.debug('The email was sent successfully.');
                } else 
                {
                    System.debug('The email failed to send: ' + results[0].errors[0].message);
                }                     
            }
            catch (Exception ex)
            {
                for (Account acct : listOfAccounts)
                {
                    if (ex.getMessage().contains('NO_MASS_MAIL_PERMISSION'))
                    {
                        acct.addError( new AccountException(' Salesforce email deliverability is off. Email alert may not be sent to respective admin upon updating \'Key Client\' on Master Group. Please contact your Salesforce Administrator.'));
                    }
                    else
                    {
                        acct.addError( new AccountException(' Error occured. Kindly check this error or contact your Salesforce Administrator ' + ex.getMessage()));
                    }                    
                }
           
            }            
           
        }
    }
    
     public class AccountException extends Exception {}
}