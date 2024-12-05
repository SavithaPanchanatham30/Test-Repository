public class LightningPagination {
     @AuraEnabled public list<Opportunity> opp;
     @AuraEnabled public integer offst;
     @AuraEnabled public integer total;
     @AuraEnabled public boolean hasprev;
     @AuraEnabled public boolean hasnext;
     @AuraEnabled public integer totalRecs;
     @AuraEnabled public integer showingRecsCnt;
}