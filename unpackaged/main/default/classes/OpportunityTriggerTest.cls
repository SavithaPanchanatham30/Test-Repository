/*
Name        : OpportunityTriggerTest
Author      : Munazza Ahmed
Date        : 7/19/2016
Purpose : Test class for coverage of trigger on Opportunity.

Modified By: Zaid Ali
Date: 8/15/2016
Purpose: To get coverage of Opportunity heiarchy fields populate.
*/

@isTest

private class OpportunityTriggerTest
{  
    
    public static testMethod void assetCreationOnOppCloseTest()
    {
        Test.startTest();
        //insert account
        Account acc = new Account();
        acc = USAbleUtility.CreateMasterGroupAccount(); //account returned from utility class
        insert acc;
        //insert Opportunity
        Opportunity opp = new Opportunity();
        opp = USAbleUtility.CreateOpportunity(acc); //opportunity returned from utility class
        opp.Effective_Date__c = date.today();
        insert opp;
        //insert Product
        Product2 prd = new Product2();
        prd = USAbleUtility.CreateProuct(); //Product returned from utility class
        insert prd;
        //insert PricebookEntry
        PricebookEntry pbe = new PricebookEntry();
        pbe = USAbleUtility.CreatePBE(prd); //PricebookEntry returned from utility class
        insert pbe;
        //insert OpportunityLineItem with closed lost stage
        OpportunityLineItem oli1 = new OpportunityLineItem();
        oli1 = USAbleUtility.CreateOppLineItemClosedLost(opp,prd,pbe); //OpportunityLineItem returned from utility class
        oli1.UnitPrice = 1;
        oli1.Changed_Carrier__c = 'yes';        
        insert oli1;
        //insert OpportunityLineItem with other than closed lost stage
        OpportunityLineItem oli2 = new OpportunityLineItem();
        oli2 = USAbleUtility.CreateOppLinePursue(opp,prd,pbe); //OpportunityLineItem returned from utility class
        oli2.UnitPrice = 2;
        insert oli2;
        opp.stagename = 'Closed Lost';
        update opp;
        
        Test.stopTest();
    }  
    
    //added by Zaid Ali 
    public static testMethod void OppHeararchyTest()
    {
        Test.startTest();
        
        /*
        // partner rep functionality test here
        Account AccPR = new Account();
        AccPR = USAbleUtility.CreateMasterGroupAccount();
        AccPR.BillingStreet = 'asd';
        AccPR.BillingCity = 'asd';
        AccPR.BillingState = 'asd';
        AccPR.BillingCountry = 'asd';
        AccPR.BillingPostalCode = '123';
        AccPR.Blue_Rep_Name__c = Conclone.Id
        insert AccPR;
        */
        
        Account AccAgency = New Account();
        AccAgency = USAbleUtility.CreateAgencyAccount();
        AccAgency.BillingStreet = 'asd';
        AccAgency.BillingCity = 'asd';
        AccAgency.BillingState = 'asd';
        AccAgency.BillingCountry = 'asd';
        AccAgency.BillingPostalCode = '123';
        insert AccAgency ;
        
        
        Account AccForPartner = new Account();
        AccForPartner = USAbleUtility.CreatePartnerAccount();
        //AccForPartner.Address__c='asdad';
        AccForPartner.BillingStreet = 'asd';
        AccForPartner.BillingCity = 'asd';
        AccForPartner.BillingState = 'asd';
        AccForPartner.BillingCountry = 'asd';
        AccforPartner.BillingPostalCode = '123';
        insert AccForPartner;                        
        
        Id RecordTypeIdPR = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner Rep').getRecordTypeId();
        Id RecordTypeIdAgent = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        Id RecordTypeIdGroup = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeId();
        
        Contact Con = new Contact ();
        Con.LastName = 'Test';
        Con.FirstName = 'Test';
        Con.AccountId = AccForPartner.Id;
        Con.RecordtypeId = RecordTypeIdPR ;
        insert Con;
        
        Contact Conclone = new Contact ();
        Conclone.LastName = 'Test';
        Conclone.FirstName = 'Test';
        Conclone.AccountId = AccForPartner.Id;
        Conclone.RecordtypeId = RecordTypeIdPR ;
        insert Conclone;
        
        Account AccPR = new Account();
        AccPR = USAbleUtility.CreateMasterGroupAccount();
        AccPR.BillingStreet = 'asd';
        AccPR.BillingCity = 'asd';
        AccPR.BillingState = 'asd';
        AccPR.BillingCountry = 'asd';
        AccPR.BillingPostalCode = '123';
        AccPR.Blue_Rep_Name__c = Conclone.Id;
        AccPR.Partner__c = AccForPartner.id;
            insert AccPR;        
        
        Contact Con1 = new Contact ();
        Con1.LastName = 'Test1';
        Con1.FirstName = 'First Name';
        Con1.AccountId = AccAgency.Id;
        Con1.RecordtypeId = RecordTypeIdAgent;
        Con1.Phone = '123';
        Con1.Email = 'abc@gmail.com';
        Con1.Contact_Type__c = 'Agent';
        insert Con1;
        
        Contact Con2 = new Contact ();
        Con2.LastName = 'Test2';
        Con2.FirstName = 'First Name';
        Con2.AccountId = AccAgency.Id;
        Con2.RecordtypeId = RecordTypeIdAgent;
        Con2.Phone = '123';
        Con2.Email = 'abc@gmail.com';
        Con2.Contact_Type__c = 'Agent';
        insert Con2;
        
        Contact Con3 = new Contact ();
        Con3.LastName = 'Test3';
        Con3.FirstName = 'First Name';
        Con3.AccountId = AccPR.Id;
        Con3.Partner_Rep_Director__c = Con.Id;
        Con3.Partner_Rep_Manager__c = Con2.Id;
        Con3.Partner_Rep_VP__c = Con1.Id;
        Con3.Partner_Rep_Territory_Code__c = '123';
        Con3.RecordtypeId = RecordTypeIdGroup ;
        Con3.Phone = '123';
        Con3.Email = 'abc@gmail.com';
        Con3.Contact_Type__c = 'Agent';
        insert Con3;
        
        //AccPR.Blue_Rep_Name__c = Con.id;
        //update AccPr;
        
        Opportunity OppPR = new Opportunity();
        OppPR = USAbleUtility.CreateOpportunity(AccPR); //opportunity returned from utility class
        OppPR.StageName = 'In Process';
        OppPR.Effective_Date__c = date.today();
        insert OppPR;
        
        Con3.Partner_Rep_Manager__c = con.id;
        update con3;
         
        //List <Opportunity> lstOpp = new List <Opportunity>();
        //lstOpp.add(opp);
        //OpportunityTrgUtil.UpdateOpportunityReps(lstOpp);
        //
        Test.stopTest();
    }
    
