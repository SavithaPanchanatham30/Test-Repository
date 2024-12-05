@isTest
public class OpenEnrollmentTRGTest {
    final String WorksiteCI = 'Worksite CI';
    Static testMethod void myUnitTest1() {
 
    // Setup Test Data
     Profile p = [SELECT Id FROM Profile WHERE Name='USAble System Administrator'];
        User u = [SELECT Id FROM User WHERE profileId = :p.Id LIMIT 1];
        test.startTest();
        List <Account> lstAcc = New List<Account>();
        Account acc= new Account();
        // Get Group Contact ID       
        Id RecordTypeIdGroup = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeID();
     // Create Account of Master Group Record Type
         id MasterGroupRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeID();
          Account acc1= new Account();
        acc1.Name='Account 2';
        //acc1.RecordTypeId = [Select r.SobjectType, r.Id, r.Name  From RecordType r WHERE r.SobjectType = 'Account' AND r.Name = 'Master Group'  LIMIT 1].Id;
        acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        acc1.Type = 'Master Group';
        acc1.Industry = 'Computer';
        acc1.ShippingCountry = 'US';
        acc1.BillingStreet = '16th';
        acc1.BillingCity = 'Little Rock';
        acc1.BillingState = 'Ar';
        acc1.BillingCountry = 'US';
        acc1.BillingPostalCode = '72223';
        insert acc1;
        // Create and insert a Group Contact
        List<Contact> lstCont = new List<Contact>();
        Contact cont = new Contact();
        cont.FirstName = 'Contact';
        cont.LastName = '01';
        cont.AccountId = acc1.Id; 
        cont.RecordTypeId = RecordTypeIdGroup ; 
        cont.Contact_Type__c = 'Group Contact';
        lstCont.add(cont);
        insert lstCont;
        // Create and Insert customer Service Open Enrollment Case
        Case case4 = new Case();
        case4.AccountId=acc1.Id;
        case4.ContactId = cont.Id;
        case4.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Service').getRecordTypeId();
        case4.Status='New';
        case4.Priority = 'Medium';
        case4.Type = 'Enrollment';
        case4.Sub_Type__c = 'Open Enrollment';
        case4.Origin = 'Phone';
        //case4.Reason = 'Group';
        case4.Reason = 'Group';
         insert Case4;
        // Create and Insert Agency Account. 
        Account acc_agency = new Account();
        acc_agency = USAbleUtility.CreateAgencyAccount(); //account returned from utility class
        insert acc_agency;
        // Create and Insert Product
        Product2 prd = new Product2();
        prd.Name = 'VGTL';
        prd.Type__c = 'LSV';
        prd.ProductCode = 'VGTL';
        prd.Family = 'GRP LIFE';
        prd.Product_Category__c = 'True Group Life';
        prd.isActive  = true;
        insert PRD;
        //create asset and Insert Asset
        asset ast = new asset();
        ast.name = 'VGTL';
        ast.Product2Id = prd.Id;
        ast.AccountId = acc1.Id;
        ast.Renewal_date__c = date.today() + 50;
        ast.Carrier__c = 'BCBS';
        ast.Initial_Contracts__c  = 20;
        ast.Initial_Eligibles__c = 200;
        ast.Initial_Premium__c = 2000;	
        Insert ast;
        // create asset and Insert Asset Child
        asset chast = new asset();
        chast.name = 'VGTL Child';
        chast.Product2Id = prd.Id;
        chast.AccountId = acc1.Id;
        chast.Renewal_date__c = date.today() + 50;
        chast.Carrier__c = 'BCBS';
        chast.Initial_Contracts__c  = 5;
        chast.Initial_Eligibles__c = 00;
        chast.Initial_Premium__c = 400;  
        Insert chast;
       // create asset and Insert Asset Spouse
        asset sast = new asset();
        sast.name = 'VGTL Spouse';
        sast.Product2Id = prd.Id;
        sast.AccountId = acc1.Id;
        sast.Renewal_date__c = date.today() + 50;
        sast.Carrier__c = 'BCBS';
        sast.Initial_Contracts__c  = 5;
        sast.Initial_Eligibles__c = 00;
        sast.Initial_Premium__c = 800;  
        Insert sast;
         // create Open Enrollment and Insert Asset
        Open_Enrollment__c OE = new Open_Enrollment__c();
        OE.Accepted_Enrollment__c = 'Yes';
        OE.Case__c = Case4.Id;
        OE.Product_Type__c = 'VGTL';
       Insert OE;
    }
}