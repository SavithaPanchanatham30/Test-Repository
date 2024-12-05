public class OpportunityCtrl {
    /*
    @AuraEnabled
    public static List<Opportunity> getOpportunity() {
        //Opportunity opportunity = [SELECT Id, Account.Name, Name, Partner_Rep__r.Name FROM Opportunity where id = '006q0000007Vtfd'];
        List<Opportunity> opportunity = [SELECT Id, Account.Name, Name, Partner_Rep__r.Name FROM Opportunity limit 100];
        return opportunity;
    }
    */
    @AuraEnabled
    public static Integer isOppTeamMember(String strOppId, String strUserId)
    {
        Id loggedInUserId = UserInfo.getUserId();
        
        List<OpportunityTeamMember> listOTM = [select Id, OpportunityId, UserId from OpportunityTeamMember where opportunityid = :strOppId and userid = :loggedInUserId and OpportunityAccessLevel  = 'Edit'];

        if (loggedInUserId == strUserId || (listOTM != null && listOTM.size() > 0 ))
        {
            return 1;
        }
        else 
        {
            return 0;
        }
    }
    
    @AuraEnabled
    public static List<sObject> getPartnerReps(String term) {
        String soql = 
            ' SELECT Id, FirstName, LastName, Name, Email, Agent_Code__c, Contact_Type__c, Admin_System_Record__c, Account_Name__c, Phone, Title, Partner_Rep_Territory_Code__c, MailingState ' +
            ' FROM Contact '   +
            ' WHERE Name Like \'%' + String.escapeSingleQuotes(term) + '%\'' +
    		' AND RecordType.DeveloperName = \'Partner_Rep\'';
        return Database.query(soql);
    }     

    @AuraEnabled
    public static List<sObject> getBrokerAgency(String term) {
        String soql = 
            ' SELECT Id, Name, Type, BillingCity, BillingState, Service_Flag__c, Group_Policy_num__c, Agency_Code__c, Master_Agency_Record__c, Agency_Sub_Type__c ' +
            ' FROM Account '   +
            ' WHERE Name Like \'%' + String.escapeSingleQuotes(term) + '%\'' +
    		' AND RecordType.DeveloperName = \'Agency\'';
        return Database.query(soql);
    }     
    
    @AuraEnabled    
    public static List<String> getOpportunityStages()
    {
        List<String> options = new List<String>();
        options.add('--None--');
        
        //we are not using describe metadata call to fetch picklist values because
        //client has a specific requirement that we have to show picklist values on grid for Opportunity.StageName where IsClosed = false
        List<OpportunityStage> listOppStage = [select Id, ApiName from OpportunityStage where isClosed = false and IsActive = true];
        if (listOppStage != null && listOppStage.size() > 0)
        {
            for (OpportunityStage picklist: listOppStage) 
            {
                options.add(picklist.ApiName);
            }
        }
        return options;
    }    
    
	 public static Integer totalRecords = 0;
     private static Integer pagesize = 25;
     private static Integer offset;
     public String oppNameSort = '';
    
    /**
        * this table lists all the search permutations based on 
        * four fields of search filter component
        *+----------------+-------------+---------------+-------+
        *| Effective Date | Partner Rep | Broker Agency | Stage |
        *+----------------+-------------+---------------+-------+
        *| *              | *           | *             | *     |
        *| *              | *           | *             | null  |
        *| *              | *           | null          | null  |
        *| *              | *           | null          | *     |
        *| *              | null        | *             | *     |
        *| *              | null        | null          | *     |
        *| *              | null        | *             | null  |
        *| *              | null        | null          | null  |
        *+----------------+-------------+---------------+-------+
    **/
    @AuraEnabled
     public static LightningPagination getOpp(Boolean next, Boolean prev, Decimal off, 
                                              Integer intMonth, Integer intYear, String strPartnerRep, String strBrokerAgency, String strStageName,
                                             String sortColumn, String sortOrder){
        
         offset = (Integer) off;
         
        list<Opportunity> li = new list<Opportunity>();
         
        integer listlength = 0;
        String soql = '';
        Id loggedInUserId = UserInfo.getUserId();
                                                  
		system.debug('ah::sortColumn ' + sortColumn);  

        //this working is being added to check whether loggedin user is owner or part of opportunity team to show records in search results 
        //list/set is created to avoid "Semi join sub-selects are only allowed at the top level WHERE expressions and not in nested WHERE expressions" SOQL error  because we cannot use
        //sub-query with in OR condition                                       
		List<OpportunityTeamMember> listOppTM = [select Id, OpportunityId from OpportunityTeamMember where UserId =: loggedInUserId]; 
                                                 
		set<Id> setOppTM = new Set<Id>();
		if (listOppTM != null && listOppTM.size() > 0)
        {
            for (OpportunityTeamMember otm : listOppTM)
            {
                setOppTM.add(otm.OpportunityId);
            }
        }
         
        //when all four parameters are given
        if (intMonth != null && intYear != null && !String.isBlank(strPartnerRep) && !String.isBlank(strBrokerAgency) && !String.isBlank(strStageName))
        {
            soql = 'SELECT count() ' + 
                ' FROM Opportunity ' +
                ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                ' AND StageName = \'' + strStageName + '\'' +
                ' AND isClosed = false' +
                ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;           
            listlength +=  Database.countQuery(soql);
            
			totalRecords = listlength;
            
            if(next == false && prev == false)
             {
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                        ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                        ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                        ' AND StageName = \'' + strStageName + '\'' +
                        ' AND isClosed = false' +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ';
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
                        
    
                li = Database.query(soql);             
             }
             else if(next == true && (offset + pagesize) <= listlength)
             {
                 offset = offset + pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                     ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                     ' AND StageName = \'' + strStageName + '\'' +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(prev == true && offset > 0)
             {
                 offset = offset - pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                     ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                     ' AND StageName = \'' + strStageName + '\'' +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }             
        }
        //when effective date, partner rep and broker agency are given
        else if (intMonth != null && intYear != null && !String.isBlank(strPartnerRep) && !String.isBlank(strBrokerAgency) && String.isBlank(strStageName))
        {
            soql = 'SELECT count() ' + 
                ' FROM Opportunity ' +
                ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\''  +
                ' AND isClosed = false' +
                ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
            
            listlength +=  Database.countQuery(soql); 
            
            totalRecords = listlength;
            
             if(next == false && prev == false)
             {
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                        ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                        ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\''  +
                        ' AND isClosed = false' +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(next == true && (offset + pagesize) <= listlength)
             {
                 offset = offset + pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                     ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\''  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(prev == true && offset > 0)
             {
                 offset = offset - pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                     ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\''  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }             
        }

        //when effective date and partner rep are given
        else if (intMonth != null && intYear != null && !String.isBlank(strPartnerRep) && String.isBlank(strBrokerAgency) && String.isBlank(strStageName))
        {
            soql = 'SELECT count() ' + 
                ' FROM Opportunity ' +
                ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear  +
                ' AND isClosed = false' +
                ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
            
            listlength +=  Database.countQuery(soql);
            
            totalRecords = listlength;
            
            if(next == false && prev == false)
             {
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                        ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear  +
                        ' AND isClosed = false' +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(next == true && (offset + pagesize) <= listlength)
             {
                 offset = offset + pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                     ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(prev == true && offset > 0)
             {
                 offset = offset - pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                     ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }            
        }
         
        //when effective date, partner rep and stage are given
        else if (intMonth != null && intYear != null && !String.isBlank(strPartnerRep) && String.isBlank(strBrokerAgency) && !String.isBlank(strStageName))
        {
            soql = 'SELECT count() ' + 
                ' FROM Opportunity ' +
                ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                ' AND StageName = \'' + strStageName + '\''  +
                ' AND isClosed = false' +
                ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
            
            listlength +=  Database.countQuery(soql);   
            
            totalRecords = listlength;
            
            if(next == false && prev == false)
             {
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                        ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                        ' AND StageName = \'' + strStageName + '\''  +
                        ' AND isClosed = false' +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(next == true && (offset + pagesize) <= listlength)
             {
                 offset = offset + pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                     ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND StageName = \'' + strStageName + '\''  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(prev == true && offset > 0)
             {
                 offset = offset - pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                     ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND StageName = \'' + strStageName + '\''  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }             
        }
         
		//when effective date, broker agency and stage are given
        else if (intMonth != null && intYear != null && String.isBlank(strPartnerRep) && !String.isBlank(strBrokerAgency) && !String.isBlank(strStageName))
        {
            soql = 'SELECT count() ' + 
                ' FROM Opportunity ' +
                ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                ' AND StageName = \'' + strStageName + '\''  +
                ' AND isClosed = false' +
                ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
            
            listlength +=  Database.countQuery(soql);
            
            totalRecords = listlength;
            
             if(next == false && prev == false)
             {
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                        ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                        ' AND StageName = \'' + strStageName + '\''  +
                        ' AND isClosed = false' +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(next == true && (offset + pagesize) <= listlength)
             {
                 offset = offset + pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                     ' AND StageName = \'' + strStageName + '\''  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(prev == true && offset > 0)
             {
                 offset = offset - pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                     ' AND StageName = \'' + strStageName + '\''  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ';
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }             
        }
         
		//when effective date and stage are given
        else if (intMonth != null && intYear != null && String.isBlank(strPartnerRep) && String.isBlank(strBrokerAgency) && !String.isBlank(strStageName))
        {
            soql = 'SELECT count() ' + 
                ' FROM Opportunity ' +
                ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                ' AND StageName = \'' + strStageName + '\''  +
                ' AND isClosed = false' +
                ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
            
            listlength +=  Database.countQuery(soql);    
            
            totalRecords = listlength;
            
            if(next == false && prev == false)
             {
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                        ' AND StageName = \'' + strStageName + '\''  +
                        ' AND isClosed = false' +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(next == true && (offset + pagesize) <= listlength)
             {
                 offset = offset + pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND StageName = \'' + strStageName + '\''  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(prev == true && offset > 0)
             {
                 offset = offset - pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND StageName = \'' + strStageName + '\''  +
                     ' AND isClosed = false' +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }             
        }
         
        //when effective date and broker agency are given
        else if (intMonth != null && intYear != null && String.isBlank(strPartnerRep) && !String.isBlank(strBrokerAgency) && String.isBlank(strStageName))
        {
            soql = 'SELECT count() ' + 
                ' FROM Opportunity ' +
                ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                ' AND isClosed = false'  +
                ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
            
            listlength +=  Database.countQuery(soql);
            
            totalRecords = listlength;
            
             if(next == false && prev == false)
             {
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                        ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                        ' AND isClosed = false'  +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(next == true && (offset + pagesize) <= listlength)
             {
                 offset = offset + pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                     ' AND isClosed = false'  +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(prev == true && offset > 0)
             {
                 offset = offset - pagesize;
                 soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                     ' FROM Opportunity ' +
                     ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                     ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                     ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                     ' AND isClosed = false'  +
                     ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                     //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                     ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                     if (String.isBlank(sortColumn))
                     {
                         soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                     }
                     else
                     {
                         soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;  
                         
                     }
                 
                li = Database.query(soql);             
             }             
        }
         
        //when only effective date is given
        else if (intMonth != null && intYear != null && String.isBlank(strPartnerRep) && String.isBlank(strBrokerAgency) && String.isBlank(strStageName))
        {
            soql = 'SELECT count() ' + 
                ' FROM Opportunity ' +
                ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                ' AND isClosed = false ' +
                ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ; 
            
            listlength =  Database.countQuery(soql); 
            totalRecords = listlength;
            system.debug('ah::listlength ' + listlength);
            
             if(next == false && prev == false)
             {
                 //li = [Select id,name,accountSource,AccountNumber,Active__c from account LIMIT :pagesize OFFSET :offset];
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                        ' AND isClosed = false ' +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ; 
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(next == true && (offset + pagesize) <= listlength)
             {
                 system.debug('ah::next ' + next);
                 system.debug('ah::....offset ' + offset);
                 system.debug('ah::....pagesize ' + pagesize);
                 system.debug('ah::....listlength ' + listlength);                 
                 offset = offset + pagesize;
                 //li = [Select id,name,accountSource,AccountNumber,Active__c from account LIMIT :pagesize OFFSET :offset];
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                        ' AND isClosed = false ' +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                     //soql += ' ORDER BY ' + sortColumn + ' ' + 'ASC' + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
             else if(prev == true && offset > 0)
             {
                 system.debug('ah::prev ' + prev);
                 system.debug('ah::....offset ' + offset);
                 system.debug('ah::....pagesize ' + pagesize);
                 system.debug('ah::....listlength ' + listlength);                 
                 offset = offset - pagesize;
                 //li = [Select id,name,accountSource,AccountNumber,Active__c from account LIMIT :pagesize OFFSET :offset];
                soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                        ' FROM Opportunity ' +
                        ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                        ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                        ' AND isClosed = false ' +
                        ' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                        //' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' ;
                        ' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' ;
                        //' ORDER BY Partner_Rep__r.Name LIMIT :pagesize OFFSET :offset' ;
                 
                 if (String.isBlank(sortColumn))
                 {
                     //soql += ' ORDER BY Partner_Rep__r.Name, Name LIMIT :pagesize OFFSET :offset' ;
                     soql += ' ORDER BY Partner_Rep__r.Name, Name ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;
                 }
                 else
                 {
                     //soql += ' ORDER BY ' + sortColumn + ' LIMIT :pagesize OFFSET :offset' ;                     
                     soql += ' ORDER BY ' + sortColumn + ' ' + sortOrder + ' LIMIT :pagesize OFFSET :offset' ;                     
                 }
    
                li = Database.query(soql);             
             }
            system.debug('ah::pagesize ' + pagesize);
            system.debug('ah::offset ' + offset);
            system.debug('ah::soql ' + soql);
         }
         
         
        LightningPagination pg = new LightningPagination();
        pg.opp = li;
        pg.offst = offset;
		pg.totalRecs = totalRecords; 
		
		Integer showingRecs = offset + pagesize;  
		if (showingRecs >= totalRecords)
        {
            showingRecs = totalRecords;
        }
                                                 
        pg.showingRecsCnt = showingRecs;                                            
        pg.hasprev = hasprev(offset);   
        pg.hasnext = hasnxt(offset,listlength,pagesize);
             system.debug('ah::pg ' + pg);
            return pg;
         }
          
         private static boolean hasprev(integer off)
         {
            if(off>0)
                return false;
            return true; 
        }
        private static boolean hasnxt(integer off,integer li,integer ps)
        {
        if(off+ps<li)
            return false;
        return true;
    	}        
    
    @AuraEnabled
    public static List<sObject> getOpportunities(Integer intMonth, Integer intYear, String strPartnerRep, String strBrokerAgency, String strStageName)
    {
        String soql = '';
        /**
        * this table lists all the search permutations based on 
        * four fields of search filter component
        *+----------------+-------------+---------------+-------+
        *| Effective Date | Partner Rep | Broker Agency | Stage |
        *+----------------+-------------+---------------+-------+
        *| *              | *           | *             | *     |
        *| *              | *           | *             | null  |
        *| *              | *           | null          | null  |
        *| *              | *           | null          | *     |
        *| *              | null        | *             | *     |
        *| *              | null        | null          | *     |
        *| *              | null        | *             | null  |
        *| *              | null        | null          | null  |
        *+----------------+-------------+---------------+-------+
        **/
        
        Id loggedInUserId = UserInfo.getUserId();
        
		List<OpportunityTeamMember> listOppTM = [select Id, OpportunityId from OpportunityTeamMember where UserId =: loggedInUserId]; 

		set<Id> setOppTM = new Set<Id>();
		if (listOppTM != null && listOppTM.size() > 0)
        {
            for (OpportunityTeamMember otm : listOppTM)
            {
                setOppTM.add(otm.OpportunityId);
            }
        }        
        
        //when all four parameters are given
        if (intMonth != null && intYear != null && !String.isBlank(strPartnerRep) && !String.isBlank(strBrokerAgency) && !String.isBlank(strStageName))
        {
            soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                    ' FROM Opportunity ' +
                    ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                    ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                    ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                    ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                    ' AND StageName = \'' + strStageName + '\'' +
                	' AND isClosed = false' +
                	' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                	//' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' +
                	' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' +
                 	' ORDER BY Partner_Rep__r.Name' ;
        }
        //when effective date, partner rep and broker agency are given
        else if (intMonth != null && intYear != null && !String.isBlank(strPartnerRep) && !String.isBlank(strBrokerAgency) && String.isBlank(strStageName))
        {
            soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                    ' FROM Opportunity ' +
                    ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                    ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                    ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                    ' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\''  +
                	' AND isClosed = false' +
                	' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                	//' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' +
                	' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' +
                 	' ORDER BY Partner_Rep__r.Name' ;
        } 
        //when effective date and partner rep are given
        else if (intMonth != null && intYear != null && !String.isBlank(strPartnerRep) && String.isBlank(strBrokerAgency) && String.isBlank(strStageName))
        {
            soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                    ' FROM Opportunity ' +
                    ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                    ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                    ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear  +
                	' AND isClosed = false' +
                	' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                	//' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' +
                	' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' +
                 	' ORDER BY Partner_Rep__r.Name' ;
        } 
        //when effective date, partner rep and stage are given
        else if (intMonth != null && intYear != null && !String.isBlank(strPartnerRep) && String.isBlank(strBrokerAgency) && !String.isBlank(strStageName))
        {
            soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                    ' FROM Opportunity ' +
                    ' WHERE Partner_Rep__c = \'' + strPartnerRep + '\''  +
                    ' AND CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                    ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                	' AND StageName = \'' + strStageName + '\''  +
                	' AND isClosed = false' +
                	' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                	//' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' +
                	' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' +
                 	' ORDER BY Partner_Rep__r.Name' ;
        }     
		//when effective date, broker agency and stage are given
        else if (intMonth != null && intYear != null && String.isBlank(strPartnerRep) && !String.isBlank(strBrokerAgency) && !String.isBlank(strStageName))
        {
            soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                    ' FROM Opportunity ' +
                    ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                    ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                	' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                	' AND StageName = \'' + strStageName + '\''  +
                	' AND isClosed = false' +
                	' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                	//' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' +
                	' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' +
                 	' ORDER BY Partner_Rep__r.Name' ;
        }  
		//when effective date and stage are given
        else if (intMonth != null && intYear != null && String.isBlank(strPartnerRep) && String.isBlank(strBrokerAgency) && !String.isBlank(strStageName))
        {
            soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                    ' FROM Opportunity ' +
                    ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                    ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                	' AND StageName = \'' + strStageName + '\''  +
                	' AND isClosed = false' +
                	' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                	//' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' +
                	' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' +
                 	' ORDER BY Partner_Rep__r.Name' ;
        } 
        //when effective date and broker agency are given
        else if (intMonth != null && intYear != null && String.isBlank(strPartnerRep) && !String.isBlank(strBrokerAgency) && String.isBlank(strStageName))
        {
            soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                    ' FROM Opportunity ' +
                    ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                    ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                	' AND Account.Sales_Primary_Agency__c = \'' + strBrokerAgency + '\'' +
                	' AND isClosed = false'  +
                	' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                	//' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' +
                	' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' +
                 	' ORDER BY Partner_Rep__r.Name' ;
        }        
        //when only effective date is given
        else if (intMonth != null && intYear != null && String.isBlank(strPartnerRep) && String.isBlank(strBrokerAgency) && String.isBlank(strStageName))
        {
            soql = 'SELECT Id, Account.Name, Name, StageName, Account.Primary_Agency_Name__c, Partner_Rep__r.Name ' + 
                    ' FROM Opportunity ' +
                    ' WHERE CALENDAR_MONTH(Effective_Date__c) = ' + intMonth +
                    ' AND CALENDAR_YEAR(Effective_Date__c) = ' + intYear +
                	' AND isClosed = false ' +
                	' AND Id not IN (SELECT OpportunityId FROM OpportunityLineItem WHERE quoted__c = true) ' +
                	//' AND Id in (select OpportunityId from OpportunityTeamMember where UserId = :loggedInUserId) ' +
                	' AND ((Id in :setOppTM) OR (ownerId =  :loggedInUserId)) ' +
                 	' ORDER BY Partner_Rep__r.Name' ;
        }
        
        system.debug('ah::getOpportunities soql ' + soql);
        return Database.query(soql);
    }    
    
    @AuraEnabled
    public static List<String> getCloseReasonForNotQuoted()
    {
        Map<String,List<String>> pickValueMap = DependentPickListValueController.GetDependentOptions('Opportunitylineitem','Line_Item_Stage__c','Closed_Reason__c');
        system.debug(pickValueMap.get('Closed Lost - Not Quoted'));
        
        List<String> listString = pickValueMap.get('Closed Lost - Not Quoted');
        
        List<String> options = new List<String>();
        options.add('--None--');
        
        for (String str : listString)
        {
                options.add(str);
        
        }
        return options;
    }    
    
    @AuraEnabled 
    public static LightningMessage saveOppRecords(List<String> listChangedRecords){
        system.debug('ah::list<string>: ' + listChangedRecords);
        
        string  SUCCESS_MESSAGE = 'Records updated successfully';
        string  ERROR_MESSAGE = 'Error occurred. Unable to save records ';
        
        LightningMessage returnMessage = new LightningMessage();
        
        try {        
            Map<Id,String> mapChangedRecords = new Map<Id,String>();
        	listChangedRecords = listChangedRecords[0].split('\\,');
            system.debug('ah::listChangedRecords ' + listChangedRecords);
            
        	//loop is starting from 1 because we are bypassing changed record attribute's default value i.e. x
        	for (Integer i=1; i<listChangedRecords.size(); i++)
            //for (String listStr : listChangedRecords)
            {
                List<String> arr = new List<String>();
                //arr = listChangedRecords[i].remove('\'').split('\\^');
                arr = listChangedRecords[i].split('\\^');
				
                system.debug('ah::unescape ' + arr[1].replaceAll('\\\\', ''));
                
                mapChangedRecords.put(arr[0], arr[1].replaceAll('\\\\', ''));
                system.debug('ah::2: ' + arr);
            }

            system.debug('ah::mapChangedRecords ' + mapChangedRecords);
        	List<OpportunityLineItem> listOppLineItem;
			if (mapChangedRecords != null && mapChangedRecords.size() > 0)        	 
            {
                List<OpportunityLineItem> listOLI = [select Id, Line_Item_Stage__c, Closed_Reason__c, OpportunityId from OpportunityLineItem where OpportunityId in :mapChangedRecords.keySet() and Line_Item_Stage__c not in ('Closed Won', 'Closed Lost - Quoted', 'Closed Lost - Not Quoted')];
                
                if (listOLI != null && listOLI.size() > 0)
                {
                    listOppLineItem = new List<OpportunityLineItem>();
                    for (OpportunityLineItem oli : listOLI)
                    {
                        if (mapChangedRecords.containsKey(oli.OpportunityId))
                        {
                            oli.Line_Item_Stage__c = 'Closed Lost - Not Quoted';
                            oli.Closed_Reason__c = mapChangedRecords.get(oli.OpportunityId);
                            listOppLineItem.add(oli);
                        }
                    }
                }
                else
                {
                    returnMessage.isSuccess = false;
                    returnMessage.errorMsg = 'There are no products/opportunity line items on this opportunity to be closed.';                    
                }
            }
        
        	if (listOppLineItem != null && listOppLineItem.size() > 0)
            {
                system.debug('ah::listOppLineItem ' + listOppLineItem);
                update listOppLineItem;
            }
        }
        
         catch(Exception ex)
         {
            system.debug('Debug Exception Message'+ex.getMessage());
            returnMessage.isSuccess = false;
            
            //Adding the error message if an exception is occured
            returnMessage.errorMsg = ERROR_MESSAGE + ex.getMessage();
       }
        //Return the error message
        return returnMessage;             
    }    
    
    @AuraEnabled 
    public static LightningMessage saveOLIRecords(List<String> listChangedRecords){
        system.debug('ah::listChangedRecords ' + listChangedRecords);
        string  SUCCESS_MESSAGE = 'Records updated successfully';
        string  ERROR_MESSAGE = 'Error occurred. Unable to save records';
        
        LightningMessage returnMessage = new LightningMessage();
        
        try {
        	Map<Id, List<String>> mapChangedRecords = new Map<Id, List<String>>();
        	listChangedRecords = listChangedRecords[0].split('\\,');

        	//loop is starting from 1 because we are bypassing changed record attribute's default value i.e. x
        	for (Integer i=1; i<listChangedRecords.size(); i++)
            {
                List<String> arr = new List<String>();
                //arr = listChangedRecords[i].remove('\'').split('\\^');
                arr = listChangedRecords[i].split('\\^');
				
                mapChangedRecords.put(arr[0], arr); 
                system.debug('ah::2: ' + arr);
            }        

        	List<OpportunityLineItem> listOppLineItem;
			if (mapChangedRecords != null && mapChangedRecords.size() > 0)        	
            {
                List<OpportunityLineItem> listOLI = [select Id, UnitPrice, Line_Item_Stage__c, Closed_Reason__c, Competitor_Name__c, Next_Renewal_Date__c, Rate_Guarantee__c, Changed_Carrier__c from OpportunityLineItem where Id in :mapChangedRecords.keySet()];
                system.debug('ah::listOLI ' + listOLI);
                if (listOLI != null && listOLI.size() > 0)
                {
                    listOppLineItem = new List<OpportunityLineItem>();
                    for (OpportunityLineItem oli : listOLI)
                    {
                        if (mapChangedRecords.containsKey(oli.Id))
                        {
                            List<String> listOLIArray = mapChangedRecords.get(oli.Id);
                            system.debug('ah::listOLIArray ' + listOLIArray);
							system.debug('ah::listOLIArray[0] ' + listOLIArray[0]);                            
                            system.debug('ah::listOLIArray[1] ' + listOLIArray[1]);
                            system.debug('ah::listOLIArray[2] ' + listOLIArray[2]);
                            system.debug('ah::listOLIArray[3] ' + listOLIArray[3]);
                            system.debug('ah::listOLIArray[4] ' + listOLIArray[4]);
                            system.debug('ah::listOLIArray[5] ' + listOLIArray[5]);
                            system.debug('ah::listOLIArray[6] ' + listOLIArray[6]);
                            system.debug('ah::listOLIArray[7] ' + listOLIArray[7]);
                            
                            OpportunityLineItem oppLI = new OpportunityLineItem(Id=listOLIArray[0]);
                            
                            if (!String.isBlank(listOLIArray[1]))
                            {
                            	oppLI.UnitPrice = Decimal.valueOf(listOLIArray[1]);
                            }
                            
                            oppLI.Line_Item_Stage__c = listOLIArray[2].replaceAll('\\\\', '');
                            oppLI.Changed_Carrier__c = listOLIArray[3];
                            
                            String strCarrier = listOLIArray[3];
                            if (strCarrier.contains('--None--') || strCarrier.length() == 0 )
                            {
                            	oppLI.Changed_Carrier__c = null;
                                system.debug(1);
                            }
                            else
                            {
                                oppLI.Changed_Carrier__c = listOLIArray[3];
                                system.debug(1);
                            }
                            
                            String strCompetitorName = listOLIArray[4];
                            if (strCompetitorName.contains('--None--') || strCompetitorName.length() == 0 )
                            {
                            	oppLI.Competitor_Name__c = null;
                                system.debug(1);
                            }
                            else
                            {
                                oppLI.Competitor_Name__c = listOLIArray[4];
                                system.debug(1);
                            }
                            
                            if (!String.isBlank(listOLIArray[5]))
                            {
                            	oppLI.Next_Renewal_Date__c = date.parse(listOLIArray[5]);
                            }
                            
                            oppLI.Rate_Guarantee__c = Boolean.valueOf(listOLIArray[6]);
                            
                            String strClosedReason = listOLIArray[7];
                            if (strClosedReason.contains('--None--') || strClosedReason.length() == 0 )
                            {
                            	oppLI.Closed_Reason__c = null;
                                system.debug(7);
                            }
                            else
                            {
                                oppLI.Closed_Reason__c = listOLIArray[7] ;
                                system.debug(7);
                            }                            
							
                            listOppLineItem.add(oppLI);
                        }
                    }
                }
            }
        
        	if (listOppLineItem != null && listOppLineItem.size() > 0)
            {
                system.debug('ah::listOppLineItem ' + listOppLineItem);
                update listOppLineItem;
                returnMessage.successMsg=SUCCESS_MESSAGE;
            }   
        }
        
         catch(Exception ex)
         {
            system.debug('Debug Exception Message'+ex.getMessage());
            returnMessage.isSuccess = false;
            
            //Adding the error message if an exception is occured
            returnMessage.errorMsg = ERROR_MESSAGE + ex.getMessage();
       }
        //Return the error message
        return returnMessage;        
    }     
    
    @AuraEnabled    
    public static List<String> getLineItemStagesHeader()
    {
        List<String> options = new List<String>();
        options.add('--None--');
        Schema.DescribeFieldResult fieldResult = Opportunitylineitem.Line_Item_Stage__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklist: ple) 
        {
            options.add(picklist.getLabel());
        }
        return options;
    } 
    
    @AuraEnabled    
    public static List<String> getLineItemStages()
    {
        List<String> options = new List<String>();
        //options.add('--None--');
        Schema.DescribeFieldResult fieldResult = Opportunitylineitem.Line_Item_Stage__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklist: ple) 
        {
            options.add(picklist.getLabel());
        }
        return options;
    }    
    
    @AuraEnabled
    public static List<String> getOLIClosedReason(String strOLIStage)
    {
        Map<String,List<String>> pickValueMap = DependentPickListValueController.GetDependentOptions('Opportunitylineitem','Line_Item_Stage__c','Closed_Reason__c');
        system.debug('ah::strOLIStage ' + strOLIStage);
        system.debug('ah::strOLIStage ' + pickValueMap.get(strOLIStage));
        
        List<String> listString = pickValueMap.get(strOLIStage);
        system.debug('ah::listString ' + listString);
        List<String> options = new List<String>();
        options.add('--None--');
        
        if (listString != null && listString.size() > 0)
        {
            for (String str : listString)
                {
                        options.add(str);
                }
		}
        
        system.debug('ah::options ' + options);
        return options;
    }     
    
    @AuraEnabled    
    public static List<String> getChangedCarrier()
    {
        List<String> options = new List<String>();
        options.add('--None--');
        Schema.DescribeFieldResult fieldResult = Opportunitylineitem.Changed_Carrier__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklist: ple) 
        {
            options.add(picklist.getLabel());
        }
        return options; 
    }    
    
    @AuraEnabled    
    public static List<String> getLineItemClosedReasons()
    {
        List<String> options = new List<String>();
        options.add('--None--');
        Schema.DescribeFieldResult fieldResult = Opportunitylineitem.Closed_Reason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklist: ple) 
        {
            options.add(picklist.getLabel());
        }
        return options;
    }    
    
    @AuraEnabled    
    public static List<String> getLineItemCompetitors()
    {
        List<String> options = new List<String>();
        options.add('--None--');
        Schema.DescribeFieldResult fieldResult = Opportunitylineitem.Competitor_Name__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklist: ple) 
        {
            options.add(picklist.getLabel());
        }
        return options;
    }      
    
    @AuraEnabled
    public static List<sObject> getOpportunityLineItem(String oppId)
    {
        String soql = 'SELECT Id, Product2.Name, UnitPrice, Line_Item_Stage__c, Closed_Reason__c, Competitor_Name__c, Next_Renewal_Date__c, Rate_Guarantee__c, Changed_Carrier__c ' + 
            'FROM Opportunitylineitem where Opportunityid = \''+ oppId + '\'' + 
            ' ORDER BY Product2.Name'; 
        system.debug('ah:: ' + soql);
        return Database.query(soql);
    }
}