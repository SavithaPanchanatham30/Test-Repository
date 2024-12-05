global without sharing class OppRenewalBatch implements Database.Batchable<sObject>, Database.stateful {
    final List<Id> AccId = new List <Id>();
    global Map <String, Opportunity_Batch__c> MapofRegionAndCS;
    global OppRenewalBatch(){
        system.debug('Without List Constructor');
    }
    global OppRenewalBatch(List <Id> lstAccId){
        AccId = lstAccId;
    }
    
    global Database.QueryLocator start (Database.BatchableContext BC){
        string Query;
        string CustomSettingQuery;
        string AccountId;
        //Map <String, Opportunity_Batch__c> MapofRegionAndCS = new Map <String, Opportunity_Batch__c>();
        
        if(AccId.size() > 0)
        {    
            // Querying the required data set
            Id AcId = AccId[0];
            Query = 'SELECT ID, Group_Anniversary_Date__c FROM Account Where Account.Id ='+AcId;
            system.debug('Query '+Query);
        }
        else{
            
            // Querying the required data set
            //Query = 'SELECT ID, Group_Anniversary_Date__c FROM Account Where Account.RecordType.DeveloperName = \'Master_Group\' AND Aniv_prior_four_months__c= TRUE';
            //system.debug('Query2 '+Query);
            
            // Zaid New Dynamic Functionality starts heres
            //CustomSettingQuery = 'SELECT ID, API_Name_of_field__c,    Blue_Partner_Id__c, AR__c, FL__c, Group_Size_Lower_Limit__c, Group_Size_Upper_Limit__c, HI__c, Number_of_Opportunities__c    FROM Opportunity_Batch__c  ';
            CustomSettingQuery = 'SELECT ID, API_Name_of_field__c,  Blue_Partner_Id__c, Group_Size_Lower_Limit__c, Group_Size_Upper_Limit__c, Number_of_Opportunities__c, Months_In_Advance__c    FROM Opportunity_Batch__c  WHERE Active__c = TRUE ';
            
            system.debug('Opp_AnniversaryDateBatch'+CustomSettingQuery );
        }
        
        return Database.getQueryLocator(CustomSettingQuery);
    
    
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity_Batch__c> lst_OppBatch){
        
         List <Opportunity_Batch__c> lst_OppBatchToSend = new List <Opportunity_Batch__c>();
         MapofRegionAndCS = new Map <String, Opportunity_Batch__c>();
         system.debug('list here in execute '+lst_OppBatch);
         for (Opportunity_Batch__c OppBatch : lst_OppBatch)
         {
             
             lst_OppBatchToSend.add(OppBatch); 
             MapofRegionAndCS.put(OppBatch.API_Name_of_field__c, OppBatch);
             //Database.executeBatch(new Opp_AnniversaryDateBatch_FetchAccounts(OppBatch.API_Name_of_field__c, OppBatch), 200);
             
         }
         system.debug('Map '+MapofRegionAndCS);
        
    }
    global void finish(Database.BatchableContext BC){
        for (String strReg : MapofRegionAndCS.keySet())
        {
            DateTime n = datetime.now().addMinutes(1);
             String cron = '';
             
             cron += n.second();
             cron += ' ' + n.minute();
             cron += ' ' + n.hour();
             cron += ' ' + n.day();
             cron += ' ' + n.month();
             cron += ' ' + '?';
             cron += ' ' + n.year();
             
             System.Debug('ah::MapofRegionAndCS Months_In_Advance__c ' + MapofRegionAndCS.get(strReg).Months_In_Advance__c);
            
             System.schedule('Schedule_OppHeader_'+strReg.replace('__c','')+'_'+n, cron, new Sch_OppRenewalHeaderCreationBatch(strReg, MapofRegionAndCS.get(strReg)));
            
        }
    }

}