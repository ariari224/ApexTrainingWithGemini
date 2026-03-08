# 課題 #004：商談クローズ時の未完了タスク自動クローズ

## 1. 課題の背景と要件
- **背景**: 商談がクローズされた後も、紐づくタスクが未完了のまま放置される問題が発生している。担当者が手動でクローズする手間を省き、漏れを防ぎたい。
- **要件**:
    - `Opportunity.StageName` が `Closed Won` または `Closed Lost` に**変更された瞬間**に動作すること。
    - 対象商談に紐づく未完了タスク（`Status != 'Completed'`）を取得する。
    - それらのタスクの `Status` を `'Completed'` に一括更新する。
    - **防御的設計**: すでにクローズ済みのレコードを更新した場合は動作しないこと。

## 2. Git 運用
- **ブランチ名**: `feature/004-close-related-tasks`
- **コミット名**: `[#004] feat: 商談クローズ時の未完了タスク自動クローズの実装`

## 3. 設計メモ
- **トリガー**: `after update`
- **ハンドラ**: `closeRelatedTasks(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap)` メソッドを作成。
- **処理フロー**:
    1. `Trigger.new` と `Trigger.oldMap` を比較し、`Closed Won` または `Closed Lost` に**変更された**商談の `Id` を `Set<Id>` に収集する。
    2. 収集した `Id` を使い、`WhatId IN :oppIds AND Status != 'Completed'` の条件でタスクをSOQLで取得する。
    3. 取得したタスクの `Status` を `'Completed'` に変更し、`update` する。
- **技術的ポイント**:
    - `Task` の親参照項目は `WhatId`（商談・取引先などに紐づく汎用の参照項目）。
    - Set が空の場合はSOQLを実行しない（ガバナ制限の節約）。

## 4. 躓いた点・エラーの記録
- （実装後に追記）

## 5. 学び・成長点
- （実装後に追記）
