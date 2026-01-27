@isTest
public with sharing class Opportunity_TrgHandlerTest {
    public Opportunity_TrgHandlerTest() {

    }
    @TestSetup
    static void setupTestData() {
        // テストデータの作成
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', 
            AccountId = acc.Id, 
            StageName = 'Prospecting', 
            CloseDate = Date.today()
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
}