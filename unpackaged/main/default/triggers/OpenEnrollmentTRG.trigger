trigger OpenEnrollmentTRG on Open_Enrollment__c (Before insert, Before Update) {
 List<Open_Enrollment__c> listOE = new List<Open_Enrollment__c >(); 
 List<Asset> Asst = New List<Asset>(); 
 List<Asset> SAsst = New List<Asset>(); 
 List<Asset> CAsst = New List<Asset>();    

For (Open_Enrollment__c OE : Trigger.new) 
{ if (Trigger.isInsert ||  OE.Related_Asset__c == Null) {
     ID MGID  = OE.Master_GroupID__c;
     String OEProduct = OE.Product_Type__c; 
     String SProduct = OE.Product_TYPE__C + ' Spouse';
     String CProduct = OE.Product_Type__C + ' Child'; 
    Asst =  [Select ID from Asset 
                            Where Asset.AccountID = :MGID And Asset.Product2.Name = :OEProduct And Asset.Active_Formula__c = True Limit 1];
    SAsst =  [Select ID, Current_Premium__c from Asset 
                            Where Asset.AccountID = :MGID And Asset.Product2.Name = :SProduct And Asset.Active_Formula__c = True Limit 1];
    CAsst =  [Select ID, Current_Premium__c from Asset 
                            Where Asset.AccountID = :MGID And Asset.Product2.Name = :CProduct And Asset.Active_Formula__c = True Limit 1];
   For (Asset AT : Asst)
    { OE.Related_Asset__c = AT.ID;
    //    FOR (Asset SAT : Sasst) {OE.Starting_Spouse_Premium__c = SAT.Current_Premium__c;}
    //    FOR (Asset CAT : Casst) {OE.Starting_Dependent_Premium__c = CAT.Current_Premium__c;}
   
 }
}
}
}