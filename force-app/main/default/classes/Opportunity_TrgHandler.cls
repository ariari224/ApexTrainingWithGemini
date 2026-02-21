/**
 * Opportunity_TrgHandler
 * Opportunity_Trgの実処理を記載
 */

public with sharing class Opportunity_TrgHandler {
    public Opportunity_TrgHandler() {

    }

    /**
     * 作成前処理
     */
    public static void onBeforeInsert(List<Opportunity> newObjs) {
        checkAmountLimit(newObjs);
    }

    /**
     * 作成後処理
     */
    public static void onAfterInsert(List<Opportunity> newObjs) {
        Set<Id> idsToRecalculate = new Set<Id>();
        for (Opportunity opp : newObjs) {
            if (opp.AccountId != null) {
                idsToRecalculate.add(opp.AccountId);
            }
        }
        recalculateAccountSummaries(idsToRecalculate);
    }

    /**
     * 更新前処理
     */
    public static void onBeforeUpdate(List<Opportunity> newObjs) {
        checkAmountLimit(newObjs);
    }

    /**
     * 更新後処理
     */
    public static void onAfterUpdate(List<Opportunity> newObjs, Map<Id, Opportunity> oldMap) {
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

        Set<Id> idsToRecalculate = new Set<Id>();
        for (Opportunity opp : newObjs) {
            // 新しいAccountIdを追加
            if (opp.AccountId != null) {
                idsToRecalculate.add(opp.AccountId);
            }
            // 古いAccountIdも（もしあれば）追加
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.AccountId != oldOpp.AccountId && oldOpp.AccountId != null) {
                idsToRecalculate.add(oldOpp.AccountId);
            }
        }
        recalculateAccountSummaries(idsToRecalculate);
    }


    /**
     * 削除後処理
     */
    public static void onAfterDelete(List<Opportunity> oldObjs) {
        Set<Id> idsToRecalculate = new Set<Id>();
        for (Opportunity opp : oldObjs) {
            if (opp.AccountId != null) {
                idsToRecalculate.add(opp.AccountId);
            }
        }
        recalculateAccountSummaries(idsToRecalculate);
    }

    /**
     * 復元後処理
     */
    public static void onAfterUndelete(List<Opportunity> newObjs) {
        Set<Id> idsToRecalculate = new Set<Id>();
        for (Opportunity opp : newObjs) {
            if (opp.AccountId != null) {
                idsToRecalculate.add(opp.AccountId);
            }
        }
        recalculateAccountSummaries(idsToRecalculate);
    }

    /**
     * 商談作成時及び更新時、削除時に取引先のDescriptionを更新する
     */
    private static void recalculateAccountSummaries(Set<Id> accountIds) {
        // IDが空なら何もしない
        if (accountIds.isEmpty()) {
            return;
        }

        // 更新対象の取引先を取得し、Descriptionを一旦リセットする
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Description FROM Account WHERE Id IN :accountIds
        ]);

        for (Account acc : accountMap.values()) {
            acc.Description = '現在の進行中商談はありません。';
        }

        // 金額を集計するSOQL
        List<AggregateResult> results = [
            SELECT AccountId, SUM(Amount) totalAmount
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND StageName NOT IN ('Closed Won', 'Closed Lost')
            GROUP BY AccountId
        ];

        // 集計結果をDescriptionに反映させるループ
        for (AggregateResult ar : results) {
            // AccountIdを取得
            Id accId = (Id)ar.get('AccountId');
            // 合計金額を取得（別名で指定。Object型で返るためDouble等にキャストが必要）
            // ar.get('totalAmount') が null の場合を考慮し Decimal にキャストするのが安全です
            Decimal sumAmount = (Decimal)ar.get('totalAmount');
            if (sumAmount != null) {
                Account acc = accountMap.get(accId);
                acc.Description = '現在の進行中商談の合計額は ¥' + sumAmount.format() + ' です';
            }
        }

        // 取引先を一括更新
        update accountMap.values();
    }

    /**
     * 商談作成時あるいは更新時、取引先の信用度ランクに応じて商談金額が超過していないかチェックする
     */
    private static void checkAmountLimit(List<Opportunity> newObjs){
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newObjs) {
            accountIds.add(opp.AccountId);
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Rank__c FROM Account WHERE Id IN :accountIds
        ]);
        for (Opportunity opp : newObjs) {
            Account acc = accountMap.get(opp.AccountId);
            if (acc == null) {
                continue;
            }
            Decimal limitAmount = 0;
            Boolean unlimit = false;
            switch on acc.Rank__c {
                when 'Bronze' {
                    limitAmount = 500000;
                }
                when 'Silver' {
                    limitAmount = 5000000;
                }
                when 'Gold' {
                    unlimit = true;
                }
                when else {
                    limitAmount = 100000;
                }
            }
            
            // 上限あり(unlimitがfalse) かつ 上限額を超えている場合にエラー
            if(!unlimit && opp.Amount > limitAmount){
                String rankName = (acc.Rank__c != null) ? acc.Rank__c : '未設定';
                opp.Amount.addError(rankName + 'ランクの取引先は、¥' + limitAmount.format() + ' 以上の商談を作成できません。');
            }
        }
    }
}