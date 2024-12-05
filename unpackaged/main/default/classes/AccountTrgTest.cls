/*
Name        : AccountTrgTest
Author      : Munazza Ahmed
Date        : 8/5/2016
Purpose : Test class for coverage of trigger on Account.
*/
@isTest
private class AccountTrgTest
{  
    
    public static testMethod void createAccountTeamTest()
    {
        Test.startTest();
        
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;
        
        id pId = [SELECT Id
                  FROM Profile
                  WHERE Name = 'USAble Standard Sales User' Limit 1].Id;
        //insert user
        User user_std = [SELECT id
                         FROM User
                         WHERE profileId =: pId AND IsActive = true limit 1];
        
        //insert account team assignment for blue territory method
        string accountManager = 'Account Manager';
        string BC_Code_1 = 'A008';
        Account_Team_Assignment__c teamAssignmentBlueTerritory_1 = USAbleUtility.CreateAccountTeamAssignmentBlueTerritory(acc_partner.Id, user_std.Id, accountManager, BC_Code_1);
        insert teamAssignmentBlueTerritory_1;
          
        //insert account team assignment for blue territory method
        string salesSupport_1 = 'Sales Support';
        string BC_Code_2 = 'A008';
        Account_Team_Assignment__c teamAssignmentBlueTerritory_2 = USAbleUtility.CreateAccountTeamAssignmentBlueTerritory(acc_partner.Id, user_std.Id, salesSupport_1, BC_Code_2);
        insert teamAssignmentBlueTerritory_2;  
        
        //insert county
        county__c countyTest = USAbleUtility.CreateCounty();
        insert countyTest;
        
        //insert account team assignment for market segment & county method
        string salesExecutive = 'Sales Executive';
        string Segment_1 = 'Mid-Market';
        Account_Team_Assignment__c teamAssignmentCounty_1 = USAbleUtility.CreateAccountTeamAssignmentSegmentCounty(acc_partner.Id, user_std.Id, salesExecutive, countyTest.Id,Segment_1);
        insert teamAssignmentCounty_1;
        
        //insert account team assignment for market segment & county method
        string salesSupport_2 = 'Sales Support';
        string Segment_2 = 'Mid-Market';
        Account_Team_Assignment__c teamAssignmentCounty_2 = USAbleUtility.CreateAccountTeamAssignmentSegmentCounty(acc_partner.Id, user_std.Id, salesSupport_2, countyTest.Id,Segment_2);
        insert teamAssignmentCounty_2;
        
        //create account of master group recordtype
        id MasterGroupRTId;
        List<Recordtype> ListOfAccRt = [SELECT Name, Id
                                    FROM Recordtype
                                    WHERE Sobjecttype = 'Account'];
        for(recordtype rt : ListOfAccRt)
        {
            if(rt.Name == 'Master Group')
            {
                MasterGroupRTId = rt.id;
            }
        }
        //insert master account
        Account acc = new Account();
        acc.recordtypeid = MasterGroupRTId;
        acc.Name = 'Test Account Master Group';
        acc.Type = 'Master Group';
        acc.Partner__c = acc_partner.Id;
        acc.Blue_Territory_Code__c = BC_Code_1 ;
        acc.Market_Segment__c = Segment_1;
        acc.County__c = countyTest.Id;
        acc.LSV_Group_Size__c = 11;
        insert acc;
        
        Asset ast = USAbleUtility.createAsset(acc.Id);
        insert ast;
        
        Account_Team_Assignment_Additional_Rule__c ataar = new Account_Team_Assignment_Additional_Rule__c();
        ataar.Active__c = true;
        ataar.Blue_Partner_Id__c = acc_partner.Id;
        ataar.Group_Size_Lower_Limit__c = 1;
        ataar.Group_Size_Upper_Limit__c = 1000000;
        ataar.Have_Asset__c = 'STD|Dental|Life & ADD|LTD|VGTL|Worksite|Medical|GRP LIFE';
        ataar.Key_Client__c = false;
        ataar.Override__c = false;
        ataar.Role__c = 'Account Manager';
        ataar.User_Id__c = user_std.Id;
        insert ataar;
        
         //create account of master group recordtype
        id ProspectRTId;
        List<Recordtype> ListOfAccRt2 = [SELECT Name, Id
                                    FROM Recordtype
                                    WHERE Sobjecttype = 'Account'];
        for(recordtype rt : ListOfAccRt2)
        {
            if(rt.Name == 'Prospect')
            {
                ProspectRTId = rt.id;
            }
        }
        
        //insert Prospect account
        Account acc2 = new Account();
        acc2.recordtypeid = ProspectRTId;
        acc2.Name = 'Test Account Prospect';
        acc2.Type = 'Prospect';
        acc2.Partner__c = acc_partner.Id;
        acc2.Blue_Territory_Code__c = BC_Code_1 ;
        acc2.Market_Segment__c = Segment_1;
        acc2.County__c = countyTest.Id;
        acc2.LSV_Group_Size__c = 11;
        acc2.BillingCity = 'Taxes';
        acc2.BillingState = 'FL';
        acc2.BillingPostalCode = '123';
        acc2.BillingCountry = 'US';
        acc2.BillingStreet = '27';
        insert acc2;
        
        //insert custom setting record
        Account_Team_Assignment_Exception__c ex = new Account_Team_Assignment_Exception__c();
        ex.Name = 'Test exception';
        ex.Active__c = true;
        ex.Account_field__c = 'LSV_Business__c';
        ex.Do_Not_Assign__c = true;
        ex.Partner_Id__c = acc_partner.Id;
        ex.Team_Role__c = 'Account Manager';
        ex.Value__c = 'Medical Only';
        insert ex;
        
        acc.LSV_Business__c = 'Medical Only';
        update acc;
        
        acc.Blue_Territory_Code__c = BC_Code_2;
        acc.reset_account_team__c = true;
        update acc;
        
        Test.stopTest();
    } 
    
