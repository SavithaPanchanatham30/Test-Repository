global without sharing class OppRenewalLineItemCreationBatch implements Database.Batchable<sObject>{
    
    Final Set <Id> SetOppId;
    Final Map <Id, Set<Id>> MapAccIdProId;
    Final List <OpportunityLineItem> lstOLI = new List <OpportunityLineItem>();
    List <Product2> lstProduct = new list <Product2>();
    list <PricebookEntry> lstPBE = new list <PricebookEntry>();
    list <Account> lstAccount;
    Map <Id, Id> MapOfProductIdPBE;
    
    Global OppRenewalLineItemCreationBatch(Set <Id> OppIds, Map <Id, Set<Id>> MapAccIdProdId){        
        SetOppId = OppIds;
        MapAccIdProId = new Map<Id, Set<Id>>(MapAccIdProdId);        
    }
    
    global Database.QueryLocator start (Database.BatchableContext BC){
        String Query;
        Query = 'SELECT ID, Name, AccountId FROM Opportunity Where Id IN :SetOppId';
        
        return Database.getQueryLocator(Query);  
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> lstOppFinal){
        
        lstProduct = [Select Id, Name from Product2 WHERE Product_Line_for_Opp__c = true];
        lstPBE = [SELECT Id,Name,Product2Id,UnitPrice FROM Pricebookentry WHERE PriceBook2.IsStandard=true AND IsActive = true];
        lstAccount = [SELECT Id, Name, Sales_Primary_Agency__c, Group_Anniversary_Date__c From Account where id IN : MapAccIdProId.keySet()];
        
        MapOfProductIdPBE = new Map <Id, Id>();
        for (PricebookEntry PP : lstPBE)
        {
            MapOfProductIdPBE.put(PP.Product2Id, PP.id);
        }
        List <Opportunity> lst_Opp = new List <Opportunity>();
        Map <Id, Account> MapAcc = new Map <Id,Account>(lstAccount);
        
        for (Opportunity Opp : lstOppFinal){
            
            lst_Opp.add(Opp);   
        }
        
        for (Opportunity O : lst_Opp)
        {
            Set <Id> SetPIds = new Set <Id>();
            
            if (MapAccIdProId.containskey(O.AccountId) )
            {
                SetPIds = MapAccIdProId.get(O.AccountId);
                For (Product2 P : lstProduct)
                {
                    if(!SetPIds.contains(P.Id))
                    {
                        OpportunityLineItem OLI = new OpportunityLineItem();
                        OLI.Line_Item_Stage__c = 'Pursue';
                        OLI.Quantity = 1;
                        OLI.Sales_Price_Custom__c = 0;
                        OLI.Broker_Agency__c = MapAcc.get(O.AccountId).Sales_Primary_Agency__c;                        
                        OLI.Next_Renewal_Date__c = MapAcc.get(O.AccountId).Group_Anniversary_Date__c.addMonths(12);
                        if (MapOfProductIdPBE.containskey(P.Id))
                        {
                            OLI.PricebookEntryId = MapOfProductIdPBE.get(P.Id);
                            OLI.OpportunityId = O.Id;
                            lstOLI.add(OLI);
                        }
                        else
                            system.debug('No Value found in PBE '+P.Id);
                    }
                }
            }
        }
        if (lstOLI.size() > 0)
            insert lstOLI;
    }
    
    global void finish(Database.BatchableContext BC){      
                
    }
}