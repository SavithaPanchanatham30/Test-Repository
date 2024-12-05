public class Opp_Batch_Invoceable {
    @InvocableMethod(label='Get Account Names' description='Returns the list of account names corresponding to the specified account IDs.')
    public static void getAccountNames(List<ID> ids) {
    system.debug('In Batch invockable class Account id here -> '+ids);
        Database.executeBatch(new OppRenewalHeaderCreationBatch(ids), 200);  
        
    }
    
    
}