    public static testMethod void createATAAROverideTrueTest2()
    {
        Test.startTest();
        
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;
        
        id pId = [SELECT Id
                  FROM Profile
                  WHERE Name = 'USAble Standard Sales User' Limit 1].Id;
        //insert user
        User user_std = [SELECT id
                         FROM User
                         WHERE profileId =: pId AND IsActive = true limit 1];
        
        //insert account team assignment for blue territory method
        string accountManager = 'Account Manager';
        string BC_Code_1 = 'A008';
        Account_Team_Assignment__c teamAssignmentBlueTerritory_1 = USAbleUtility.CreateAccountTeamAssignmentBlueTerritory(acc_partner.Id, user_std.Id, accountManager, BC_Code_1);
        insert teamAssignmentBlueTerritory_1;
          
        //insert account team assignment for blue territory method
        string salesSupport_1 = 'Sales Support';
        string BC_Code_2 = 'A008';
        Account_Team_Assignment__c teamAssignmentBlueTerritory_2 = USAbleUtility.CreateAccountTeamAssignmentBlueTerritory(acc_partner.Id, user_std.Id, salesSupport_1, BC_Code_2);
        insert teamAssignmentBlueTerritory_2;  
        
        //insert county
        county__c countyTest = USAbleUtility.CreateCounty();
        insert countyTest;
        
        //insert account team assignment for market segment & county method
        string salesExecutive = 'Sales Executive';
        string Segment_1 = 'Mid-Market';
        Account_Team_Assignment__c teamAssignmentCounty_1 = USAbleUtility.CreateAccountTeamAssignmentSegmentCounty(acc_partner.Id, user_std.Id, salesExecutive, countyTest.Id,Segment_1);
        insert teamAssignmentCounty_1;
        
        //insert account team assignment for market segment & county method
        string salesSupport_2 = 'Sales Support';
        string Segment_2 = 'Mid-Market';
        Account_Team_Assignment__c teamAssignmentCounty_2 = USAbleUtility.CreateAccountTeamAssignmentSegmentCounty(acc_partner.Id, user_std.Id, salesSupport_2, countyTest.Id,Segment_2);
        insert teamAssignmentCounty_2;
        
        //create account of master group recordtype
        id MasterGroupRTId;
        List<Recordtype> ListOfAccRt = [SELECT Name, Id
                                    FROM Recordtype
                                    WHERE Sobjecttype = 'Account'];
        for(recordtype rt : ListOfAccRt)
        {
            if(rt.Name == 'Master Group')
            {
                MasterGroupRTId = rt.id;
            }
        }
        //insert master account
        Account acc = new Account();
        acc.recordtypeid = MasterGroupRTId;
        acc.Name = 'Test Account Master Group';
        acc.Type = 'Master Group';
        acc.Partner__c = acc_partner.Id;
        acc.Blue_Territory_Code__c = BC_Code_1 ;
        acc.Market_Segment__c = Segment_1;
        acc.County__c = countyTest.Id;
        acc.LSV_Group_Size__c = 11;
        insert acc;
        
        Asset ast = USAbleUtility.createAsset(acc.Id);
        insert ast;
        
        Account_Team_Assignment_Additional_Rule__c ataar = new Account_Team_Assignment_Additional_Rule__c();
        ataar.Active__c = true;
        ataar.Blue_Partner_Id__c = acc_partner.Id;
        ataar.Group_Size_Lower_Limit__c = 1;
        ataar.Group_Size_Upper_Limit__c = 1000000;
        ataar.Have_Asset__c = 'STD|Dental|Life & ADD|LTD|VGTL|Worksite|Medical|GRP LIFE';
        ataar.Key_Client__c = false;
        ataar.Override__c = true;
        ataar.Role__c = 'Account Manager';
        ataar.User_Id__c = user_std.Id;
        insert ataar;
        
    
        //insert custom setting record
        Account_Team_Assignment_Exception__c ex = new Account_Team_Assignment_Exception__c();
        ex.Name = 'Test exception';
        ex.Active__c = true;
        ex.Account_field__c = 'LSV_Business__c';
        ex.Do_Not_Assign__c = true;
        ex.Partner_Id__c = acc_partner.Id;
        ex.Team_Role__c = 'Account Manager';
        ex.Value__c = 'Medical Only';
        insert ex;
        
        //acc.LSV_Business__c = 'Medical Only';
        //update acc;
        
        acc.Blue_Territory_Code__c = BC_Code_2;
        acc.reset_account_team__c = true;
        update acc;
        
        Test.stopTest();
    }  
    
