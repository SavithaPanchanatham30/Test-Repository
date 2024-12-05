@isTest
public class DependentPickListValueControllerTest
{
    static testMethod void DependentPickListValueControllerTest()
    {
        DependentPickListValueController pdlv = new DependentPickListValueController(); 
        Map<String,List<String>> gdo = DependentPickListValueController.GetDependentOptions('Opportunitylineitem','Line_Item_Stage__c','Closed_Reason__c');

    }
}