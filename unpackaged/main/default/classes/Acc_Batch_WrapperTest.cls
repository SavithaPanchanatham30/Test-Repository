@isTest
private class Acc_Batch_WrapperTest {
    static testmethod void test1() {
    
        //Insert Account For Florida
         Account Acc = new Account();
         Acc.name = 'Master Group Acc';
         Acc.Partner__c = '001i000000cN6g4';
         Acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
         Acc.LSV_Group_Size__c = 220 ;
         Acc.FL__c = true;
         
         //date myDate = date.newInstance(2016, 11, 15);
         date myDate = date.today().addMonths(5);
         Acc.Group_Anniversary_Date__c = myDate;
         Acc.Run_Opp_Batch__c = true;
         Acc.Manually_Create_Opp__c = true; 
         Acc.Manually_Create_Opp_User__c = '005i0000002OG7PAAW';
         insert Acc;
        
        Account Acc1 = new Account();
         Acc1.name = 'Master Group Acc1';
         Acc1.Partner__c = '001i000000cN6g4';
         Acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
         Acc1.LSV_Group_Size__c = 215 ;
         Acc1.FL__c = true;
         
         //date myDate = date.newInstance(2016, 11, 15);
         date myDate1 = date.today().addMonths(5);
         Acc1.Group_Anniversary_Date__c = myDate1;
         Acc1.Run_Opp_Batch__c = true;
         Acc1.Manually_Create_Opp__c = true;
         Acc1.Manually_Create_Opp_User__c = '005i0000002OG7PAAW';    
         insert Acc1;
         
         List <Id> lstAccId = new List <Id>();
         lstAccId.add(Acc.Id);
         
        
      
         List <Acc_Batch_Wrapper> lstAccBatch = new List <Acc_Batch_Wrapper>();
         lstAccBatch.add(new Acc_Batch_Wrapper(Acc));
         lstAccBatch.add(new Acc_Batch_Wrapper(Acc1));
         lstAccBatch.sort();         
        
         /*
         Acc_Batch_Wrapper Ta = new Acc_Batch_Wrapper(acc);
         Ta.act = acc;         
         Ta.compareTo(acc);
         
         Acc_Batch_Wrapper Sa = new Acc_Batch_Wrapper(acc1);
         
         System.assertEquals(-1,Ta.compareTo(Sa));
         */
         //system.assertEquals('Master Group Acc', lstAccBatch.get(0).act.name);
        
         
        

    
    }
}