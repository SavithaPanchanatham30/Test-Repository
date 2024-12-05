/*
Name        : AgencyPartnerTrgTest
Author      : Munazza Ahmed
Date        : 9/5/2016
Purpose : Test class for coverage of trigger on AgencyPartner.
*/
@isTest
private class AgencyPartnerTrgTest
{  
    public static testMethod void BlueRepRegionCheckboxesTest()
    {
        Test.startTest();
        
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;
        
        //insert account
        Account acc = new Account();
        acc = USAbleUtility.CreateAgencyAccount(); //account returned from utility class
        insert acc;
        
        string AgenctRTId;
        //query appropriate recordtype
        List<Recordtype> ListOfAccRt = [SELECT Name, Id
                                        FROM Recordtype
                                        WHERE Sobjecttype = 'Contact'];
        for(recordtype rt : ListOfAccRt)
        {
            if(rt.Name == 'Agent')
            {
                AgenctRTId = rt.id;
            }
        }
        /*
        //insert contact agent
        Contact cont = new contact();
        cont.FirstName = 'test';
        cont.LastName = 'agent';
        cont.AccountId = acc.Id;
        cont.Phone = '0213455';
        cont.Email = 'test@testmail.com';
        cont.RecordTypeId = AgenctRTId;
        insert cont;
        */
        //insert custom setting record
        Blue_Rep_Fields__c bFields = new Blue_Rep_Fields__c ();
        bFields.Name = 'Test Field';
        bFields.Partner_Id__c = acc_partner.Id;
        bFields.API_Name_of_field__c = 'FL__c';
        bFields.Name_of_field__c = 'FL';
        insert bFields;
        
        
        //insert AgencyPartner record
        Agency_Partner__c ap = new Agency_Partner__c();
        ap.Master_Agency_ID__c = acc.Id;
        ap.Master_Partner_ID__c = acc_partner.Id;
        insert ap;
        
        //insert partner account
        Account acc_partner_2 = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner_2;
        
        //insert custom setting record
        Blue_Rep_Fields__c bFields_2 = new Blue_Rep_Fields__c ();
        bFields_2.Name = 'Test Field2';
        bFields_2.Partner_Id__c = acc_partner_2.Id;
        bFields_2.API_Name_of_field__c = 'AR__c';
        bFields_2.Name_of_field__c = 'AR';
        insert bFields_2;
        
        //update AgencyPartner record
        ap.Master_Partner_ID__c = acc_partner_2.Id;
        update ap;
        
        Test.stopTest();
        
    }
}