@isTest (SeeAllData=true)
private class CASE_HierarchyTest {
    static testMethod void myUnitTest2() {
    Case theCase =  [select ID, ParentID from Case where ParentID != null limit 1];
     Set<ID> AllParents = new Set<ID>();
     String fieldSetName = 'Case_Hierarchy';
     Boolean allDone = false; 
 //    AllParents.add(theCase.ID);
     String sObjName = theCase.ID.getSObjectType().getDescribe().getName();
   String returnCases =  CASE_Hierarchy.getHierarchiesQuickById (theCase.ID, sObjName);
        String jsonSerializedd = CASE_Hierarchy.getColumnJSON (fieldSetName,sObjName,false);   }
}