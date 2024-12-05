global class Acc_Batch_Wrapper implements Comparable {

    //public Opportunity oppy;
    public Account act;
    
    // Constructor
    public Acc_Batch_Wrapper(Account ac) {
        act = ac;
        system.debug('inside Acc Batch Wrapper Constructor '+act);
    }
    
    // Compare opportunities based on the opportunity amount.
    global Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        Acc_Batch_Wrapper compareToOppy = (Acc_Batch_Wrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (act.LSV_Group_Size__c < compareToOppy.act.LSV_Group_Size__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (act.LSV_Group_Size__c > compareToOppy.act.LSV_Group_Size__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}