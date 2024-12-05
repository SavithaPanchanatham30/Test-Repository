/*
Name        : OpportunityTrg
Author      : Munazza Ahmed
Date        : 7/20/2016
Purpose : Trigger on Oppotunity with following functionality:
           - Auto create asset record for closed lost opportunity line items when opportunity is closed won or closed lost.
Modified by: Zaid
Date: 8/15/2016

Modified by: Munazza Ahmed
Modification Date: 9/4/2016
Purpose:
        - Update blue partner region field on opportunity based on the partner region of master account the opportunity is related to.
*/
trigger OpportunityTrg on Opportunity (before insert, after insert, after update)
{
    //initializing variables to be used in trigger
    set<id> setOfOppIds = new set<id>();
    set<id> setOfPrdId = new set<id>();
    set<Id> setOfPartnerIds = new set<Id>();
    
    list<Asset> listOfAsset = new list<Asset>();
    list<OpportunityLineItem> listOfOLI = new list<OpportunityLineItem>();
    list<OpportunityLineItem> listOfConvertedOli = new list<OpportunityLineItem>();
    list<Opportunity> listOfOppToUpdate = new list<Opportunity>();
    list<Blue_Rep_Fields__c> listOfPartnerState = new list<Blue_Rep_Fields__c>();
    
    map<id,Product2> mapOfOliIdandPrd = new map<id,Product2>();
    map<id, Opportunity> mapOfOppIdAndOpp = new map<id, Opportunity>();
    map<id,OpportunityLineItem> mapOfprdIdandOLI = new map<id,OpportunityLineItem>();
    map<Id,string> mapOfPartnerIdandName = new map<Id,string>();
    map<opportunity,Id> mapOfOppandMasterGrpAccId = new map<opportunity,Id>();
    map<Id,Id> MapOfMasterGrpIdAndPartnerIds = new map<Id,Id>();
    
    //Modification starts
    if (Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            OpportunityTrgUtil.UpdateOpportunityReps(Trigger.new); // This line is added by zaid to check opportunity update function
            OpportunityTrgUtil.ResetOpportunityTeam(Trigger.new);
        }
    }
    //Modification ends
    
    //Modification by Munazza Ahmed for Blue Partner Region populate
    if(Trigger.isInsert && Trigger.isBefore)
    {
        //fetch fields from custom settings containing partner id and field api name
        for(Blue_Rep_Fields__c blueRepFields :  [SELECT API_Name_of_field__c, Partner_Id__c, Name_of_field__c
                                                FROM Blue_Rep_Fields__c])
        {
            listOfPartnerState.add(blueRepFields);  //all records for blue rep fields custom setting
            mapOfPartnerIdandName.put(blueRepFields.Partner_Id__c, blueRepFields.Name_of_field__c); //map of partner Id & name
            setOfPartnerIds.add(blueRepFields.Partner_Id__c);
        } 
        //get related master group account for opportunity
        for(opportunity opp : Trigger.new)
        {
            mapOfOppandMasterGrpAccId.put(opp,opp.AccountId);
        }
        //get partner account ids for related master group accounts
        for(account acc : [SELECT id, partner__c FROM account WHERE Id IN: mapOfOppandMasterGrpAccId.values()])
        {
            MapOfMasterGrpIdAndPartnerIds.put(acc.Id,acc.Partner__c);
        }
        //populate blue partner region field for opportunity with relevant region
        for(opportunity keyValue : mapOfOppandMasterGrpAccId.keyset())
        {
            for(string partnerId : mapOfPartnerIdandName.keyset())
            {
                //check if related partner state is present in custom setting
                if(MapOfMasterGrpIdAndPartnerIds.get(mapOfOppandMasterGrpAccId.get(keyValue)) == partnerId)
                {
                    keyValue.Blue_Rep_Region__c = mapOfPartnerIdandName.get(partnerId);    //populate region field with partner name
                }
            }
        }
    }
    //Modification ends
    
    
    
    if(Trigger.isUpdate && Trigger.isAfter)
    { 
        for(Opportunity opp : Trigger.new)
        {
            if((opp.StageName != Trigger.oldMap.get(opp.Id).StageName && opp.StageName == 'Closed Won') 
                || (opp.StageName != Trigger.oldMap.get(opp.Id).StageName && opp.StageName == 'Closed Lost') && OpportunityTrgUtil.firstRun)
            {
                setOfOppIds.add(opp.id);    //store opportunity id if it is closed
                mapOfOppIdAndOpp.put(opp.id,opp);    //store opportunity if it is closed
                OpportunityTrgUtil.firstRun = false;    //ensure single trigger of after update on workflow update
                
            }
        } 
        if(setOfOppIds.size()>0 && mapOfOppIdAndOpp.size()>0)
        {
            OpportunityTrgUtil.InsertAssetForClosedOpp(setOfOppIds,mapOfOppIdAndOpp);    //call method from utility class to create asset
        }
    } 
}