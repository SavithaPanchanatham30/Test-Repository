global without sharing class OppRenewalHeaderCreationBatch implements Database.Batchable<sObject>, Database.stateful{
    
    final String RegionAPI = null;
    final decimal MinGroupSize = null;
    Final decimal MaxGroupSize = null;
    Final decimal NumberofOpps = null;
    Final String BluePartnerId = null;
    Final integer MonthsInAdvance = null;
    Opportunity_Batch__c OppBat = null;
    
    Global List <Opportunity> lstOppToAdd = null;
    Global map<Id,Set<Id>> mapAccountAssets = new map<Id,Set<Id>>();
    Global List <Opportunity> lstOppReturn;
    
    List<Id> AccId = new List <Id>();
    Integer OppCount = 0;
    
    Global OppRenewalHeaderCreationBatch(List <Id> lstAccId){
        
        AccId = lstAccId;
        // Thse lines added for button click functionality

        Account Acc = new Account();
        Acc = [SELECT ID, NAME, FL__c, AR__c, HI__c FROM ACCOUNT WHERE ID IN : AccId LIMIT 1];
    }
    
    Global OppRenewalHeaderCreationBatch(String str, Opportunity_Batch__c OBat){
        
        RegionAPI = str;
        OppBat = new Opportunity_Batch__c();
        OppBat = OBat;
        MinGroupSize = OBat.Group_Size_Lower_Limit__c;
        MaxGroupSize = OBat.Group_Size_Upper_Limit__c;
        NumberofOpps = OBat.Number_of_Opportunities__c;
        BluePartnerId = OBat.Blue_Partner_Id__c;
        MonthsInAdvance = Integer.valueOf(OBat.Months_In_Advance__c);
        
        OppCount = 0;
        
        System.debug('MinGroupSize:'+MinGroupSize );
        System.debug('MaxGroupSize :'+MaxGroupSize );
        System.debug('NumberofOpps :'+NumberofOpps );
        System.debug('BluePartnerId :'+BluePartnerId );
        System.debug('ah::OppRenewalHeaderCreationBatch MonthsInAdvance :'+ MonthsInAdvance );
        
    }
    
    global Database.QueryLocator start (Database.BatchableContext BC){
        
        String Query;
        Id MasterGroupId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        lstOppReturn = new List <Opportunity>();
        
        if(AccId.size() > 0)
        {
            Id AcId = AccId[0];
            Query = 'SELECT ID, Group_Anniversary_Date__c, Blue_Rep_Name__c, Opportunity_Batch_Industry__c, LSV_Group_Size__c FROM Account Where Id = \''+AcId+'\'';
            return Database.getQueryLocator(Query);
        }       
        else 
        {
            Decimal monthsInAdvanceMinusOne = MonthsInAdvance - 1;
            //Query = 'SELECT ID, Group_Anniversary_Date__c, Blue_Rep_Name__c, Opportunity_Batch_Industry__c, LSV_Group_Size__c FROM Account Where '+RegionAPI+'= true AND RecordtypeId = \''+MasterGroupId+'\' AND Aniv_prior_four_months__c= true AND LSV_Group_Size__c >='+MinGroupSize+' AND LSV_Group_Size__c <='+MaxGroupSize+' AND Partner__c = \''+BluePartnerId+'\'ORDER BY LSV_Group_Size__c DESC';
            Query = 'SELECT ID, Group_Anniversary_Date__c, Blue_Rep_Name__c, Opportunity_Batch_Industry__c, LSV_Group_Size__c FROM Account Where '+RegionAPI+'= true AND RecordtypeId = \''+MasterGroupId+'\' AND Group_Anniversary_Date__c > NEXT_N_MONTHS:' + monthsInAdvanceMinusOne  + ' AND Group_Anniversary_Date__c = NEXT_N_MONTHS:' + MonthsInAdvance + ' AND LSV_Group_Size__c >='+MinGroupSize+' AND LSV_Group_Size__c <='+MaxGroupSize+' AND Partner__c = \''+BluePartnerId+'\'ORDER BY LSV_Group_Size__c DESC';
            system.debug('ah::Query ' + Query);
            return Database.getQueryLocator(Query);
        }
        
    }
    
    global void execute(Database.BatchableContext BC, List<Account> lst_MG){       
        List <Account> lst_Accounts = new List <Account>();
        Map <Id, Account> MapOfAccount = new Map <Id, Account>();
        Set <Id> SetofAccIdToSend = new Set <Id>();
        
        List <PricebookEntry> lstProductsTotal = New List <PricebookEntry>([SELECT Id,Name,Product2Id,UnitPrice FROM Pricebookentry WHERE IsActive = true]);
        List <Acc_Batch_Wrapper> lstAccBatch = new List <Acc_Batch_Wrapper>();
        
        // Iterating list of accounts and putting id against account in a map
        for (Account Acc : lst_MG){
            
            lst_Accounts.add(Acc);   
            MapOfAccount.put(Acc.Id, Acc);
            lstAccBatch.add(new Acc_Batch_Wrapper(Acc));
        }
        
        lstAccBatch.sort();
        

        if(RegionAPI == null)
        {
            // Iterating on assets to put Accountid and set of products against it in a map
            for (Asset A : [Select Id, Name, AccountId, Opp_ProductLine__c, Product2Id, Master_Group_Anniversary_Date__c from asset where  Accountid IN : lst_Accounts]) {
                
                if (mapAccountAssets.containsKey(A.AccountId)) {
                    
                    Set<Id> setOfIds = mapAccountAssets.get(A.AccountId);
                    
                    if(A.Master_Group_Anniversary_Date__c == MapofAccount.get(A.AccountId).Group_Anniversary_Date__c)
                    {
                        if (A.Opp_ProductLine__c != null)
                        setOfIds.add(A.Opp_ProductLine__c);
                        mapAccountAssets.put(A.AccountId,setOfIds);
                    }
                    
                } else {
                    Set<Id> setOfIds = new Set<Id>();
                    if(A.Master_Group_Anniversary_Date__c == MapofAccount.get(A.AccountId).Group_Anniversary_Date__c)
                    {
                        if (A.Opp_ProductLine__c != null)                    
                        setOfIds.add(A.Opp_ProductLine__c);
                        mapAccountAssets.put(A.AccountId,setOfIds);
                    }
                }
            }
            if (mapAccountAssets.size() < 1)
            {
                Set<Id> setOfIds = new Set<Id>();
                mapAccountAssets.put(lst_Accounts[0].Id, setOfIds );
            }        
        }
        else
        {
            // Iterating on assets to put Accountid and set of products against it in a map
            for (Asset A : [Select Id, Name, AccountId, Opp_ProductLine__c, Product2Id, Master_Group_Anniversary_Date__c from asset where Active_Formula__c = true AND Accountid IN : lst_Accounts]) {
                if (mapAccountAssets.containsKey(A.AccountId)) {
                    Set<Id> setOfIds = mapAccountAssets.get(A.AccountId);
                    if(A.Master_Group_Anniversary_Date__c == MapofAccount.get(A.AccountId).Group_Anniversary_Date__c)
                    {
                        if (A.Opp_ProductLine__c != null)
                        setOfIds.add(A.Opp_ProductLine__c);
                        mapAccountAssets.put(A.AccountId,setOfIds);
                    }                   
                } else {
                    Set<Id> setOfIds = new Set<Id>();
                    if(A.Master_Group_Anniversary_Date__c == MapofAccount.get(A.AccountId).Group_Anniversary_Date__c)
                    {
                        if (A.Opp_ProductLine__c != null)                    
                        setOfIds.add(A.Opp_ProductLine__c);
                        mapAccountAssets.put(A.AccountId,setOfIds);
                    }
                }
            }
        }
        
        system.debug('ah::line 146 ' + mapAccountAssets);
        // query assets for account ids
        List <Asset> lstAsset = new List <Asset>([Select Id, Name, AccountId, Product2Id from asset where Active_Formula__c = true AND Accountid IN : lst_Accounts]);
        Map <Id, Asset> MapofAccIDAsset = new Map <Id, Asset>();
        set <Id> SetofProduct2Id = new Set <Id>();
        
        // iterate on assets and put in May Key -> Accountid and Value -> Asset
        // get products ids in a set
        for (Asset A : lstAsset)
        {
            MapofAccIDAsset.put(A.AccountId, A);
            SetofProduct2Id.add(A.Product2Id);
        }
        
        List <Product2> lstProduct = new List <Product2>([SELECT Id,ProductCode,Product_Category__c FROM Product2 where Id IN : SetofProduct2Id ]);
        Map <Id, Product2> MapofProdID = new Map <Id, Product2>();
        Account Ac = new Account();
         
        Set <Id> setofAccoutsToAdd = new Set <Id>();
        
        for (Product2 P : lstProduct)
        {
            MapofProdID.put(P.Id, P);
        }
        //logic for AR only
        If (RegionAPI == 'AR__c')
        {
            for (Acc_Batch_Wrapper lstSortedAccount : lstAccBatch)
            {
                Ac = lstSortedAccount.act;
                for (Asset AA : lstAsset)
                {
                    if(AA.AccountId == Ac.id)
                    {
                        if(MapofProdID.get(AA.Product2Id).Product_Category__c == 'Medical' || Ac.Opportunity_Batch_Industry__c == 'School District')
                        {
                            if(OppCount < NumberofOpps)
                            {
                                If(mapAccountAssets.get(Ac.id).size() < lstProductsTotal.size() && !setofAccoutsToAdd.contains(Ac.id))
                                {
                                    setofAccoutsToAdd.add(Ac.Id);
                                    OppCount++;
                                }
                            } else {
                                break;
                            }   
                        }
                    }
                }
            }
            
            OppBatchHelper OppB = new OppBatchHelper();
            lstOppReturn.addAll(OppB.CreateOpp(setofAccoutsToAdd));
        }   
        // default logic for rest of the regions and cross sell click
        else
        {                        
            // default logic for rest of the regions
            if(AccId.size() == 0) {
                for (Acc_Batch_Wrapper lstSortedAccount : lstAccBatch)
                {
                    Ac = lstSortedAccount.act;
                    for (Asset AA : lstAsset)
                    {
                        if(AA.AccountId == Ac.id)
                        {
                            if(MapofProdID.get(AA.Product2Id).Product_Category__c == 'Medical')
                            {
                                If(OppCount < NumberofOpps) // only add number of Opps given from Custom Settings
                                {
                                    // DEBUG FOR TEST CLASS                               
                                    If(mapAccountAssets.get(Ac.id).size() < lstProductsTotal.size() && !setofAccoutsToAdd.contains(Ac.id))
                                    {
                                        setofAccoutsToAdd.add(Ac.Id);
                                        OppCount++;                                    
                                    }                                
                                } else {
                                    break;
                                }                            
                            }
                        }
                    }
                }
                
                OppBatchHelper OppB = new OppBatchHelper();
                lstOppReturn.addAll(OppB.CreateOpp(setofAccoutsToAdd));
            } 
            // dealing cross sell
            else {
                for (Account Acco : lst_Accounts)
                {
                    if(lstAsset.size() > 0)
                    {
                        for (Asset AA : lstAsset)
                        {
                            if(AA.AccountId == Acco.id)
                            {
                             setofAccoutsToAdd.add(Acco.Id);
                            }
                        }
                    }
                    else {
                        setofAccoutsToAdd.add(Acco.Id);
                    }
                }
                
                OppBatchHelper OppB = new OppBatchHelper();
                lstOppReturn = OppB.CreateOpp(setofAccoutsToAdd);
            }                        
        }        
    }
    
    global void finish(Database.BatchableContext BC){       
        if(lstOppReturn.size() > 0)
        {
            Set <Id> SetOpId = (new Map<Id,Opportunity>(lstOppReturn).keyset());     
             String cron = '';
             DateTime n = datetime.now().addMinutes(1);
             cron += n.second();
             cron += ' ' + n.minute();
             cron += ' ' + n.hour();
             cron += ' ' + n.day();
             cron += ' ' + n.month();
             cron += ' ' + '?';
             cron += ' ' + n.year();
            system.debug('ah::mapAccountAssets ' + mapAccountAssets);
            system.debug('ah::SetOpId ' + SetOpId);
             if(!Test.isRunningTest()){
                 System.schedule('Batch Create OLI_'+n, cron, new Sch_OppRenewalLineItemCreationBatch(SetOpId, mapAccountAssets));
             }              

        } 
    }
}