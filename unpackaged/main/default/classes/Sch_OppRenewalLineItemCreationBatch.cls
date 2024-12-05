Global class Sch_OppRenewalLineItemCreationBatch implements Schedulable{
    
    Set <Id> SetOpp{get;set;}
    Global map<Id,Set<Id>> mapAccountProdId{get;set;}
    
    Global Sch_OppRenewalLineItemCreationBatch(Set <Id> lstOp, Map <Id,Set<Id>> MapAccProdId){
        
        system.debug('here check '+MapAccProdId);
        SetOpp = lstOp;
        mapAccountProdId = new Map <Id,Set<Id>>(MapAccProdId);
    }
    
    global void execute(SchedulableContext sc){
        
        database.executeBatch(new OppRenewalLineItemCreationBatch(SetOpp,mapAccountProdId));
        
    }

}