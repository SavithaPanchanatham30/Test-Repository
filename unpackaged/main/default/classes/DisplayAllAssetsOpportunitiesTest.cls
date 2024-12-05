@istest
public class DisplayAllAssetsOpportunitiesTest {
    public static testmethod void testmycontroller(){
        PageReference pageRef = Page.DisplayAssetsonOpp;
        Test.setCurrentPage(pageRef);

        //insert account
        Account acc = new Account();
        acc = USAbleUtility.CreateMasterGroupAccount(); //account returned from utility class
        insert acc;
        //insert Opportunity
        Opportunity opp = new Opportunity();
        opp = USAbleUtility.CreateOpportunity(acc); //opportunity returned from utility class
        opp.Effective_Date__c = date.today();
        insert opp;
        
        // Add parameters to page URL              
        ApexPages.currentPage().getParameters().put('id',opp.id);
        
        DisplayAllAssetsOpportunities ext;
        ApexPages.StandardController con = new ApexPages.StandardController(opp);
        ext = new DisplayAllAssetsOpportunities(con);

        
    }
}