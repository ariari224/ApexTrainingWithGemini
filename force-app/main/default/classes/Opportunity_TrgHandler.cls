/**
 * Opportunity_TrgHandler
 * Opportunity_Trgの実処理を記載
 */

public with sharing class Opportunity_TrgHandler {
    public Opportunity_TrgHandler() {

    }

    /**
     * 更新後処理
     */
    public void onAfterUpdate(List<Opportunity> newObjs, Map<Id, Opportunity> oldMap) {
        // Closed Wonに更新された商談に対してタスクを作成する
        List<Task> taskList = new List<Task>();
        for (Opportunity opp : newObjs) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (oldOpp.StageName != 'Closed Won' && opp.StageName == 'Closed Won') {
                Task t = new Task();
                t.Subject = '契約手続きを開始してください';
                t.WhatId = opp.Id;
                t.OwnerId = opp.OwnerId;
                t.Priority = 'Normal';
                t.Status = 'Not Started';
                t.ActivityDate = Date.today().addDays(7);
                taskList.add(t);
            }
        }
        if (!taskList.isEmpty()) {
            insert taskList;
        }
    }
}