@isTest(SeeAllData=false)
Public Class TestOppRenewalHeaderCreationBatch{
    
    //@testSetup
    Public static testMethod void testData(){
        
        // Insert Custom Setting
        Opportunity_Batch__c NewCS = new Opportunity_Batch__c();
        NewCS.Name = 'FL';
        NewCS.Active__c = true;
        NewCS.API_Name_of_field__c = 'FL__c';
        NewCS.Group_Size_Lower_Limit__c = 50;
        NewCS.Group_Size_Upper_Limit__c = 300;
        NewCS.Blue_Partner_Id__c = '001i000000cN6g4';
        NewCS.Number_of_Opportunities__c = 1;
        NewCS.Months_In_Advance__c = 5;
        insert NewCS;
        
        /*
        // Insert Custom Setting for AR
        Opportunity_Batch__c NewCSAR = new Opportunity_Batch__c();
        NewCSAR.Name = 'AR';
        NewCSAR.Active__c = true;
        NewCSAR.API_Name_of_field__c = 'AR__c';
        NewCSAR.Group_Size_Lower_Limit__c = 20;
        NewCSAR.Group_Size_Upper_Limit__c = 5000;
        NewCSAR.Blue_Partner_Id__c = '001q000000eX3Ck';
        NewCSAR.Number_of_Opportunities__c = 1;
        insert NewCSAR;
        */
        
        //Insert Account For Florida
        Account Acc = new Account();
        Acc.name = 'Master Group Acc';
        Acc.Partner__c = '001i000000cN6g4';
        Acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        Acc.LSV_Group_Size__c = 220 ;
        Acc.FL__c = true;
        
        //date myDate = date.newInstance(2016, 11, 15);
        date myDate = date.today().addMonths(5);
        Acc.Group_Anniversary_Date__c = myDate;
        insert Acc;
        
        //insert Products
        List<Product2> lstProducts = new List<Product2>();
        
        Product2 p = new product2(name='x');
        lstProducts.add(p);
        
        Product2 p2 = new product2(name='y');
        p2.Product_Category__c = 'Medical';
        p2.IsActive = true;
        lstProducts.add(p2);
        
        insert lstProducts;
        
        
        //Insert Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(pricebook2id=Test.getStandardPricebookId(), product2id=p.id,unitprice=1.0, isActive=true);
        insert pbe;
        
        //Insert Assets
        List<Asset> lstAssets = new List<Asset>();
        
        Asset Ast = new Asset ();
        Ast.Name = 'Ast1';
        Ast.Carrier__c = 'AIG';
        Ast.AccountId = Acc.Id;
        Ast.Product2Id = p2.Id;
        Ast.Master_Group_Anniversary_Date__c = myDate;
        Ast.Renewal_Date__c = date.today().addDays(1);
        lstAssets.add(Ast);
        
        insert lstAssets;

        /*
        //Insert Account For Arkansas
        Account AccAR = new Account();
        AccAR.name = 'Master Group Acc';
        AccAR.Partner__c = '001q000000eX3Ck';
        AccAR.RecordTypeId = '012i0000001I8XYAA0';
        AccAR.LSV_Group_Size__c = 220 ;
        AccAR.AR__c = true;
        
        //date myDate = date.newInstance(2016, 11, 15);
        date myDateAR = date.today().addMonths(5);
        AccAR.Group_Anniversary_Date__c = myDateAR;
        insert AccAR;
        
        //Insert Assets For Arkansas
        List<Asset> lstAssetsAR = new List<Asset>();
        
        Asset AstAR = new Asset ();
        AstAR.Name = 'Ast1';
        AstAR.Carrier__c = 'AIG';
        AstAR.AccountId = AccAR.Id;
        AstAR.Product2Id = p2.Id;
        AstAR.Master_Group_Anniversary_Date__c = myDateAR;
        AstAR.Renewal_Date__c = date.today().addDays(1);
        lstAssetsAR.add(AstAR);
        
        insert lstAssetsAR;
        */
        Test.startTest();
             
             OppRenewalBatch B = new OppRenewalBatch();
             database.executeBatch(b);
            
             Test.stopTest();
      
    }
    
    
    Public static testMethod void BatchTest(){
         
            // Insert Custom Setting for AR
            Opportunity_Batch__c NewCSAR = new Opportunity_Batch__c();
            NewCSAR.Name = 'AR';
            NewCSAR.Active__c = true;
            NewCSAR.API_Name_of_field__c = 'AR__c';
            NewCSAR.Group_Size_Lower_Limit__c = 20;
            NewCSAR.Group_Size_Upper_Limit__c = 5000;
            NewCSAR.Blue_Partner_Id__c = '001i000000cN6Id';
            NewCSAR.Number_of_Opportunities__c = 1;
            NewCSAR.Months_In_Advance__c = 5;
            insert NewCSAR; 
            
            //insert Products
            List<Product2> lstProducts = new List<Product2>();
            
            Product2 p = new product2(name='x');
            lstProducts.add(p);
            
            Product2 p2 = new product2(name='y');
            p2.Product_Category__c = 'Medical';
            p2.IsActive = true;
            lstProducts.add(p2);
            
            insert lstProducts;
            
            
            //Insert Pricebook Entry
            PricebookEntry pbe = new PricebookEntry(pricebook2id=Test.getStandardPricebookId(), product2id=p.id,unitprice=1.0, isActive=true);
            insert pbe;
        
            //Insert Account For Arkansas
            Account AccAR = new Account();
            AccAR.name = 'Master Group Acc';
            AccAR.Partner__c = '001i000000cN6Id';
            AccAR.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
            AccAR.LSV_Group_Size__c = 220 ;
            AccAR.AR__c = true;
            
            //date myDate = date.newInstance(2016, 11, 15);
            date myDateAR = date.today().addMonths(5);
            AccAR.Group_Anniversary_Date__c = myDateAR;
            insert AccAR;
            
            //Insert Assets For Arkansas
            List<Asset> lstAssetsAR = new List<Asset>();
            
            Asset AstAR = new Asset ();
            AstAR.Name = 'Ast1';
            AstAR.Carrier__c = 'AIG';
            AstAR.AccountId = AccAR.Id;
            AstAR.Product2Id = p2.Id;
            AstAR.Master_Group_Anniversary_Date__c = myDateAR;
            AstAR.Renewal_Date__c = date.today().addDays(1);
            lstAssetsAR.add(AstAR);
        
            insert lstAssetsAR;
        
            Test.startTest();
             
             OppRenewalBatch B = new OppRenewalBatch();
             database.executeBatch(b);
            
             Test.stopTest();

    } 
    
    Public static testMethod void BatchTestOLI(){
        
        
        //Insert Account For Florida
        Account Acc = new Account();
        Acc.name = 'Master Group Acc';
        Acc.Partner__c = '001i000000cN6g4';
        Acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
        Acc.LSV_Group_Size__c = 220 ;
        Acc.FL__c = true;
        
        //date myDate = date.newInstance(2016, 11, 15);
        date myDate = date.today().addMonths(5);
        Acc.Group_Anniversary_Date__c = myDate;
        insert Acc;
        
        //insert Products
        List<Product2> lstProducts = new List<Product2>();
        
        Product2 p = new product2(name='x');
        lstProducts.add(p);
        
        Product2 p2 = new product2(name='y');
        p2.Product_Category__c = 'Medical';
        p2.IsActive = true;
        p2.Product_Line_for_Opp__c = true;
        lstProducts.add(p2);
        
        insert lstProducts;
        
        
        //Insert Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(pricebook2id=Test.getStandardPricebookId(), product2id=p.id,unitprice=1.0, isActive=true);
        insert pbe;
        
        //Insert Assets
        List<Asset> lstAssets = new List<Asset>();
        
        Asset Ast = new Asset ();
        Ast.Name = 'Ast1';
        Ast.Carrier__c = 'AIG';
        Ast.AccountId = Acc.Id;
        Ast.Product2Id = p2.Id;
        Ast.Master_Group_Anniversary_Date__c = myDate;
        Ast.Renewal_Date__c = date.today().addDays(1);
        lstAssets.add(Ast);
        
        insert lstAssets;

        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opp';
        Opp.AccountId = Acc.Id;
        Opp.Batch_Created__c = true;
        Opp.Type = 'New Business';
        Opp.StageName = 'New';
        DateTime nn = datetime.now();
        Opp.CloseDate = nn.date();
        Opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Opp.Effective_Date__c = nn.date();
        insert Opp;
        
        Map <Id,Set<Id>> mapAccountAssets = new map<Id,Set<Id>>();
        Set <Id> SetofId = new Set <Id>();
        Set <Id> SetofOppId = new Set <Id>();
        SetofOppId.add(Opp.Id);
        mapAccountAssets.put(Acc.Id, SetofId);
         Test.startTest();
         
         String cron = '';
                 DateTime n = datetime.now().addMinutes(1);
                 //cron += n.millisecond();
                 cron += n.second();
                 cron += ' ' + n.minute();
                 cron += ' ' + n.hour();
                 cron += ' ' + n.day();
                 cron += ' ' + n.month();
                 cron += ' ' + '?';
                 cron += ' ' + n.year();                 
            System.schedule('Batch Create OLI_'+n, cron, new Sch_OppRenewalLineItemCreationBatch(SetofOppId, mapAccountAssets));
        
         Test.stopTest(); 
    }
    
     Public static testMethod void BatchTestMethodOppBatchInvoke(){
         
         //Insert Account For Florida
         Account Acc = new Account();
         Acc.name = 'Master Group Acc';
         Acc.Partner__c = '001i000000cN6g4';
         Acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Master Group').getRecordTypeId();
         Acc.LSV_Group_Size__c = 220 ;
         Acc.FL__c = true;
         Acc.Manually_Create_Opp_User__c = '005i0000002OG7PAAW';
         
         //date myDate = date.newInstance(2016, 11, 15);
         date myDate = date.today().addMonths(5);
         Acc.Group_Anniversary_Date__c = myDate;
         Acc.Run_Opp_Batch__c = true;
         Acc.Manually_Create_Opp__c = true;
         insert Acc;
         
         List <Id> lstAccId = new List <Id>();
         lstAccId.add(Acc.Id);
         /*
         Test.startTest();
         Opp_Batch_Invoceable.getAccountNames(lstAccId);         
         Test.stopTest();
			*/
     }
    
    Public Static TestMethod void TestMethodSchOppRenewal(){
        
        
         String cron = '';
                 DateTime n = datetime.now().addMinutes(2);
                 //cron += n.millisecond();
                 cron += n.second();
                 cron += ' ' + n.minute();
                 cron += ' ' + n.hour();
                 cron += ' ' + n.day();
                 cron += ' ' + n.month();
                 cron += ' ' + '?';
                 cron += ' ' + n.year();                                    
         system.schedule('Job Name', cron, new Sch_OppRenewalBatch());
         //Sch_OppRenewalBatch ScOp = new Sch_OppRenewalBatch();
        
    }        
    
}