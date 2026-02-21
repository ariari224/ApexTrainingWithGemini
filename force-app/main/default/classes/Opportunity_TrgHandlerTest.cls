@isTest
public with sharing class Opportunity_TrgHandlerTest {
    public Opportunity_TrgHandlerTest() {

    }
    @TestSetup
    static void setupTestData() {
        // テストデータの作成
        List<Account> accList = new List<Account>();
        // Bronzeランク
        accList.add(new Account(Name = 'Bronze Account', Rank__c = 'Bronze'));
        // Silverランク
        accList.add(new Account(Name = 'Silver Account', Rank__c = 'Silver'));
        // Goldランク
        accList.add(new Account(Name = 'Gold Account', Rank__c = 'Gold'));
        // ランクなし（null）
        accList.add(new Account(Name = 'NoRank Account', Rank__c = null));
        // デフォルト用
        accList.add(new Account(Name = 'Test Account', Description = 'test', Rank__c = 'Bronze'));
        
        insert accList;

        // 更新系テスト用の商談作成
        Account defaultAcc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', 
            AccountId = defaultAcc.Id, 
            StageName = 'Prospecting', 
            CloseDate = Date.today(),
            Amount = 100000
        );
        insert opp;
    }

    @IsTest
    static void testOnAfterUpdate() {
        // 商談をClosed Wonに更新
        Opportunity targetOpp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opportunity'];
        targetOpp.StageName = 'Closed Won';
        update targetOpp;

        // タスクが作成されたことを検証
        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :targetOpp.Id];
        System.assertEquals(1, tasks.size(), '1つのタスクが作成されていること');
        System.assertEquals('契約手続きを開始してください', tasks[0].Subject, 'タスクの件名が正しいこと');
    }

    @isTest
    static void testBulkUpdate_OpportunityStageNameChange() {
        // 200件の商談を一括更新してもガバナ制限に引っかからないか検証
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i=0; i<200; i++) {
            opps.add(new Opportunity(
                Name = 'テスト商談' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert opps;

        Test.startTest();
        for(Opportunity o : opps){
            o.StageName = 'Closed Won';
        }
        update opps;
        Test.stopTest();

        System.assertEquals(200, [SELECT count() FROM Task]);
    }

    @isTest
    static void testUpdateAccountAmount() {
        Opportunity targetOpp = [SELECT Id, StageName, AccountId, Amount FROM Opportunity WHERE Name = 'Test Opportunity'];
        targetOpp.Amount = 200000;

        Test.startTest();
        update targetOpp;
        Test.stopTest();

        Account targetAcc = [SELECT Id, Description FROM Account WHERE Id=:targetOpp.AccountId LIMIT 1];
        System.assertEquals('現在の進行中商談の合計額は ¥200,000 です', targetAcc.Description, '集計処理が失敗しています。');
    }

    @isTest
    static void testCreateOpp() {
        Opportunity opp = new Opportunity(
            Name = 'new Opp',
            AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Amount = 300000
        );
        Test.startTest();
        insert opp;
        Test.stopTest();

        Opportunity targetOpp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'new Opp'];
        
        Account targetAcc = [SELECT Id, Description FROM Account WHERE Id=:targetOpp.AccountId LIMIT 1];
        System.assertEquals('現在の進行中商談の合計額は ¥400,000 です', targetAcc.Description, '集計処理が失敗しています。');
    }

    @isTest
    static void testDeleteOpp() {
        Opportunity targetOpp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opportunity'];
        Test.startTest();
        delete targetOpp;
        Test.stopTest();

        Account targetAcc = [SELECT Id, Description FROM Account WHERE Id=:targetOpp.AccountId LIMIT 1];
        System.assertEquals('現在の進行中商談はありません。', targetAcc.Description, '集計処理が失敗しています。');
    }

    @isTest
    static void testUndeleteOpp() {
        Opportunity targetOpp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opportunity'];
        Test.startTest();
        delete targetOpp;
        undelete targetOpp;
        Test.stopTest();

        Account targetAcc = [SELECT Id, Description FROM Account WHERE Id=:targetOpp.AccountId LIMIT 1];
        System.assertEquals('現在の進行中商談の合計額は ¥100,000 です', targetAcc.Description, '集計処理が失敗しています。');
    }

    @isTest
    static void testBronzeLimit() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Bronze Account' LIMIT 1];
        
        // 1. 正常系：上限ぴったり (500,000)
        Opportunity okOpp = new Opportunity(
            Name = 'OK Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(),
            Amount = 500000
        );
        Test.startTest();
        insert okOpp; // エラーにならないはず
        Test.stopTest();

        // 2. 異常系：上限オーバー (500,001)
        Opportunity opp = new Opportunity(
            Name = 'Error Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(),
            Amount = 500001 // 上限+1円
        );

        try {
            insert opp;
            System.assert(false, 'Bronzeランクの上限超過エラーが発生するはず');
        } catch (DmlException e) {
            // メッセージ内の金額フォーマットとスペースに注意して検証
            System.assert(e.getMessage().contains('Bronzeランクの取引先は'), 'ランク名が含まれていること');
            System.assert(e.getMessage().contains('500,000'), '上限額が含まれていること');
            System.assert(e.getMessage().contains('以上の商談を作成できません'), 'エラーメッセージの後半が正しいこと');
        }
    }

    @isTest
    static void testSilverLimit() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Silver Account' LIMIT 1];
        
        // 異常系：上限オーバー (5,000,001)
        Opportunity opp = new Opportunity(
            Name = 'Error Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(),
            Amount = 5000001
        );

        try {
            insert opp;
            System.assert(false, 'Silverランクの上限超過エラーが発生するはず');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Silverランクの取引先は'), 'ランク名が含まれていること');
            System.assert(e.getMessage().contains('5,000,000'), '上限額が含まれていること');
        }
    }

    @isTest
    static void testGoldLimit() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Gold Account' LIMIT 1];
        
        // Goldは上限なしなので、高額でもエラーにならない
        Opportunity opp = new Opportunity(
            Name = 'Rich Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(),
            Amount = 999999999
        );
        
        insert opp; // 例外が発生しなければOK
    }

    @isTest
    static void testNoRankLimit() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'NoRank Account' LIMIT 1];
        
        // 異常系：上限オーバー (100,001)
        Opportunity opp = new Opportunity(
            Name = 'Error Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(),
            Amount = 100001
        );

        try {
            insert opp;
            System.assert(false, 'ランク未設定の上限超過エラーが発生するはず');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('未設定ランクの取引先は'), 'ランク名が「未設定」となっていること');
            System.assert(e.getMessage().contains('100,000'), '上限額が含まれていること');
        }
    }
}