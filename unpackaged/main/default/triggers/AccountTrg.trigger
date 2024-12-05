/*
Name        : AccountTrg
Author      : Munazza Ahmed
Date        : 8/2/2016
Purpose : Trigger on Account with following functionality:
            - When an account is inserted, check for relevant fields and exceptions for account team creation and create an account team.
            - Partner rep update on account affects opportunity partner rep info 
            - Update Asset anniversary date when Master group account anniversary date gets changed
            - If Partner on Master Group or Partner account is present in custom setting then relevant region field updated. 
              For example, Master Group or Partner account has Blue Cross Blue shield Florida as a Partner and 
              Blue Cross Blue Shield Floria exists in custom setting then Florida region is set to true on that Master Group or Partner.
            - When Agency's region fields are upated, region fields on Agents will also be synced.            
            
Modified by : Zaid  
Purpose : to add functionality to reflect partner rep fields update on opportunities 
 
*/
trigger AccountTrg on Account (before insert, before update, after insert, after update)
{
    //initializing variables to be used in trigger
    List<Account> listOfAccounts = new List<Account>();
    
        if(Trigger.isInsert && Trigger.isAfter)
    {
        //getting master recordtype Id from utlity class method
        string recordtypeName = 'Master Group';
        Id MasterGroupId = AccountTrgUtil.GetAccountRecordtypeId(recordtypeName);
        string recordtypeName2 = 'Prospect';
        Id ProspectId = AccountTrgUtil.GetAccountRecordtypeId(recordtypeName2);
        
        //list of accounts to be passed in order to create account team
        for(Account acc : Trigger.new)
        {
            //check if account is master group
            if(acc.RecordTypeId == MasterGroupId || acc.RecordTypeId == ProspectId)
            {
                listOfAccounts.add(acc);
                
            }
        }
        AccountTrgUtil.AutoCreateAccountTeam(listOfAccounts);   //create team for account using method in utility class
        
        //ZA Mofification Starts
        //adding line to add partner rep update on opportunity functionality
        set <Id> setofAccountId = new set <Id>();
        
        List <Opportunity> lstOpportunity = new list <Opportunity>();
        for (Account acc : Trigger.new)
        {
            //Account AccToCheck = Trigger.oldMap.get(acc.id);
            //if(AccToCheck.Blue_Rep_Name__c != acc.Blue_Rep_Name__c )
            setofAccountId.add(acc.id);
        }
        
        lstOpportunity = [select id,name,stagename,AccountId from opportunity where AccountId IN : setofAccountId ];
        

        try
        {
            OpportunityTrgUtil.UpdateOpportunityReps(lstOpportunity);
            OpportunityTrgUtil.ResetOpportunityTeam(lstOpportunity);
        }
        catch (Exception ex)
        {
            for (Account acct : Trigger.new) 
            {
                acct.addError(ex.getMessage());
            }
        }        
        
        //partner rep update functionality ends here
        //ZA Modification ends
    }
    if(Trigger.isUpdate && Trigger.isBefore)
    {
        //initializing variables to be used in trigger
        List<Account> lstOfAccounts = new List<Account>();
        set <Id> setofAccountId = new set <Id>();
      
        
        //getting master recordtype Id from utlity class method
        string recordtypeName = 'Master Group';
        Id MasterGroupId = AccountTrgUtil.GetAccountRecordtypeId(recordtypeName);
        
        //list of accounts to be perform an account team reset
        for(Account acc : Trigger.new)
        {
            //check if account is master group
            if(acc.RecordTypeId == MasterGroupId && acc.Reset_Account_Team__c == true)
            {
                lstOfAccounts.add(acc);
                setofAccountId.add(acc.id);
            }
            
            system.debug('ah::acc.RecordTypeId ' + acc.RecordTypeId);
            system.debug('ah::acc.Reset_Account_Team__c ' + acc.Reset_Account_Team__c );            
        }
        AccountTrgUtil.ClearAccountTeam(lstOfAccounts);     //clear the existing account team using method in utility class
        

        system.debug('ah::listOfAccounts 1 ' + lstOfAccounts);
        AccountTrgUtil.AutoCreateAccountTeam(lstOfAccounts);   //create team for account using method in utility class
        
        //Opp. team reset
        /*
        if (setofAccountId.size() > 0) {
            List <Opportunity> lstOpportunity = new list <Opportunity>();
            lstOpportunity = [select id,name,stagename,AccountId from opportunity where AccountId IN : setofAccountId ];
            try
            {
                OpportunityTrgUtil.UpdateOpportunityReps(lstOpportunity);
            }
            catch (Exception ex)
            {
                for (Account acct : Trigger.new) 
                {
                    acct.addError(ex.getMessage());
                }
            }
        }     
        */
        //Opp. team reset ends
        
        //AccountTrgUtil.UpdateResetAccountTeamCheckBox(lstOfAccounts);   //revert the checkbox to false using method in utility class
        
    }
    
    if(Trigger.isUpdate && Trigger.isAfter)
    {
        system.debug('ah:log working');
        //ZA Modification starts
        //adding line to add partner rep update on opportunity functionality
        set <Id> setofAccountId = new set <Id>();
        set <Id> setofAccountIdResetAT = new set <Id>();
        
        List <Account> lstAccMG = new list <Account>();
        Id ProspectId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        //partner rep update functionality ends here
        //initializing list of accounts contain accounts where Master Group Anniversry date is changed
        List<Account> lstOfAccountswithAnvDateChange = new List<Account>(); //added by zaid to update asset aniv date on assets functionality
        string recordtypeName = 'Master Group';
        Id MasterGroupId = AccountTrgUtil.GetAccountRecordtypeId(recordtypeName);
        
        List <Opportunity> lstOpportunity = new list <Opportunity>();
        for (Account acc : Trigger.new)
        {
            Account AccToCheck = Trigger.oldMap.get(acc.id);
            //if(AccToCheck.Blue_Rep_Name__c != acc.Blue_Rep_Name__c || (acc.Reset_Account_Team__c == true && AccToCheck.Reset_Account_Team__c != acc.Reset_Account_Team__c)){
            
            //set to hold account IDs for which there is blue rep name updated
            if(AccToCheck.Blue_Rep_Name__c != acc.Blue_Rep_Name__c)
            {
                setofAccountId.add(acc.id);
            }
            
            //set to hold account IDs if there is reset account team ticked
            if (acc.Reset_Account_Team__c == true && AccToCheck.Reset_Account_Team__c != acc.Reset_Account_Team__c)
            {
                setofAccountIdResetAT.add(acc.id);
            }
            //added by zaid to update asset aniv date on assets functionality
            //check if account is master group and group anniversery date is change
            if(acc.RecordTypeId == MasterGroupId && Trigger.oldMap.get(acc.id).Group_Anniversary_Date__c != Trigger.newMap.get(acc.id).Group_Anniversary_Date__c )
            {
                lstOfAccountswithAnvDateChange.add(acc);
            }
            // zaid added code ends here
        }
        
        //list to update partner rep on opportunity
        lstOpportunity = [select id,name,stagename,AccountId from opportunity where AccountId IN : setofAccountId ];
        
        //list to reset opportunity team
        List<Opportunity> lstOpportunityResetAT = [select id,name,stagename,AccountId from opportunity where AccountId IN : setofAccountIdResetAT ];
    
        try
        {
            //update partner rep on opportunity
            if (lstOpportunity != null && lstOpportunity.size() > 0)
            {
                OpportunityTrgUtil.UpdateOpportunityReps(lstOpportunity); 
            }
            
            //reset opportunity team
            if (lstOpportunityResetAT != null && lstOpportunityResetAT.size() > 0)
            {
                OpportunityTrgUtil.ResetOpportunityTeam(lstOpportunityResetAT);
            }            
        }
        catch (Exception ex)
        {
            for (Account acct : Trigger.new) 
            {
                acct.addError(ex.getMessage());
            }
        }
        
        AccountTrgUtil.AssetAnivDate(lstOfAccountswithAnvDateChange);
        
        List <Account> listofAcctIds = new List<Account>();
        List<Account> listAcctForKeyClientAlert = new List<Account>();
        
        //ZA Modification ends
        for (Account acco : Trigger.New)
        {
            if (acco.Master_Group__c != Trigger.oldMap.get(acco.Id).Master_Group__c && acco.recordtypeid == ProspectId &&  acco.Master_Group__c != null)
            {
                lstAccMg.add(acco);
            }
            
            //check if account is master group
            if(acco.RecordTypeId == MasterGroupId && acco.Reset_Account_Team__c == true)
            {
                listofAcctIds.add(acco);
            }            
            
            //account is master group and key client field has changed then build a list to send email alert to
            if (acco.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId() && 
                Trigger.oldMap.get(acco.Id).Key_Client__c != acco.Key_Client__c )
            {
                listAcctForKeyClientAlert.add(acco);
            }
        }
        
        if (listofAcctIds != null && listofAcctIds.size() > 0)
        {
            //Reset_Account_Team__c to false
            AccountTrgUtil.UpdateResetAccountTeamCheckBox(listofAcctIds); 
        }
        
        if(lstAccMg.size() > 0)
        ProspectConvertMG.ConverIntoMG(lstAccMg);
        
        if (listAcctForKeyClientAlert != null && listAcctForKeyClientAlert.size() > 0)
        {
            //send email alert to public group members to tell them these are master groups whose key client field has changed
            AccountTrgUtil.SendKeyClientChangeAlert(listAcctForKeyClientAlert);
        }
   }

    //generic changes: will refined later; just a skeleton code    
    if((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore)
    {
                Id MasterGroupReportTypeId = AccountTrgUtil.GetAccountRecordtypeId('Master Group');
                Id PartnerReportTypeId = AccountTrgUtil.GetAccountRecordtypeId('Prospect');
                Id AgencyReportTypeId = AccountTrgUtil.GetAccountRecordtypeId('Agency');

                Map<Id, String> mapBlueRepCS = new Map<Id, String>();
                Set<Id> setPartnerIds = new Set<Id>();
                string strRegions = '';

                for(Blue_Rep_Fields__c blueRepFieldCS : Blue_Rep_Fields__c.getAll().values())
                {
                    mapBlueRepCS.put(blueRepFieldCS.Partner_Id__c, blueRepFieldCS.API_Name_of_field__c);
                    setPartnerIds.add(blueRepFieldCS.Partner_Id__c);
                    strRegions += blueRepFieldCS.API_Name_of_field__c + ',';
                }

                Set<Id> setAcctIds = new Set<Id>();
                for(Account acc : Trigger.new)
                {
                    if (acc.Id != null)
                    {
                        setAcctIds.add(acc.Id);    
                    }
                    
                }
                system.debug('ah::setAcctIds ' + setAcctIds);
                
                List<Contact> listCont;
                if (setAcctIds != null && setAcctIds.size() > 0)
                {
                    String strQeuryAgencyBranch = 'select ' + strRegions + ' Id, Agency_Branch__c from contact where Agency_Branch__c in :setAcctIds limit 50000' ;
                    system.debug('ah::strQeuryAgencyBranch ' + strQeuryAgencyBranch);
                    listCont = Database.query(strQeuryAgencyBranch);                      
                }
                  


                Map<Id, List<Contact>> mapCont = new Map<Id, List<Contact>>();
                if (listCont != null && listCont.size() > 0)
                {
                    for (Contact con : listCont)
                    {
                        if (mapCont.containsKey(con.Agency_Branch__c))
                        {
                            List<Contact> listContact = mapCont.get(con.Agency_Branch__c);
                            listContact.add(con);
                            mapCont.put(con.Agency_Branch__c, listContact);    
                        }
                        else
                        {
                            mapCont.put(con.Agency_Branch__c, new List<Contact>{con});
                        }
                    }
                }


                for(Account acc : Trigger.new)
                {
                    if ((acc.RecordTypeId == MasterGroupReportTypeId || acc.RecordTypeId == PartnerReportTypeId)  && acc.Partner__c != null && mapBlueRepCS.containsKey(acc.Partner__c) )
                    {
                        acc.put(mapBlueRepCS.get(acc.Partner__c), true);
                    }
                    else if ((acc.RecordTypeId == MasterGroupReportTypeId || acc.RecordTypeId == PartnerReportTypeId) && !setPartnerIds.contains(acc.Partner__c))
                    {
                        for(Blue_Rep_Fields__c blueRepFieldCS : Blue_Rep_Fields__c.getAll().values())
                        {
                            //describe value of each region fields from account object, 
                            //if found one with true set it to false and break out of loop
                            if (acc.get(blueRepFieldCS.API_Name_of_field__c) == true)
                            {
                                acc.put(blueRepFieldCS.API_Name_of_field__c, false);
                                break;
                            }
                        }
                    }

                    //below code block will execute whenever region field is updated
                    if (Trigger.isUpdate)
                    {
                        if (acc.RecordTypeId == AgencyReportTypeId)
                        {
                            List<Contact> listAgencyBranch = new List<Contact>();
                            Map<String, Contact> mapCon = new Map<String, Contact>();

                            for(Blue_Rep_Fields__c blueRepFieldCS : Blue_Rep_Fields__c.getAll().values())
                            {
                                if (mapCont != null & mapCont.size() > 0)
                                {
                                    if (acc.get(blueRepFieldCS.API_Name_of_field__c) != trigger.oldMap.get(acc.Id).get(blueRepFieldCS.API_Name_of_field__c) && mapCont.containsKey(acc.Id))
                                    {
                                        //update region on agency branch to true
                                        List<Contact> listCon = mapCont.get(acc.Id);

                                        if  (listCon != null && listCon.size() > 0)
                                        {
                                            for (Contact con : listCon)
                                            {
                                                String strCon = con.Id; 
                                                if (mapCon.containsKey(strCon))
                                                {
                                                    Contact c = mapCon.get(strCon);
                                                   if (acc.get(blueRepFieldCS.API_Name_of_field__c) == true)
                                                    {
                                                        c.put(blueRepFieldCS.API_Name_of_field__c, true);
                                                    }
                                                    mapCon.put(strCon, c);
                                                }
                                                else
                                                {
                                                   if (acc.get(blueRepFieldCS.API_Name_of_field__c) == true)
                                                    {
                                                        con.put(blueRepFieldCS.API_Name_of_field__c, true);
                                                    }
                                                    mapCon.put(strCon, con);                                        
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            if (mapCon != null && mapCon.size() > 0)
                            {
                                system.debug('ah::mapCon ' + mapCon);
                                try
                                {
                                    update mapCon.values();
                                }
                                catch (Exception ex)
                                {
                                    for (Contact c : mapCon.values()) 
                                    {
                                        c.addError('Error occured. Kindly check this error or contact your Salesforce Administrator ' + ex.getMessage());
                                    }
                                }
                            }                    
                        }
                    }
                }
    }

}