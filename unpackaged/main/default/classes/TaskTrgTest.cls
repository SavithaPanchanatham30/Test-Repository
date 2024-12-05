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
private class TaskTrgTest {

    static testMethod void myUnitTest() {
    
        
        string BC_Code_1 = 'A008';
        string Segment_1 = 'Mid-Market';
        //county__c countyTest = USAbleUtility.CreateCounty();
        //insert countyTest;
        
         //insert partner account
        //Account acc_partner = USAbleUtility.CreatePartnerAccount(); //account returned from utility class
        //insert acc_partner;
                
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
        //acc.Partner__c = acc_partner.Id;
        acc.Blue_Territory_Code__c = BC_Code_1 ;
        acc.Market_Segment__c = Segment_1;
        //acc.County__c = countyTest.Id;
        
        insert acc;
        
        
        Contact cont = new Contact();
        cont.FirstName = 'Contact';
        cont.LastName = '01';
        cont.AccountId = acc.Id; 
        cont.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Group Contact').getRecordTypeId();
        cont.Contact_Type__c = 'Group Contact';
        
        insert cont;
        
        User U = [select id from User WHERE Profile.Name Like '%Standard Claims User%' AND IsActive = true limit 1];
        Task t = new Task(Ownerid = U.id,Subject = 'Test',Whoid = cont.id,Whatid = Acc.id,Status = 'Pending',Priority = 'Low',Description = 'Test');
        insert t; //Note:While giving this insert check the required fields for task and include it above
        
        System.RunAs(u){
            Try{
                delete t;
                }
            catch (DmlException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' ,e.getDmlStatusCode(0) );
            }
        }
        
        // Zaid Code Ends Here
    }
}