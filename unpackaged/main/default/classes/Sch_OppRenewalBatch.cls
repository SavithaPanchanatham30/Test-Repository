/*

Purpose : To Execute the batch
Made By : Zaid Ali Darbar (Tectonic)
Date : 1-31-17

*/

global class Sch_OppRenewalBatch implements Schedulable {

    global void execute(SchedulableContext Scontext) 
    {
        // Intializing the Batch
        OppRenewalBatch oppRenewalBatch = new OppRenewalBatch();
        
        //Executing the batch
        Database.executeBatch(oppRenewalBatch, 200);
    }
}