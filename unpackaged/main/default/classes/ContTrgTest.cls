/*
Name: ContTrgTest
Created By: Zaid Ali
Date: 8/15/2016
Purpose: To get coverage of Opportunity heiarchy fields populate.


Modified By: Munazza Ahmed
Date: 9/18/2016
Purpose: To get coverage of Contact insertion and partner region populate.

Modified By: Mansoor Ahmad
Date; 04/16/2019
Purpose: Correct the Billing Addresses as valid entries (Valid State and Country Codes are added)
*/

@isTest

private class ContTrgTest
{  
    //added by Zaid Ali 
    public static testMethod void OppHeararchyTest()
    {
        Test.startTest();
        
        // partner rep functionality test here
        Account AccPR = new Account();
        AccPR = USAbleUtility.CreateMasterGroupAccount();
        AccPR.BillingStreet = 'asd';
        AccPR.BillingCity = 'asd';
        AccPR.BillingState = 'FL';
        AccPR.BillingCountry = 'US';
        AccPR.BillingPostalCode = '123';
        insert AccPR;
        
        Account AccForPartner = new Account();
        AccForPartner = USAbleUtility.CreatePartnerAccount();
        //AccForPartner.Address__c='asdad';
        AccForPartner.BillingStreet = 'asd';
        AccForPartner.BillingCity = 'asd';
        AccForPartner.BillingState = 'FL';
        AccForPartner.BillingCountry = 'US';
        AccforPartner.BillingPostalCode = '123';
        insert AccForPartner;
        
        AccPR.Partner__c = AccForPartner.Id;
        
        Id RecordTypeIdPR;
        Id RecordTypeIdAgent;
        Id RecordTypeIdGroup;
        /*
        for(recordtype RecordTypeCon : [SELECT ID, Name 
                                   FROM Recordtype
                                   WHERE SobjectType = 'Contact'])
        {
            if(RecordTypeCon.Name == 'Partner Rep')
            {
                RecordTypeIdPR = RecordTypeCon.Id;
            }
            else if(RecordTypeCon.Name == 'Agent')
            {
                RecordTypeIdAgent = RecordTypeCon.Id;
            }
            else if(RecordTypeCon.Name == 'Group Contact')
            {
                RecordTypeIdGroup = RecordTypeCon.Id;
            }
        }
        */        

        RecordTypeIdPR = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner Rep').getRecordTypeId();
        RecordTypeIdAgent = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        RecordTypeIdGroup = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeId();
        
        Contact Con = new Contact ();
        Con.LastName = 'Test';
        Con.FirstName = 'Test';
        Con.AccountId = AccForPartner.Id;
        Con.RecordtypeId = RecordTypeIdPR ;
        insert Con;
        
        Contact Con1 = new Contact ();
        Con1.LastName = 'Test1';
        Con1.FirstName = 'First Name';
        Con1.AccountId = AccPR.Id;
        Con1.RecordtypeId = RecordTypeIdGroup;
        Con1.Phone = '123';
        Con1.Email = 'abc@gmail.com';
        insert Con1;
        
        Contact Con2 = new Contact ();
        Con2.LastName = 'Test2';
        Con2.FirstName = 'First Name';
        Con2.AccountId = AccForPartner.Id;
        Con2.RecordtypeId = RecordTypeIdPR ;
        Con2.Phone = '123';
        Con2.Email = 'abc@gmail.com';
        Con2.Contact_Type__c = 'Agent';
        insert Con2;
        
        Contact Con3 = new Contact ();
        Con3.LastName = 'Test3';
        Con3.FirstName = 'First Name';
        Con3.AccountId = AccForPartner.Id;
        Con3.Partner_Rep_Director__c = Con.Id;
        Con3.Partner_Rep_Manager__c = Con2.Id;
        Con3.Partner_Rep_VP__c = Con1.Id;
        Con3.Partner_Rep_Territory_Code__c = '123';
        Con3.RecordtypeId = RecordTypeIdPR ;
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
        AccForPartner.BillingState = 'FL';
        AccForPartner.BillingCountry = 'US';
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
        
        // This code is added by Zaid for deployment
        ETL_and_Non_ETL_fields_for_Contact__c nonETLFields = new ETL_and_Non_ETL_fields_for_Contact__c ();
        nonETLFields.ETL__c = false;
        nonETLFields.Field_API_Name__c = 'TestFieldAPINameNonETL';
        nonETLFields.Name = 'TestNonETL';
        insert nonETLFields;
        
        Con1.Email = 'abcd@gmail.com';
        update con1;
        // Zaid Code ends here
        // 
        Test.stopTest();
        
    }
    public static testMethod void contactInsertionPartnerRegion()
    {
        Test.startTest();
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;
        
        //insert account
        Account acc = new Account();
        acc = USAbleUtility.CreateMasterGroupAccount(); //account returned from utility class
        acc.partner__c = acc_partner.Id;
        acc.BillingStreet = 'abc';
        acc.BillingCity = 'abc';
        acc.BillingCountry = 'abc';
        acc.BillingState = 'abc';
        acc.BillingStreet  = 'abc';
        acc.BillingCity = 'asd';
        acc.BillingState = 'FL';
        acc.BillingCountry = 'US';
        acc.BillingPostalCode = '123';
        insert acc; 
        
        //insert custom setting record
        Blue_Rep_Fields__c bFields = new Blue_Rep_Fields__c ();
        bFields.Name = 'Test Field';
        bFields.Partner_Id__c = acc_partner.Id;
        bFields.API_Name_of_field__c = 'FL__c';
        bFields.Name_of_field__c = 'FL';
        insert bFields;
        
        contact GrpCon = new contact();
        GrpCon.AccountId = acc.Id;
        GrpCon.Lastname = 'Contact';
        GrpCon.Firstname = 'Test';
        GrpCon.Phone = '02103757974';
        GrpCon.Email = 'test@test.com';
        GrpCon.RecordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeId();
        insert GrpCon;
        
        contact PartnerCon = new contact();
        PartnerCon.AccountId = acc_partner.Id;
        PartnerCon.Lastname = 'Contact';
        PartnerCon.Firstname = 'Test';
        PartnerCon.Phone = '02103757974';
        PartnerCon.Email = 'test@test.com';
        PartnerCon.RecordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner Rep').getRecordTypeId();
        insert PartnerCon;
        
        Test.stopTest();
    }
}