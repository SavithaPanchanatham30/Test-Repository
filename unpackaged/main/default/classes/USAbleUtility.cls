/*
    Name        : USAbleUtility
    Author      : Munazza Ahmed
    Date        : 7/19/2016
    Purpose : Utility class that can be used for future test classes.

    Author      : Munazza Ahmed
    Date        : 7/19/2016
    Purpose     : Set Valid State and Country Code in test method. Also this is a utility class for test classes, so mark it as a Test
    
*/
@isTest
public with sharing class USAbleUtility
{
    //variables that will be used
    static id AgencyRTId;
    static id MasterGroupRTId;
    static id PartnerRTId;
    static id ProspectId;
    
    //create account of agency recordtype
    public static account CreateAgencyAccount()
    {
        //query appropriate recordtype
        List<Recordtype> ListOfAccRt = [SELECT Name, Id
            FROM Recordtype
        WHERE Sobjecttype = 'Account'];
        for(recordtype rt : ListOfAccRt)
        {
            if(rt.Name == 'Agency')
            {
                AgencyRTId = rt.id;
            }
        }
        Account acc = new Account();
        acc.recordtypeid = AgencyRTId;
        acc.Name = 'Test Account Agency';
        acc.Type = 'Agency';
        acc.BillingStreet  = 'test street';
        acc.BillingCity = 'test city';
        acc.BillingState = 'FL';
        acc.BillingPostalCode = '1234';
        return acc;
    }
    //create account of master group recordtype
    public static account CreateMasterGroupAccount()
    {
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
        Account acc = new Account();
        acc.recordtypeid = MasterGroupRTId;
        acc.Name = 'Test Account Master Group';
        acc.Type = 'Master Group';
        acc.BillingStreet  = 'test street';
        acc.BillingCity = 'test city';
        acc.BillingState = 'FL';
        acc.BillingPostalCode = '1234';
        return acc;
    }
    
    // create account of prospect record type
    public static account CreateProspectAccount()
    {
        Id ProspectRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        Account acc = new Account();
        acc.recordtypeid = ProspectRecordTypeId;
        acc.Name = 'Test Account Prospect';
        acc.Type = 'Prospect';
        acc.BillingStreet  = 'test street';
        acc.BillingCity = 'test city';
        acc.BillingState = 'FL';
        acc.BillingPostalCode = '1234';
        return acc;
    }
    
    
    //create account of partner recordtype
    public static account CreatePartnerAccount()
    {
        List<Recordtype> ListOfAccRt = [SELECT Name, Id
            FROM Recordtype
        WHERE Sobjecttype = 'Account'];
        for(recordtype rt : ListOfAccRt)
        {
            if(rt.Name == 'Partner')
            {
                PartnerRTId = rt.id;
            }
        }
        Account acc = new Account();
        acc.recordtypeid = PartnerRTId;
        acc.Name = 'Test Account Partner';
        acc.Type = 'Partner';
        return acc;
    }
    //create opportunity
    public static Opportunity CreateOpportunity(account acc)
    {
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acc.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; // stage of closed lost
        return Opp;
    }
    //create product
    public static Product2 CreateProuct()
    {
        Product2 prd = new Product2();
        prd.Name = 'Test Product';
        prd.Type__c = 'LSV';
        prd.ProductCode = 'Test Code';
        prd.Family = 'GRP LIFE';
        prd.Product_Category__c = 'True Group Life';
        prd.isActive  = true;
        return prd;
    }
    //create pricebook entry for opportunity line item
    public static PricebookEntry CreatePBE(Product2 prod)
    {
        id StdPdId = Test.getStandardPricebookId();  // get standard pricebook
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = StdPdId;
        pbe.Product2Id = prod.Id;
        pbe.UnitPrice = 100.00;
        pbe.IsActive = true;
        return pbe;
    }
    //create opportunity line item matching criteria for creation of asset with pursue stage
    public static OpportunityLineItem CreateOppLinePursue(opportunity opp, product2 prd,pricebookentry pbe)
    {
        id StdPdId = Test.getStandardPricebookId(); 
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.id;
        oli.UnitPrice = 0.00;
        oli.Quantity = 1;
        oli.PricebookEntryId = pbe.id;
        oli.Line_Item_Stage__c = 'Pursue';
        oli.Renewal_Date__c = date.today();
        oli.Competitor_Name__c = 'MetLife';
        oli.Rate_Guarantee__c = true;
        oli.Changed_Carrier__c = 'Yes';
        oli.Next_Renewal_Date__c = oli.Renewal_Date__c.addMonths(6);
        return oli;
        
    }
    //create opportunity line item matching criteria for creation of asset with closed lost stage
    public static OpportunityLineItem CreateOppLineItemClosedLost(opportunity opp, product2 prd,pricebookentry pbe)
    {
        id StdPdId = Test.getStandardPricebookId(); 
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.id;
        oli.UnitPrice = 1.00;
        oli.Quantity = 1;
        oli.PricebookEntryId = pbe.id;
        oli.Line_Item_Stage__c = 'Closed Lost - Quoted';
        oli.Changed_Carrier__c = 'Yes';
        oli.Closed_Reason__c = 'Bad Customer Experience';
        oli.Renewal_Date__c = date.today();
        oli.Competitor_Name__c = 'MetLife';
        oli.Rate_Guarantee__c = true;
        oli.Next_Renewal_Date__c = oli.Renewal_Date__c.addMonths(6);
        return oli;
        
    }
    //create agency master group
    public static Agency_MasterGroups__c CreateAgencyMasterGroup(account agency, account master)
    {
        Agency_MasterGroups__c am = new Agency_MasterGroups__c();
        am.Broker_Agency__c = agency.Id;
        am.Master_Group__c = master.Id;
        return am;
    }
    
    //create county
    public static county__c CreateCounty()
    {
        County__c countyTest = new County__c();
        countyTest.Name = 'Test County';
        countyTest.County_Code__c = '0089';
        countyTest.State_Code__c = '087';
        countyTest.State__c = 'FL';
        return countyTest;
    }
    
    //create account team assignment for blue territory method
    public static Account_Team_Assignment__c CreateAccountTeamAssignmentBlueTerritory(id partnerId, id userId, string Role, string BCRepCode)
    {
        Account_Team_Assignment__c ats = new Account_Team_Assignment__c();
        ats.Assignment_Method__c = 'Blue Territory';
        ats.Blue_Partner__c = partnerId;
        ats.BC_Rep_Code__c = BCRepCode;
        ats.Team_Role__c = Role;
        ats.User__c = userId;
        return ats;
    }
    //create account team assignment for market segment & county method
    public static Account_Team_Assignment__c CreateAccountTeamAssignmentSegmentCounty(id partnerId, id userId, string Role, Id countyId, string segment)
    {
        Account_Team_Assignment__c ats = new Account_Team_Assignment__c();
        ats.Assignment_Method__c = 'Market Segment & County';
        ats.Blue_Partner__c = partnerId;
        ats.Group_Segment__c = Segment;
        ats.County__c = countyId;
        ats.Team_Role__c = Role;
        ats.User__c = userId;
        return ats;
    }
    
    Id getRecordType(String strObject, String strDeveloperName)
    {
        List<RecordType> listRecordTypes = [SELECT Id, Name, DeveloperName FROM RecordType where Sobjecttype = :strObject and DeveloperName = :strDeveloperName limit 1];
        Id recTypeId;
        
        if (listRecordTypes != null && listRecordTypes.size() > 0)
        {
            recTypeId = listRecordTypes[0].Id;
        }
        
        return recTypeId;
    }
    
    public static contact createParnterRep ()
    {
        USAbleUtility util = new USAbleUtility();
        Id pRepRecordType = util.getRecordType('Contact', 'Partner_Rep');
        
        Contact con = new contact();
        
        con.FirstName = 'Clark';
        con.LastName  = 'Michael';
        con.Email = 'abc@test.com';
        con.Contact_Type__c = 'Partner Rep';
        con.Phone = '1234567';
        con.Title = 'Mr.';
        con.Partner_Rep_Territory_Code__c = 'A555';
        con.MailingState = 'FL';  
        con.RecordTypeId = pRepRecordType;
        
        insert con;
        return con;
    }
    
    public static Account createBrokerAgency()
    {
        USAbleUtility util = new USAbleUtility();
        Id pRepRecordType = util.getRecordType('Account', 'Agency');
        
        Account act = new Account();
        act.Name = 'Clark Company';
        act.Type = 'Broker Agency';
        act.BillingCity = 'Miami';
        act.BillingState = 'FL';
        act.Service_Flag__c = false;
        act.Group_Policy_num__c = '12345'; 
       // act.Agency_Code__c = '';
        act.Agency_Sub_Type__c = '';   
        act.RecordTypeId = pRepRecordType;
        
        insert act;
        return act;
    }
    
    public static Asset createAsset(Id vId)
    {
        //insert Product
        Product2 prd = new Product2();
        prd = USAbleUtility.CreateProuct(); //Product returned from utility class
        insert prd;
        
        //create asset
        asset ast = new asset();
        ast.name = 'GRP LIFE';
        ast.Product2Id = prd.Id;
        ast.AccountId = vId;
        ast.Renewal_date__c = date.today() + 1;
        ast.Carrier__c = 'BCBS';
        return ast;
    }
}