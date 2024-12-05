@isTest
public class OpportunityCtrlTest {
	public static testmethod void getPartnerRepsTest()
    {
        Test.startTest();
        
        Contact con = USAbleUtility.createParnterRep();
        
        List<sObject> listObj = OpportunityCtrl.getPartnerReps('Clark');
        
        List<String> lstOppStages = OpportunityCtrl.getOpportunityStages();
        
        
        
        Test.stopTest(); 
    }
    
	public static testmethod void getBrokerAgencyTest()
    {
        Test.startTest();
        
        Account act = USAbleUtility.createBrokerAgency();
        
        List<sObject> listObj = OpportunityCtrl.getBrokerAgency('Clark');
        
        Test.stopTest(); 
    }  
    
    public static testmethod void oppCtrlTest()
    {
        Test.startTest();
        
        List<String> lstClsRea = OpportunityCtrl.getCloseReasonForNotQuoted();
        
        List<String> lstLIStagesHead = OpportunityCtrl.getLineItemStagesHeader();
        
        List<String> lstLIStages = OpportunityCtrl.getLineItemStages();
            
        List<String> lstOLIClsRea = OpportunityCtrl.getOLIClosedReason('Closed Won');
        
        List<String> lstCar = OpportunityCtrl.getChangedCarrier();
        
        List<String> lstLIClsRea = OpportunityCtrl.getLineItemClosedReasons();
        
        List<String> lstCompetitors = OpportunityCtrl.getLineItemCompetitors();
        
        
        
        Test.stopTest(); 
    } 
    
   /**
        * this table lists all the search permutations based on 
        * four fields of search filter component
        *+----------------+-------------+---------------+-------+
        *| Effective Date | Partner Rep | Broker Agency | Stage |
        *+----------------+-------------+---------------+-------+
        *| *              | *           | *             | *     |
        *| *              | *           | *             | null  |
        *| *              | *           | null          | null  |
        *| *              | *           | null          | *     |
        *| *              | null        | *             | *     |
        *| *              | null        | null          | *     |
        *| *              | null        | *             | null  |
        *| *              | null        | null          | null  |
        *+----------------+-------------+---------------+-------+
    **/
    //test search when all parameters are given                                         
    public static testmethod void getoppTest1()
    {
        Test.startTest();
        
        Contact pRep = USAbleUtility.createParnterRep();
		
        Account bAgency = USAbleUtility.createBrokerAgency();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        insert acct;
        
        //acct.Sales_Primary_Agency__c = bAgency.Id;
        //update acct;
        
        //acct.RecordType.DeveloperName = 'Prospect';
        acct.Type = 'Prospect';
        update acct;
        
        Opportunity Opp = new Opportunity(); 
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acct.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; 
        //opp.Partner_Rep__c = pRep.Id;
        opp.Effective_Date__c = date.today();
        opp.Type = 'New Business';
        insert Opp;        
        
        Product2 prod = USAbleUtility.CreateProuct();
            
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe);  
        
        LightningPagination lp = OpportunityCtrl.getOpp(false, false, 0, 4, 2017, pRep.Id, bAgency.Id, 'In Process', null, 'ASC');
        
        LightningPagination lp2 = OpportunityCtrl.getOpp(false, true, 26, 4, 2017, pRep.Id, bAgency.Id, 'In Process', null, 'ASC');
        
        List<sObject> lobj = OpportunityCtrl.getOpportunities(4, 2017, pRep.Id, bAgency.Id, 'In Process');
        
