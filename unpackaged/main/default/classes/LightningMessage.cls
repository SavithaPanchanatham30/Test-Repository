public class LightningMessage {
    /*
     Wrapper  Class to hold error and success message to  display in  lightning component 
    */
    @AuraEnabled public Boolean isSuccess;
    @AuraEnabled public String errorMsg; //error msg
    @AuraEnabled public String successMsg; //success msg
    
    public LightningMessage(){
        isSuccess = true;
        errorMsg = '';
        successMsg = '';
    }
}