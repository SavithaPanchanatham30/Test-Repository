/*
Name        : OpportunityTrgUtil
Author      : Munazza Ahmed
Date        : 7/21/2016
Purpose : Utility class for Opportunity Trigger.
          - Return asset record list that is to be created.
modified by : Zaid
purpose : to add update partner rep fields on opportunity functionality added a new function
*/
public with sharing class OpportunityTrgUtil
{
    //variable to ensure single trigger of after update on workflow update
    public static  boolean firstRun = true;
    public static void InsertAssetForClosedOpp(set<Id> l_setOfOppIds, map<id,opportunity> l_mapOfOppIdAndOpp)
    {
        //initializing variables to be used in trigger
        set<id> setOfPrdId = new set<id>();
        
        list<Asset> listOfAsset = new list<Asset>();
        list<OpportunityLineItem> listOfOLI = new list<OpportunityLineItem>();
        list<OpportunityLineItem> listOfConvertedOli = new list<OpportunityLineItem>();
        
        map<id,Product2> mapOfOliIdandPrd = new map<id,Product2>();
        map<id,OpportunityLineItem> mapOfprdIdandOLI = new map<id,OpportunityLineItem>();
        //system.debug('Opp Util '+l_setOfOppIds.size());
        
        if (l_setOfOppIds.size() > 0)
        {
            for(OpportunityLineItem oli: [SELECT id, Line_Item_Stage__c, Product2Id, Renewal_Date__c, Competitor_Name__c,
                                          Next_Renewal_Date__c, opportunityId, Rate_Guarantee__c, Broker_Agency__c, Agent__c
                                          FROM OpportunityLineItem
                                          WHERE opportunityid in: l_setOfOppIds
                                          AND Product2Id <> null
                                          AND Competitor_Name__c <> null
                                          AND Next_Renewal_Date__c <> null
                                          AND (Line_Item_Stage__c = 'Closed Lost - Quoted' OR Line_Item_Stage__c = 'Closed Lost - Not Quoted')
                                          ]) 
            {
                listOfOLI.add(oli);    //store opportunity line item meeting appropriate conditions
                setOfPrdId.add(oli.Product2Id);    //store product id for relevant line item
                mapOfprdIdandOLI.put(oli.product2id,oli);    //store product id against line item
                system.debug('oli -> '+oli);
            }
            // Line_Item_Stage__c IN ('Closed Lost - Quoted', 'Closed Lost - Not Quoted')
            //get products in map for later assignment of product name to newly created asset name
            for(Product2 prd : [SELECT id, name
                                FROM Product2
                                WHERE Id in: setOfPrdId])
            {
                mapOfOliIdandPrd.put(mapOfprdIdandOLI.get(prd.id).id,prd);
            }
            
            system.debug('listOfOLI.size() '+listOfOLI.size()+'mapOfOliIdandPrd.size() '+mapOfOliIdandPrd.size()+'l_mapOfOppIdAndOpp.size() '+l_mapOfOppIdAndOpp.size());
            //get the list of assets to be inserted from utility class method
            if(listOfOLI.size()>0 && mapOfOliIdandPrd.size()>0 && l_mapOfOppIdAndOpp.size()>0)
            {
                for(OpportunityLineItem oli : listOfOLI)
                {
                    //create asset and populate relevant fields
                    asset ast = new asset();
                    ast.Name = mapOfOliIdandPrd.get(oli.id).Name;
                    ast.AccountId = l_mapOfOppIdAndOpp.get(oli.OpportunityId).AccountId;
                    ast.Product2Id = oli.Product2Id;
                    ast.Carrier__c = oli.Competitor_Name__c;
                    ast.Renewal_Date__c = oli.Next_Renewal_Date__c;
                    ast.Rate_Guarantee__c = oli.Rate_Guarantee__c;
                    ast.Broker_Agency__c = oli.Broker_Agency__c;
                    ast.Broker_Agent__c = oli.Agent__c;
                    listOfAsset.add(ast);
                }
                
            }
            if(listOfAsset.size() > 0)
            {
                insert listOfAsset;    //insert asset
                
            }
        } 
    }
    
    //Modification starts
    public static void UpdateOpportunityReps (List <Opportunity> lstOppToChange){
        
        Map <Id,Id> MapofOppAndAccount = new Map <Id,Id>();
        Map <Id,Account> MapofIdAndAccount = new Map <Id,Account>();
        Map <Id,Contact> MapofIdAndContact = new Map <Id,Contact>();
        Set <Id> setofOppOwnerId = new Set <Id>();
        Set <Id> setofAccountId = new Set <Id>();
        Set <Id> setofOppId = new Set <Id>();
        Set <Id> setofContactIds = new Set <Id>();
        List <Account> lstAccount = new list <Account>();
        List <Opportunity> lstOpportunity = new list <Opportunity>();
        Set <Id> SetOfOPPPId = new Set <Id>();
        for (Opportunity OPPP : lstOppToChange)
        {
            SetOfOPPPId.add(OPPP.Id);
        }
        List <Opportunity> lstOpp = new List <Opportunity>([Select OwnerId, id, name, StageName, AccountId , Partner_Rep__c, Partner_Rep_Territory_Code__c, Partner_Rep_Manager__c, Partner_Rep_Director__c, Partner_Rep_VP__c, isclosed from Opportunity where ID IN : SetOfOPPPId]);
        
        // iterate on list of opportunities
        for(Opportunity OP : lstOpp)
        {
            
            //if(OP.StageName == 'In Process' || OP.StageName == 'New')
            if(OP.IsClosed == false){
                setofAccountId.add(OP.AccountId);
                setofOppId.add(OP.Id);
                setofOppOwnerId.add(OP.OwnerId);
            }
        }

        // get list of accounts from opp list
		if (setofAccountId != null && setofAccountId.size() > 0)
        {
        	lstAccount = [select id, name, RecordTypeId,Blue_Rep_Name__c from Account where Id IN : setofAccountId];            
        }

        
        // storing accound id and account in a map
        if (lstAccount != null && lstAccount.size() > 0)
        {
            for (Account Acc : lstAccount)
            {
                MapofIdAndAccount.put(Acc.Id, Acc);
            }
            
        }
        //system.debug('Accounts ' +MapofIdAndAccount);
        Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        Id ProspectRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        //system.debug('RecordTypeId ' +RecordTypeId);
        
        // iterate over list of oppty to get account blue rep name
        for(Opportunity OPP : lstOpp)
        {
            system.debug('TempAccount '+MapofIdAndAccount.get(OPP.AccountId));
            Account TempAccount = MapofIdAndAccount.get(OPP.AccountId);
            //If((OPP.StageName == 'In Process' || OPP.StageName == 'New'  ) && (TempAccount.RecordTypeId == RecordTypeId || TempAccount.RecordTypeId == ProspectRecordTypeId ))
            If((OPP.IsClosed == False  ) && (TempAccount.RecordTypeId == RecordTypeId || TempAccount.RecordTypeId == ProspectRecordTypeId ))
            {
                //MapOfAccountAndContact.put(TempAccount,TempAccount.Blue_Rep_Name__c);
                setofContactIds.add(TempAccount.Blue_Rep_Name__c);
            }
        }
        
        List <Contact> lstContact = new List <Contact>();
        if (setofContactIds != null && setofContactIds.size() > 0)
        {
        	lstContact = [select id, name, Partner_Rep_Territory_Code__c, Partner_Rep_Manager__c, Partner_Rep_Director__c, Partner_Rep_VP__c from Contact where Id IN : setofContactIds ];    
        }
        
        //system.debug('lstContact ' +lstContact);
        
        if (lstContact != null && lstContact.size() > 0)
        {
        	for (Contact Con : lstContact)
            {
                MapofIdAndContact.put(Con.Id, Con);
            }
            
        }
        
        if (setofOppId != null && setofOppId.size() > 0)
        {
        	for (Opportunity OPPO : [Select id, name, StageName, AccountId , Partner_Rep__c, Partner_Rep_Territory_Code__c, Partner_Rep_Manager__c, Partner_Rep_Director__c, Partner_Rep_VP__c, isclosed from Opportunity where ID IN : setofOppId])
            {
                if(MapofIdAndAccount.get(OPPO.AccountId) != null)
                {
                Account TAccount = MapofIdAndAccount.get(OPPO.AccountId);
                
                if( MapofIdAndContact.get(TAccount.Blue_Rep_Name__c) != null )
                {
                    Contact Cont = MapofIdAndContact.get(TAccount.Blue_Rep_Name__c);
                    system.debug('Contact Id Here '+MapofIdAndContact.get(TAccount.Blue_Rep_Name__c));
                    //If((OPPO.StageName == 'In Process' || OPPO.StageName == 'New' ) && (TAccount.RecordTypeId == RecordTypeId || TAccount.RecordTypeId == ProspectRecordTypeId))
                    If((OPPO.IsClosed == False ) && (TAccount.RecordTypeId == RecordTypeId || TAccount.RecordTypeId == ProspectRecordTypeId))
                    {
                        /* if(OPPO.Partner_Rep__c != TAccount.Blue_Rep_Name__c 
                        && OPPO.Partner_Rep_Territory_Code__c != Cont.Partner_Rep_Territory_Code__c 
                        && OPPO.Partner_Rep_Manager__c != Cont.Partner_Rep_Manager__c 
                        && OPPO.Partner_Rep_Director__c != Cont.Partner_Rep_Director__c
                        && OPPO.Partner_Rep_VP__c != Cont.Partner_Rep_VP__c) */
                        //{
                            OPPO.Partner_Rep__c = TAccount.Blue_Rep_Name__c;
                            OPPO.Partner_Rep_Territory_Code__c = Cont.Partner_Rep_Territory_Code__c ;
                            OPPO.Partner_Rep_Manager__c = Cont.Partner_Rep_Manager__c;
                            OPPO.Partner_Rep_Director__c = Cont.Partner_Rep_Director__c;
                            OPPO.Partner_Rep_VP__c = Cont.Partner_Rep_VP__c;
                            lstOpportunity.add(OPPO);
                        //}
                    }
                 }
                }
            }
            
        }
        
        try
        {
            if (lstOpportunity.size() > 0)
            {
                Update lstOpportunity;
            }
        }
        catch (Exception ex)
        {
            if (ex.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'))
            {
                throw new OpportunityException(' You have insufficient privileges to update the open opportunity associated to this account. ');
            }
            else
            {
                throw new OpportunityException(' Error occured. Kindly check this error or contact your Salesforce Administrator ' + ex.getMessage());
            }           
        }
        
        
    
		
    }
    

	public static void ResetOpportunityTeam (List <Opportunity> lstOppToChange)
	{
        system.debug('ah::lstOppToChange ' + lstOppToChange);
        
        Set <Id> SetOfOPPPId = new Set <Id>();
        Set <Id> setofOppOwnerId = new Set <Id>();
        
        for (Opportunity Oppt : lstOppToChange)
        {
            SetOfOPPPId.add(Oppt.Id);
        }        
        
        List <Opportunity> lstOpp = new List <Opportunity>([Select OwnerId, id, name, StageName, AccountId, isclosed from Opportunity where ID IN : SetOfOPPPId]);
        
       if (lstOpp != null && lstOpp.size() > 0)
       {
        	for (Opportunity OPPP : lstOpp)
            {
                if(OPPP.IsClosed == false)
                {
                    setofOppOwnerId.add(OPPP.OwnerId);
                }
            }
       }
        
        // opp team is missing logic 
        Map<Id, List<UserTeamMember>> mapDefaultOppTeamDetail = new Map<Id, List<UserTeamMember>>();
        List<UserTeamMember> lstTeamMembers = null;
        
        //creating map of owner from userteamember.This will be used for team member role during opp. team addition in team.
        for (UserTeamMember utm : [select OpportunityAccessLevel, UserId, TeamMemberRole, OwnerId from UserTeamMember where OwnerId=:setofOppOwnerId])
        {
            if (!mapDefaultOppTeamDetail.containsKey(utm.OwnerId)){
                lstTeamMembers = new List<UserTeamMember>();
                lstTeamMembers.add(utm);
            } else {
                lstTeamMembers = mapDefaultOppTeamDetail.get(utm.OwnerId);
                lstTeamMembers.add(utm);
            }
            
            mapDefaultOppTeamDetail.put(utm.OwnerId, lstTeamMembers);               
        }        

        //creating map of opportunity team members
        Map<String, String> mapOTM = new Map<String, String>();
        
        for (OpportunityTeamMember otm : [select Id, TeamMemberRole, UserId, OpportunityId from OpportunityTeamMember where OpportunityId in :SetOfOPPPId])
        {
            String strKey = otm.OpportunityId + '-' + otm.UserId;
            if (!mapOTM.containsKey(strKey))
            {
                mapOTM.put(strKey, otm.TeamMemberRole);                    
            }
        }
        
        //managing list of opp. team member not in the above map
        List<OpportunityTeamMember> lstOTM = new List<OpportunityTeamMember>();
        for (Opportunity opt : [select Id, ownerId from opportunity where Id IN: SetOfOPPPId])
        {
            if (mapDefaultOppTeamDetail.containsKey(opt.ownerId)) {
                for (UserTeamMember usrTeamMember : mapDefaultOppTeamDetail.get(opt.ownerId)){
                    if (!mapOTM.containsKey(opt.Id+'-'+usrTeamMember.UserId)){
                        OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId = opt.Id, UserId = usrTeamMember.UserId, TeamMemberRole = usrTeamMember.TeamMemberRole, OpportunityAccessLevel=usrTeamMember.OpportunityAccessLevel);
                        lstOTM.add(otm);
                    }
                }
            }
        }
        
        if (lstOTM.size() > 0)
        {
            insert lstOTM;
        }
	}
    
    public class OpportunityException extends Exception {}
}