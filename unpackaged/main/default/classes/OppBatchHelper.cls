public class OppBatchHelper {
    
    public list <Opportunity> CreateOpp(Set <Id> SetofAccId){
        system.debug('OppBatchHelper Class '+SetofAccId);
        List <Account> lstAccounts = new list <Account>([SELECT ID, Name, Group_Anniversary_Date__c, Blue_Rep_Name__c,  Manually_Create_Opp__c, Manually_Create_Opp_User__c, LSV_Business__c FROM Account Where Id IN : SetofAccID]);
        List <Opportunity> lstOppToAdd = new List <Opportunity>();
        //Id EDIId = [SELECT Id, LastName FROM User where LastName = 'EDI' and IsActive = true limit 1].id;
        Id EDIId = [SELECT Id, LastName FROM User where LastName = 'SFAdmin' and IsActive = true limit 1].id;        
        Integer month;
        Integer year;
        system.debug('OppBatchAccounts '+lstAccounts);
        List <AccountTeamMember> lstACTMem = new List <AccountTeamMember>();
        lstACTMem = [SELECT AccountId,Id,TeamMemberRole,Title FROM AccountTeamMember where TeamMemberRole = 'Sales Executive' AND isdeleted = false];
        Map <Id, Id> MapofAccIdAndAccTMemId = new Map <Id, Id>();
        for (AccountTeamMember ACTM : [SELECT AccountId,Id,UserId, TeamMemberRole,Title FROM AccountTeamMember where AccountId IN : lstAccounts])
        {
            if(ACTM.TeamMemberRole == 'Sales Executive')
            {
                MapofAccIdAndAccTMemId.put(ACTM.AccountId, ACTM.UserId);
            }
        }
        
        
        for (Account AC : lstAccounts)
        {
            Opportunity Op = new Opportunity();
            Op.Name = 'New Opp.';
            //Op.Type = 'Cross Sell';
            Op.Effective_Date__c = AC.Group_Anniversary_Date__c;
            Op.AccountId = AC.Id;
            Op.Partner_Rep__c = AC.Blue_Rep_Name__c;
            Op.StageName = 'New';
            if(AC.Manually_Create_Opp__c == true)
            {
                Op.Batch_Created__c = false;
            }
            else{
                Op.Batch_Created__c = true;
            }
            
            //Sukesh Nandella - To account for the new Opp TYpes 05/16/2023
            
            if(AC.LSV_Business__c == 'Medical Only')
            {
                Op.Type = 'Cross Sell';
            }
            else{
                Op.Type = 'Up Sell';
            }
            
            if(MapofAccIdAndAccTMemId != null)
            {
                if(MapofAccIdAndAccTMemId.get(Op.AccountId) != null)
                {
                    Op.OwnerId = MapofAccIdAndAccTMemId.get(Op.AccountId);
                }
                else {
                    Op.OwnerId = EDIId;
                }
            }
            if (AC.Manually_Create_Opp__c == true)
                Op.OwnerId = AC.Manually_Create_Opp_User__c;
            
            month = AC.Group_Anniversary_Date__c.month();
            year = AC.Group_Anniversary_Date__c.year();
            /*
            if(month == 1)
            {
                year= year - 1;
                date myDate = date.newInstance(year, 12, 15);
                Op.CloseDate = myDate;
            }
            else {
                date mDate = date.newInstance(year, month - 1, 15);
                Op.CloseDate = mDate;
            }
            */
            
            //date mDate = date.newInstance(year, month + 1, 15);
            date mDate = AC.Group_Anniversary_Date__c;
            Op.CloseDate = mDate+14;
            
            
            lstOppToAdd.add(Op);
        }
        
        system.debug('List of Opp Created '+lstOppToAdd);
        insert lstOppToAdd;
        
        list <Account> lstAccountsToReupdate = new List <Account>();
        for (Account A : lstAccounts)
        {
            A.Run_Opp_Batch__c = false;
            A.Manually_Create_Opp__c = false;
            lstAccountsToReupdate.add(A);
        }
        update lstAccountsToReupdate;
        
        
        
        return lstOppToAdd;
    }

}