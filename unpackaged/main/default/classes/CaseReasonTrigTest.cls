/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CaseReasonTrigTest {
    
    static testMethod void myUnitTest1() {
        Test.startTest();
        
        // These Lines are added by Zaid to correct the test class
        
        Id RecordTypeIdPR = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner Rep').getRecordTypeId();
        Id RecordTypeIdAgent = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        Id RecordTypeIdGroup = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeId();
        Id RecordTypeIdMember = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        
        //insert county
        county__c countyTest = USAbleUtility.CreateCounty();
        insert countyTest;
        
        string BC_Code_1 = 'A008';
        string Segment_1 = 'Mid-Market';
        
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;
        
        // Zaid Modification ends here
        
        Account acc= new Account();
        acc.Name='Account 1';
        //acc.RecordTypeId = [Select r.SobjectType, r.Id, r.Name  From RecordType r WHERE r.SobjectType = 'Account' AND r.Name = 'Master Group'  LIMIT 1].Id;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        acc.Type = 'Master Group';
        acc.Industry = 'Computer';
        acc.ShippingCountry = 'US';
        acc.BillingStreet = '16th';
        acc.BillingCity = 'Chicago';
        acc.BillingState = 'IL';
        acc.BillingCountry = 'US';
        acc.BillingPostalCode = '25250';
        
        // Zaid code here
        acc.Partner__c = acc_partner.Id;
        acc.Blue_Territory_Code__c = BC_Code_1 ;
        acc.Market_Segment__c = Segment_1;
        acc.County__c = countyTest.Id;
        // Zaid code ends here
        
        insert acc;
        
        Group__c group11 = new Group__c();
        group11.Name = 'Test group';
        group11.Master_Group__c = acc.Id;
        
        insert group11;
        
        Contact cont = new Contact();
        cont.FirstName = 'Contact';
        cont.LastName = '01';
        cont.AccountId = acc.Id; 
        cont.RecordTypeId = RecordTypeIdGroup ; // This line is added by Zaid
        cont.Contact_Type__c = 'Group Contact';
        
        insert cont;
        
        Member__c member = new Member__c();
        member.Member__c = cont.Id;
        member.Group__c = group11.Id;
        insert member;   
        // Rick added additional member 
        
        Contact cont2 = new Contact();
        cont2.FirstName = 'Membercontact';
        cont2.LastName = '01';
        cont2.AccountId = acc.Id; 
        cont2.RecordTypeId = RecordTypeIdMember ; // This line is added by Rick
        cont2.Contact_Type__c = 'Member';
        cont2.Group__c = group11.id;
        insert cont2;
        
        Member__c member2 = new Member__c();
        member2.Member__c = cont2.Id;
        member2.Group__c = group11.Id;
        insert member2;  
        // Zaid Added this
        
        Case case1 = new Case();
        case1.AccountId=acc.Id;
        case1.ContactId = cont.Id;
        //case1.RecordTypeId = [Select r.SobjectType, r.Id, r.Name  From RecordType r WHERE r.SobjectType = 'Case' AND r.Name = 'Policy Services'  LIMIT 1].Id;
        case1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Policy Services').getRecordTypeId();
        case1.Status='New';
        case1.Priority = 'Medium';
        case1.Type = 'New Business Setup';
        case1.Origin = 'newbusiness@usablelife.com';
        //case1.Reason = 'Group/Member'; commented by Zaid
        case1.Reason = 'Group';
        
        insert case1;
        
        Test.stopTest();    
    }
    
    static testMethod void myUnitTest2() {
        Test.startTest();
        
        // These Lines are added by Zaid to correct the test class
        
        Id RecordTypeIdPR = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner Rep').getRecordTypeId();
        Id RecordTypeIdAgent = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        Id RecordTypeIdGroup = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeId();
        Id RecordTypeIdMember = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        
        //insert county
        county__c countyTest = USAbleUtility.CreateCounty();
        insert countyTest;
        
        string BC_Code_1 = 'A008';
        string Segment_1 = 'Mid-Market';
        
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;
        
        // Zaid Modification ends here
        
        List <Account> lstAcc = New List<Account>();
        Account acc= new Account();
        acc.Name='Account 1';
        //acc.RecordTypeId = [Select r.SobjectType, r.Id, r.Name  From RecordType r WHERE r.SobjectType = 'Account' AND r.Name = 'Master Group'  LIMIT 1].Id;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        acc.Type = 'Master Group';
        acc.Industry = 'Computer';
        acc.ShippingCountry = 'US';
        acc.BillingStreet = '16th';
        acc.BillingCity = 'Chicago';
        acc.BillingState = 'IL';
        acc.BillingCountry = 'US';
        acc.BillingPostalCode = '25250';
        
        // Zaid code here
        acc.Partner__c = acc_partner.Id;
        acc.Blue_Territory_Code__c = BC_Code_1 ;
        acc.Market_Segment__c = Segment_1;
        acc.County__c = countyTest.Id;
        // Zaid code ends here        
        lstAcc.add(acc);        
        
        Account acc1= new Account();
        acc1.Name='Account 2';
        //acc1.RecordTypeId = [Select r.SobjectType, r.Id, r.Name  From RecordType r WHERE r.SobjectType = 'Account' AND r.Name = 'Master Group'  LIMIT 1].Id;
        acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        acc1.Type = 'Master Group';
        acc1.Industry = 'Computer';
        acc1.ShippingCountry = 'US';
        acc1.BillingStreet = '16th';
        acc1.BillingCity = 'Chicago';
        acc1.BillingState = 'IL';
        acc1.BillingCountry = 'US';
        acc1.BillingPostalCode = '25250';
        lstAcc.add(acc1);
        
        Account AccAgency = New Account();
        AccAgency = USAbleUtility.CreateAgencyAccount();
        AccAgency.BillingStreet = 'asd';
        AccAgency.BillingCity = 'asd';
        AccAgency.BillingState = 'asd';
        AccAgency.BillingCountry = 'asd';
        AccAgency.BillingPostalCode = '123';
        lstAcc.add(AccAgency);
        
        insert lstAcc;
        //insert acc;
        
        acc.Id = lstAcc[0].Id;
        acc1.Id = lstAcc[1].Id; 
        AccAgency.Id = lstAcc[2].Id;
        
        Group__c group11 = new Group__c();
        group11.Name = 'Test group';
        group11.Master_Group__c = acc.Id;
        
        insert group11;
        
        List<Contact> lstCont = new List<Contact>();
        Contact cont = new Contact();
        cont.FirstName = 'Contact';
        cont.LastName = '01';
        cont.AccountId = acc.Id; 
        cont.RecordTypeId = RecordTypeIdGroup ; // This line is added by Zaid
        cont.Contact_Type__c = 'Group Contact';
        lstCont.add(cont);
        
        
        Contact cont1 = new Contact();
        cont1.FirstName = 'Contact';
        cont1.LastName = '02';
        //cont1.AccountId = acc1.Id; 
        cont1.AccountId = AccAgency.Id;
        cont1.Contact_Type__c = 'Agent';
        cont1.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        //cont1.Group__c = group2.Id;        
        //insert cont1;
        lstCont.add(cont1);
        
        insert lstCont;
        //insert cont;
        cont.Id = lstCont[0].Id;
        cont1.Id = lstCont[1].Id;       
        
        
        Member__c member = new Member__c();
        member.Member__c = cont.Id;
        member.Group__c = group11.Id;
        insert member;   
        
        // Zaid Added this
        
        Case case4 = new Case();
        case4.AccountId=acc1.Id;
        case4.ContactId = cont1.Id;
        //case4.RecordTypeId = [Select r.SobjectType, r.Id, r.Name  From RecordType r WHERE r.SobjectType = 'Case' AND r.Name = 'Policy Services'  LIMIT 1].Id;
        case4.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Policy Services').getRecordTypeId();
        case4.Status='New';
        case4.Priority = 'Medium';
        case4.Type = 'New Business Setup';
        case4.Origin = 'newbusiness@usablelife.com';
        //case4.Reason = 'Group';
        case4.Reason = 'Agency Relationship';
        
        insert case4;      
        
        Test.stopTest();    
    }
    
    /*static testMethod void myUnitTest2() {
        Test.startTest();
        
        // These Lines are added by Zaid to correct the test class
        
        Id RecordTypeIdPR = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner Rep').getRecordTypeId();
        Id RecordTypeIdAgent = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        Id RecordTypeIdGroup = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeId();
        Id RecordTypeIdMember = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        
        //insert county
        county__c countyTest = USAbleUtility.CreateCounty();
        insert countyTest;
        
        string BC_Code_1 = 'A008';
        string Segment_1 = 'Mid-Market';
        
        //insert partner account
        Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        insert acc_partner;
        
        List <Account> lstAcc = New List<Account>();
        Account acc1= new Account();
        acc1.Name='Account 2';
        //acc1.RecordTypeId = [Select r.SobjectType, r.Id, r.Name  From RecordType r WHERE r.SobjectType = 'Account' AND r.Name = 'Master Group'  LIMIT 1].Id;
        acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        acc1.Type = 'Master Group';
        acc1.Industry = 'Computer';
        acc1.ShippingCountry = 'US';
        acc1.BillingStreet = '16th';
        acc1.BillingCity = 'Chicago';
        acc1.BillingState = 'IL';
        acc1.BillingCountry = 'US';
        acc1.BillingPostalCode = '25250';        
        
        lstAcc.add(acc1);
        
        Account AccAgency = New Account();
        AccAgency = USAbleUtility.CreateAgencyAccount();
        AccAgency.BillingStreet = 'asd';
        AccAgency.BillingCity = 'asd';
        AccAgency.BillingState = 'asd';
        AccAgency.BillingCountry = 'asd';
        AccAgency.BillingPostalCode = '123';
        lstAcc.add(AccAgency);
        
        Account acc= new Account();
        acc.Name='Account 1';
        //acc.RecordTypeId = [Select r.SobjectType, r.Id, r.Name  From RecordType r WHERE r.SobjectType = 'Account' AND r.Name = 'Master Group'  LIMIT 1].Id;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        acc.Type = 'Master Group';
        acc.Industry = 'Computer';
        acc.ShippingCountry = 'US';
        acc.BillingStreet = '16th';
        acc.BillingCity = 'Chicago';
        acc.BillingState = 'IL';
        acc.BillingCountry = 'US';
        acc.BillingPostalCode = '25250';
        
        // Zaid code here
        acc.Partner__c = acc_partner.Id;
        acc.Blue_Territory_Code__c = BC_Code_1 ;
        acc.Market_Segment__c = Segment_1;
        acc.County__c = countyTest.Id;
        // Zaid code ends here
        
        lstAcc.add(acc);
        
        insert lstAcc;
        acc1.Id = lstAcc[0].Id;
        AccAgency.Id = lstAcc[1].Id;
        acc.Id = lstAcc[2].Id;  
        
        Group__c group2 = new Group__c();
        group2.Name = 'Test group2';
        group2.Master_Group__c = acc1.Id;        
        insert group2;      
        
        List<Contact> lstCont = new List<Contact>();
        Contact cont1 = new Contact();
        cont1.FirstName = 'Contact';
        cont1.LastName = '02';
        //cont1.AccountId = acc1.Id; 
        cont1.AccountId = AccAgency.Id;
        cont1.Contact_Type__c = 'Agent';
        cont1.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
        //cont1.Group__c = group2.Id;        
        //insert cont1;
        lstCont.add(cont1);
        
        Contact cont11 = new Contact();
        cont11.FirstName = 'Contact';
        cont11.LastName = '001';
        cont11.AccountId = acc.Id; 
        cont11.Contact_Type__c = 'Member';
        cont11.RecordTypeId = RecordTypeIdGroup; // This line is added by Zaid
        
        //insert cont11;
        lstCont.add(cont11);        
        insert lstCont;
        
        cont1.Id = lstCont[0].Id;
        cont11.Id = lstCont[1].Id;
        
        
        Case case3 = new Case();
        case3.AccountId=acc1.Id;
        case3.ContactId = cont1.Id;
        //case3.RecordTypeId = [Select r.SobjectType, r.Id, r.Name  From RecordType r WHERE r.SobjectType = 'Case' AND r.Name = 'Policy Services'  LIMIT 1].Id;
        case3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Policy Services').getRecordTypeId();
        case3.Status='New';
        case3.Priority = 'Medium';
        case3.Type = 'New Business Setup';
        case3.Origin = 'newbusiness@usablelife.com';
        case3.Reason = 'Agent/Member';
        case3.Member__c = cont11.Id; 
        
        insert case3;        
        
        Test.stopTest();    
    }*/
    
}