    public static testMethod void ContactCustomSettingTest()
    {
        Test.startTest();
        
        Id RecordTypeIdAgent = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        
        Account acc = new Account();
        acc = USAbleUtility.CreateAgencyAccount(); //account returned from utility class
        insert acc;
        
        Account AccForPartner = new Account();
        AccForPartner = USAbleUtility.CreatePartnerAccount();
        //AccForPartner.Address__c='asdad';
        AccForPartner.BillingStreet = 'asd';
        AccForPartner.BillingCity = 'asd';
        AccForPartner.BillingState = 'asd';
        AccForPartner.BillingCountry = 'asd';
        AccforPartner.BillingPostalCode = '123';
        insert AccForPartner;
        
        Blue_Rep_Fields__c blueRepFields = new Blue_Rep_Fields__c();
        blueRepFields.API_Name_of_field__c = 'FL__c';
        blueRepFields.Partner_Id__c = AccForPartner.id;
        blueRepFields.Name_of_field__c = 'FL';
        blueRepFields.Name = 'Florida';
        insert blueRepFields;
        
        Agency_Partner__c AP = new Agency_Partner__c();
        AP.Master_Partner_ID__c = AccForPartner.id;
        AP.Master_Agency_ID__c = acc.id;
        insert AP;
        
        Contact Con1 = new Contact ();
        Con1.LastName = 'Test1';
        Con1.FirstName = 'First Name';
        Con1.AccountId = Acc.Id;
        Con1.RecordtypeId = RecordTypeIdAgent;
        Con1.Phone = '123';
        Con1.Email = 'abc@gmail.com';
        Con1.Contact_Type__c = 'Agent';
        insert Con1;
        
        // This code is added by Zaid for deployment
            ETL_and_Non_ETL_fields_for_Contact__c ETLFields = new ETL_and_Non_ETL_fields_for_Contact__c ();
            ETLFields.ETL__c = true;
            ETLFields.Field_API_Name__c = 'TestFieldAPIName';
            ETLFields.Name = 'Test';
        insert ETLFields;
        
        Con1.Email = 'abcd@gmail.com';
        update con1;
        // Zaid Code ends here
        // 
        Test.stopTest();
        
    }
    public static testMethod void OpportunityCreationBlueRepRegionPopulateTest()
    {
        Test.startTest();
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;
        
        //insert account
        Account acc = new Account();
        acc = USAbleUtility.CreateMasterGroupAccount(); //account returned from utility class
        acc.Partner__c = acc_partner.Id;
        insert acc;
        
        //insert custom setting record
        Blue_Rep_Fields__c bFields = new Blue_Rep_Fields__c ();
        bFields.Name = 'Test Field';
        bFields.Partner_Id__c = acc_partner.Id;
        bFields.API_Name_of_field__c = 'FL__c';
        bFields.Name_of_field__c = 'FL';
        insert bFields;
        
        //insert Opportunity
        Opportunity opp = new Opportunity();
        opp = USAbleUtility.CreateOpportunity(acc); //opportunity returned from utility class
        opp.Effective_Date__c = date.today();
        insert opp;
        
        Test.stopTest();
    }
}