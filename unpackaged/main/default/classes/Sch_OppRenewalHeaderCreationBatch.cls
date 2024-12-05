global class Sch_OppRenewalHeaderCreationBatch implements Schedulable{
    Final String RegionStr;
    Opportunity_Batch__c OppBat;
    
    Global Sch_OppRenewalHeaderCreationBatch(String str, Opportunity_Batch__c OBat){
        RegionStr = str;
        OppBat = new Opportunity_Batch__c();
        OppBat = OBat;
    }
    
    global void execute(SchedulableContext sc){
        
        database.executeBatch(new OppRenewalHeaderCreationBatch(RegionStr,OppBat));
        //database.executeBatch(new TestBatch(RegionStr,OppBat));
        
    }
}