    public static testMethod void createAccountTeamWithNoExTest()
    {
        Test.startTest();
        
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;
        
        id pId = [SELECT Id
                  FROM Profile
                  WHERE Name = 'USAble Standard Sales User' Limit 1].Id;
        //insert user
        User user_std = [SELECT id
                         FROM User
                         WHERE profileId =: pId AND IsActive = true limit 1];
        
        //insert account team assignment for blue territory method
        string accountManager = 'Account Manager';
        string BC_Code_1 = 'A008';
        Account_Team_Assignment__c teamAssignmentBlueTerritory_1 = USAbleUtility.CreateAccountTeamAssignmentBlueTerritory(acc_partner.Id, user_std.Id, accountManager, BC_Code_1);
        insert teamAssignmentBlueTerritory_1;
          
        //insert account team assignment for blue territory method
        string salesSupport_1 = 'Sales Support';
        string BC_Code_2 = 'A008';
        Account_Team_Assignment__c teamAssignmentBlueTerritory_2 = USAbleUtility.CreateAccountTeamAssignmentBlueTerritory(acc_partner.Id, user_std.Id, salesSupport_1, BC_Code_2);
        insert teamAssignmentBlueTerritory_2;  
        
        //insert county
        county__c countyTest = USAbleUtility.CreateCounty();
        insert countyTest;
        
        //insert account team assignment for market segment & county method
        string salesExecutive = 'Sales Executive';
        string Segment_1 = 'Mid-Market';
        Account_Team_Assignment__c teamAssignmentCounty_1 = USAbleUtility.CreateAccountTeamAssignmentSegmentCounty(acc_partner.Id, user_std.Id, salesExecutive, countyTest.Id,Segment_1);
        insert teamAssignmentCounty_1;
        
        //insert account team assignment for market segment & county method
        string salesSupport_2 = 'Sales Support';
        string Segment_2 = 'Mid-Market';
        Account_Team_Assignment__c teamAssignmentCounty_2 = USAbleUtility.CreateAccountTeamAssignmentSegmentCounty(acc_partner.Id, user_std.Id, salesSupport_2, countyTest.Id,Segment_2);
        insert teamAssignmentCounty_2;
        
        //create account of master group recordtype
        id MasterGroupRTId;
        List<Recordtype> ListOfAccRt = [SELECT Name, Id
                                    FROM Recordtype
                                    WHERE Sobjecttype = 'Account'];
        for(recordtype rt : ListOfAccRt)
        {
            if(rt.Name == 'Master Group')
            {
                MasterGroupRTId = rt.id;
            }
        }
        //insert master account
        Account acc = new Account();
        acc.recordtypeid = MasterGroupRTId;
        acc.Name = 'Test Account Master Group';
        acc.Type = 'Master Group';
        acc.Partner__c = acc_partner.Id;
        acc.Blue_Territory_Code__c = BC_Code_1 ;
        acc.Market_Segment__c = Segment_1;
        acc.County__c = countyTest.Id;
        acc.LSV_Group_Size__c = 11;
        insert acc;
        
        Asset ast = USAbleUtility.createAsset(acc.Id);
        insert ast;
        
        Account_Team_Assignment_Additional_Rule__c ataar = new Account_Team_Assignment_Additional_Rule__c();
        ataar.Active__c = true;
        ataar.Blue_Partner_Id__c = acc_partner.Id;
        ataar.Group_Size_Lower_Limit__c = 1;
        ataar.Group_Size_Upper_Limit__c = 1000000;
        ataar.Have_Asset__c = 'STD|Dental|Life & ADD|LTD|VGTL|Worksite|Medical|GRP LIFE';
        ataar.Key_Client__c = false;
        ataar.Override__c = true;
        ataar.Role__c = 'Account Manager';
        ataar.User_Id__c = user_std.Id;
        insert ataar;
        
    
        //insert custom setting record
        /*
        Account_Team_Assignment_Exception__c ex = new Account_Team_Assignment_Exception__c();
        ex.Name = 'Test exception';
        ex.Active__c = true;
        ex.Account_field__c = 'LSV_Business__c';
        ex.Do_Not_Assign__c = true;
        ex.Partner_Id__c = acc_partner.Id;
        ex.Team_Role__c = 'Account Manager';
        ex.Value__c = 'Medical Only';
        insert ex;
        */
        //acc.LSV_Business__c = 'Medical Only';
        //update acc;
        
        acc.Blue_Territory_Code__c = BC_Code_2;
        acc.reset_account_team__c = true;
        update acc;
        
        Test.stopTest();
    }    
    
