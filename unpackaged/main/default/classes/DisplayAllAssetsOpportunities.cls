public class DisplayAllAssetsOpportunities {

    public Opportunity OpportunityInfo{get;set;}
    Public List<Asset> ast {get;set;}
    Public AggregateResult[] groupedResults {get;set;}
    
    public DisplayAllAssetsOpportunities (ApexPages.StandardController controller) {
        this.OpportunityInfo = (Opportunity)controller.getRecord();
        system.debug('Opp Info Here '+OpportunityInfo );
        Opportunity Opp = new Opportunity ();
        
        Opp = [Select Id, AccountId, Effective_Date__c  From Opportunity Where Id =: OpportunityInfo.Id ];
        Id AccId = [Select AccountId  From Opportunity Where Id =: OpportunityInfo.Id ].AccountId;
        system.debug('AccId '+AccId);
        Date d = Date.valueof(Opp.Effective_Date__c);
        //ast = [select ID, AccountId, name, Opp_Product_Category__c, Current_Premium__c, Current_Eligibles__c, Current_Contracts__c from Asset where Accountid=:AccId AND Active_Formula__c = true AND Renewal_Date__c <=: d  ORDER BY  Opp_Product_Category__c];
        
        //groupedResults = [Select   Opp_Product_Category__c, SUM(Current_Premium__c), SUM(Current_Eligibles__c), SUM(Current_Contracts__c), AccountId from Asset where Accountid=:AccId AND Active_Formula__c = true AND Renewal_Date__c <=: d  GROUP BY Opp_Product_Category__c, AccountId ];
        groupedResults = [select Account.Name a , Product2.Product_Category__c b, sum(Current_Premium__c) c , max(Current_Eligibles__c) d, max(Current_Contracts__c) e from Asset where Accountid=:AccId AND Active_Formula__c = true AND Effective_Date__c <=: d AND Competitor_Asset__c = false Group By Product2.Product_Category__c,Account.name];
        
        
        
        
        
//        OpportunityInfo=new Opportunity(id=OppId);
system.debug('zaid::ast ' + ast);
    }
    

}