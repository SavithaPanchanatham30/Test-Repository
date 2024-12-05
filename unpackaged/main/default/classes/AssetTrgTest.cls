/*
Name        : AssetTrgTest
Author      : Munazza Ahmed
Date        : 8/5/2016
Purpose : Test class for coverage of trigger on Asset.
*/

@isTest
private class AssetTrgTest
{  
    public static testMethod void assetRelationshipTest()
    {
        //insert account
        Account acc_agency = new Account();
        acc_agency = USAbleUtility.CreateAgencyAccount(); //account returned from utility class
        insert acc_agency;
        
        //insert account
        Account acc_master = new Account();
        acc_master = USAbleUtility.CreateMasterGroupAccount(); //account returned from utility class
        insert acc_master;
        
        //insert agency master record
        Agency_MasterGroups__c agencyMaster = new Agency_MasterGroups__c();
        agencyMaster = USAbleUtility.CreateAgencyMasterGroup(acc_agency,acc_master);
        insert agencyMaster;
        
        //insert account
        Account acc_master_b = new Account();
        acc_master_b = USAbleUtility.CreateMasterGroupAccount(); //account returned from utility class
        insert acc_master_b;
        
        //insert account
        Account acc_agency_b = new Account();
        acc_agency_b = USAbleUtility.CreateAgencyAccount(); //account returned from utility class
        insert acc_agency_b;
        
        //insert Product
        Product2 prd = new Product2();
        prd = USAbleUtility.CreateProuct(); //Product returned from utility class
        insert prd;
        
        //create asset
        asset ast = new asset();
        ast.name = 'Test Asset';
        ast.Product2Id = prd.Id;
        ast.AccountId = acc_master_b.Id;
        ast.Broker_Agency__c = acc_agency_b.Id;
        ast.Renewal_date__c = date.today();
        ast.Carrier__c = 'AIG';
        insert ast;
    }
}