    public static testMethod void prospectAcctTest()
    {
        Test.startTest();
        
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;        
        
        Test.stopTest();
    }
    
    public static testMethod void ProspectToMGAccountTest()
    {
        Test.startTest();
        
        //insert Master Group Account
        Account acc_MG = USAbleUtility.CreateMasterGroupAccount(); //account returned from utility class
        insert acc_MG;
        
        //insert Master Group Account
        //Account acc_MG1 = USAbleUtility.CreateMasterGroupAccount(); //account returned from utility class
        //insert acc_MG1;
        
        //insert Prospect Account
        Account acc_Prospect = USAbleUtility.CreateProspectAccount(); //account returned from utility class
        insert acc_Prospect;
        
        //insert Oppotunity
        Opportunity NewOpp = USAbleUtility.CreateOpportunity(acc_Prospect);
        NewOpp.Effective_Date__c = date.today();
        insert NewOpp;
        
        //insert Contact
        Contact con = new contact();
        con.AccountId = acc_Prospect.id;
        con.FirstName = 'Clark';
        con.LastName  = 'Michael';
        con.Email = 'abc@test.com';
        con.Contact_Type__c = 'Group Contact';
        con.Phone = '1234567';
        con.Title = 'Mr.';
        con.Partner_Rep_Territory_Code__c = 'A555';
        con.MailingState = 'FL';  
        con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeId();
        
        
        insert con;
        
        
        acc_Prospect.Master_Group__c = acc_MG.id;
        update acc_Prospect;
        
        //acc_Prospect.Master_Group__c = acc_MG1.id;
        //update acc_Prospect;
        
        Test.stopTest();
    }
    
    public static testMethod void updateAgency()
    {
        
        Test.startTest();
        
        List<Blue_Rep_Fields__c> listCS = new List<Blue_Rep_Fields__c>();
        
        Blue_Rep_Fields__c brf = new Blue_Rep_Fields__c();
        brf.Name = 'BCBS of Florida';
        brf.API_Name_of_field__c = 'FL__c';
        brf.Name_of_field__c = 'FL';
        brf.Partner_Id__c = '0016300000ORP1dAAH';
        listCS.add(brf);
        
        Blue_Rep_Fields__c brf2 = new Blue_Rep_Fields__c();
        brf2.Name = 'Arkansas BCBS';
        brf2.API_Name_of_field__c = 'AR__c';
        brf2.Name_of_field__c = 'AR';
        brf2.Partner_Id__c = '0016300000ORP1aAAH';
        listCS.add(brf2);

        insert listCS;     
        
        
        List<Recordtype> agencyRecordTypeId = [SELECT Name, Id
                                    FROM Recordtype
                                    WHERE Sobjecttype = 'Account' and DeveloperName = 'Agency' limit 1];

        Account acc = new Account();
        acc.recordtypeid = agencyRecordTypeId[0].Id;
        acc.Name = 'Test Account Service Agency';
        acc.Type = 'Agency';
        acc.BillingCity = 'Taxes';
        acc.BillingState = 'FL';
        acc.BillingPostalCode = '123';
        acc.BillingCountry = 'US';
        acc.BillingStreet = '27';
        insert acc;

        Account accBA = new Account();
        accBA.recordtypeid = agencyRecordTypeId[0].Id;
        accBA.Name = 'Test Account Agency';
        accBA.Type = 'Agency';
        accBA.BillingCity = 'Taxes';
        accBA.BillingState = 'FL';
        accBA.BillingPostalCode = '123';
        accBA.BillingCountry = 'US';
        accBA.BillingStreet = '27';
        accBA.Service_Master_Agency__c = acc.id;
        insert accBA;        
        
        Contact con = new contact();
        con.AccountId = acc.id;
        con.Agency_Branch__c = accBA.id;
        con.FirstName = 'Clark';
        con.LastName  = 'Michael';
        con.Email = 'abc@test.com';
        con.Contact_Type__c = 'Agency';
        con.Phone = '1234567';
        con.Title = 'Mr.';
        con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        insert con;  
        
        accBA.FL__c = true;
        update accBA;
        
        Test.stopTest();
    }
    
}