        Test.stopTest();
    }
    
    //test search when effective date, partner rep and broker agency are given                                         
    public static testmethod void getoppTest2()
    {
        Test.startTest();
        
        Contact pRep = USAbleUtility.createParnterRep();
		
        Account bAgency = USAbleUtility.createBrokerAgency();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        insert acct;
        
        //acct.Sales_Primary_Agency__c = bAgency.Id;
        //update acct;
        
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acct.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; 
       // opp.Partner_Rep__c = pRep.Id;
        opp.Effective_Date__c = date.today();
        
        insert Opp;        
        
        Product2 prod = USAbleUtility.CreateProuct();
            
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe);  
        
        LightningPagination lp = OpportunityCtrl.getOpp(false, false, 0, 4, 2017, pRep.Id, bAgency.Id, null, null, 'ASC');
        LightningPagination lp2 = OpportunityCtrl.getOpp(false, true, 26, 4, 2017, pRep.Id, bAgency.Id, null, null, 'ASC');
        List<sObject> lobj = OpportunityCtrl.getOpportunities(4, 2017, pRep.Id, bAgency.Id, null);
        
        Test.stopTest();
    }    
    
    //test search when effective date and partner rep are given                                         
    public static testmethod void getoppTest3()
    {
        Test.startTest();
        
        Contact pRep = USAbleUtility.createParnterRep();
		
        Account bAgency = USAbleUtility.createBrokerAgency();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        insert acct;
        
        //acct.Sales_Primary_Agency__c = bAgency.Id;
        //update acct;
        
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acct.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; 
       // opp.Partner_Rep__c = pRep.Id;
        opp.Effective_Date__c = date.today();
        
        insert Opp;        
        
        Product2 prod = USAbleUtility.CreateProuct();
            
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe);  
        
        LightningPagination lp = OpportunityCtrl.getOpp(false, false, 0, 4, 2017, pRep.Id, null, null, null, 'ASC');
        LightningPagination lp2 = OpportunityCtrl.getOpp(false, true, 26, 4, 2017, pRep.Id, null, null, null, 'ASC');
        List<sObject> lobj = OpportunityCtrl.getOpportunities(4, 2017, pRep.Id, null, null);
        
        Test.stopTest();
    }     
    
    //test search when effective date, partner rep and stage are given                                         
    public static testmethod void getoppTest4()
    {
        Test.startTest();
        
        Contact pRep = USAbleUtility.createParnterRep();
		
        Account bAgency = USAbleUtility.createBrokerAgency();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        insert acct;
        
        //acct.Sales_Primary_Agency__c = bAgency.Id;
        //update acct;
        
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acct.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; 
       // opp.Partner_Rep__c = pRep.Id;
        opp.Effective_Date__c = date.today();
        
        insert Opp;        
        
        Product2 prod = USAbleUtility.CreateProuct();
            
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe);  
        
        LightningPagination lp = OpportunityCtrl.getOpp(false, false, 0, 4, 2017, pRep.Id, null, 'In Process', null, 'ASC');
        LightningPagination lp2 = OpportunityCtrl.getOpp(false, true, 26, 4, 2017, pRep.Id, null, 'In Process', null, 'ASC');
        List<sObject> lobj = OpportunityCtrl.getOpportunities(4, 2017, pRep.Id, null, 'In Process');
        
        Test.stopTest();
    }    
    
    //test search when effective date, broker agency and stage are given                                         
    public static testmethod void getoppTest5()
    {
        Test.startTest();
        
        Contact pRep = USAbleUtility.createParnterRep();
		
        Account bAgency = USAbleUtility.createBrokerAgency();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        insert acct;
        
        //acct.Sales_Primary_Agency__c = bAgency.Id;
        //update acct;
        
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acct.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; 
      //  opp.Partner_Rep__c = pRep.Id;
        opp.Effective_Date__c = date.today();
        
        insert Opp;        
        
        Product2 prod = USAbleUtility.CreateProuct();
            
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe);  
        
        LightningPagination lp = OpportunityCtrl.getOpp(false, false, 0, 4, 2017, null, bAgency.Id, 'In Process', null, 'ASC');
        LightningPagination lp2 = OpportunityCtrl.getOpp(false, true, 26, 4, 2017, null, bAgency.Id, 'In Process', null, 'ASC');
        List<sObject> lobj = OpportunityCtrl.getOpportunities(4, 2017, null, bAgency.Id, 'In Process');
        
        Test.stopTest();
    }    
    
    //test search when effective date and stage are given                                         
    public static testmethod void getoppTest6()
    {
        Test.startTest();
        
        Contact pRep = USAbleUtility.createParnterRep();
		
        Account bAgency = USAbleUtility.createBrokerAgency();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        insert acct;
        
        //acct.Sales_Primary_Agency__c = bAgency.Id;
        //update acct;
        
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acct.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; 
        //opp.Partner_Rep__c = pRep.Id;
        opp.Effective_Date__c = date.today();
        
        insert Opp;        
        
        Product2 prod = USAbleUtility.CreateProuct();
            
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe);  
        
        LightningPagination lp = OpportunityCtrl.getOpp(false, false, 0, 4, 2017, null, null, 'In Process', null, 'ASC');
        LightningPagination lp2 = OpportunityCtrl.getOpp(false, true, 26, 4, 2017, null, null, 'In Process', null, 'ASC');
        List<sObject> lobj = OpportunityCtrl.getOpportunities(4, 2017, null, null, 'In Process');
        
        Test.stopTest();
    }  
    
    //test search when effective date and broker agency are given                                         
    public static testmethod void getoppTest7()
    {
        Test.startTest();
        
        Contact pRep = USAbleUtility.createParnterRep();
		
        Account bAgency = USAbleUtility.createBrokerAgency();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        insert acct;
        
        //acct.Sales_Primary_Agency__c = bAgency.Id;
        //update acct;
        
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acct.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; 
       // opp.Partner_Rep__c = pRep.Id;
        opp.Effective_Date__c = date.today();
        
        insert Opp;        
        
        Product2 prod = USAbleUtility.CreateProuct();
            
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe);  
        
        LightningPagination lp = OpportunityCtrl.getOpp(false, false, 0, 4, 2017, null, bAgency.Id, null, null, 'ASC');
        LightningPagination lp2 = OpportunityCtrl.getOpp(false, true, 26, 4, 2017, null, bAgency.Id, null, null, 'ASC');
        List<sObject> lobj = OpportunityCtrl.getOpportunities(4, 2017, null, bAgency.Id, null);
        
        Test.stopTest();
    }      
    
    //when effective date is given to search opportunities
    public static testmethod void getoppTest8()
    {
        Test.startTest();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        
        Opportunity opp = USAbleUtility.CreateOpportunity(acct);
        
        Product2 prod = USAbleUtility.CreateProuct();
            
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe);  
        
        LightningPagination lp = OpportunityCtrl.getOpp(false, false, 0, 4, 2017, null, null, null, null, 'ASC');
        LightningPagination lp2 = OpportunityCtrl.getOpp(false, true, 26, 4, 2017, null, null, null, null, 'ASC');
        List<sObject> lobj = OpportunityCtrl.getOpportunities(4, 2017, null, null, null);
        
        Test.stopTest();
    }    
    
    public static testmethod void saveOppTest()
    {
        Test.startTest();
        
        Contact pRep = USAbleUtility.createParnterRep();
		
        Account bAgency = USAbleUtility.createBrokerAgency();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        insert acct;
        
        //acct.Sales_Primary_Agency__c = bAgency.Id;
        //update acct;
        
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acct.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; 
       // opp.Partner_Rep__c = pRep.Id;
        opp.Effective_Date__c = date.today();
        insert Opp;
        
        Product2 prod = USAbleUtility.CreateProuct();
		insert prod;
        
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        insert pbe;
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe); 
        insert oli;
        
        String strRecords = 'x,' + opp.Id + '^' + 'Broker Relationship';
        List<String> lstString = new List<String>();
        lstString.add(strRecords);
        
        LightningMessage lm = OpportunityCtrl.saveOppRecords(lstString);   
        
        Test.stopTest();
    }
    
    public static testmethod void saveOLITest()
    {
        Test.startTest();
        
        Contact pRep = USAbleUtility.createParnterRep();
		
        Account bAgency = USAbleUtility.createBrokerAgency();
        
        Account acct = USAbleUtility.CreateMasterGroupAccount();
        insert acct;
        
        //acct.Sales_Primary_Agency__c = bAgency.Id;
        //update acct;
        
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.AccountId = acct.id;
        opp.CloseDate = date.today();
        opp.StageName = 'In Process'; 
       // opp.Partner_Rep__c = pRep.Id;
        opp.Effective_Date__c = date.today();
        insert Opp;
        
        Product2 prod = USAbleUtility.CreateProuct();
		insert prod;
        
        PricebookEntry pbe = USAbleUtility.CreatePBE(prod);  
        insert pbe;
        
        OpportunityLineItem oli = USAbleUtility.CreateOppLinePursue(opp, prod, pbe); 
        insert oli;
        
        String strRecords = ',' + oli.Id + '^0^Pursue^--None--^Aetna^08/01/2018^false^--None--';
        List<String> lstString = new List<String>();
        lstString.add(strRecords);
        
        LightningMessage lm = OpportunityCtrl.saveOLIRecords(lstString);   
        
        List<sObject> listObj = OpportunityCtrl.getOpportunityLineItem(opp.Id);
        
        Test.stopTest();
    }    
}