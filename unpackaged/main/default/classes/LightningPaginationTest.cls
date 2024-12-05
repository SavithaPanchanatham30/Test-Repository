@isTest
public class LightningPaginationTest
{
    static testMethod void LightningPaginationTest()
    {
		Test.startTest();
         LightningPagination lp = new LightningPagination();
         lp.offst = 0;
         lp.total = 0;
         lp.hasprev = false;
         lp.hasnext = true;
         lp.totalRecs = 0;
         lp.showingRecsCnt = 0;        
        Test.stopTest();
    }
}