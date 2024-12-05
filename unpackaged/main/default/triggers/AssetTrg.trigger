/*
Name        : AssetTrg
Author      : Munazza Ahmed
Date        : 8/1/2016
Purpose : Trigger on Asset with following functionality:
          - Create a relationship of master and agency accounts in junction object if it doesn't exist already on insert and update of asset.
 
*/
trigger AssetTrg on Asset (after insert, after update)
{
    //initializing variables to be used in trigger
    set<string> setOfKey = new set<string>();
    list<Agency_MasterGroups__c> listOfAgencyMaster = new list<Agency_MasterGroups__c>();
    set<string> setOfAgencyMasterKey = new set<string>();
    if(Trigger.isInsert && Trigger.isAfter)
    {
        
        for(Asset ast : Trigger.new)
        {
            //check condition of broker agency field not being empty and relationship not existing already
            if(ast.Broker_Agency__c != null)
            {
                //create a record in junction object for this relationship
                Agency_MasterGroups__c agencyMaster = new Agency_MasterGroups__c();
                agencyMaster.Master_Group__c = ast.AccountId;
                agencyMaster.Broker_Agency__c = ast.Broker_Agency__c;
                agencyMaster.Agency_Master_Key__c = ast.AccountId+'-'+ast.Broker_Agency__c;
                if(!setOfAgencyMasterKey.contains(agencyMaster.Agency_Master_Key__c))
                {
                    listOfAgencyMaster.add(agencyMaster);
                }
                setOfAgencyMasterKey.add(agencyMaster.Agency_Master_Key__c);
            }
                
        }
        if(listOfAgencyMaster.size() > 0)
        {
            //update or insert the list of junction object records
            upsert listOfAgencyMaster Agency_Master_Key__c ;
        }
        
    }
    
    if(Trigger.isUpdate && Trigger.isAfter)
    {
        for(Asset ast : Trigger.new)
        {
            //check condition of broker agency field not being empty and relationship not existing already
            if(ast.Broker_Agency__c != null)
            {
                //create a record in junction object for this relationship
                Agency_MasterGroups__c agencyMaster = new Agency_MasterGroups__c();
                agencyMaster.Master_Group__c = ast.AccountId;
                agencyMaster.Broker_Agency__c = ast.Broker_Agency__c;
                agencyMaster.Agency_Master_Key__c = ast.AccountId+'-'+ast.Broker_Agency__c;
                
                if(!setOfAgencyMasterKey.contains(agencyMaster.Agency_Master_Key__c))
                {
                    listOfAgencyMaster.add(agencyMaster);
                }
                setOfAgencyMasterKey.add(agencyMaster.Agency_Master_Key__c);
            }
                
        }
        if(listOfAgencyMaster.size()>0)
        {
            //update or insert the list of junction object records
            upsert listOfAgencyMaster Agency_Master_Key__c;
        }
    }
}