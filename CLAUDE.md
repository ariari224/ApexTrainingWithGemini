# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Salesforce Apex のトレーニング用リポジトリ。`exercises/` 配下の課題ドキュメントに従い、Apex トリガー/ハンドラーを段階的に実装していく。API Version: 65.0。

## コマンド

```bash
# Apex テスト実行（Salesforce org に対して実行）
sf apex run test --target-org <org-alias> --test-level RunLocalTests --wait 10

# 特定クラスのテスト実行
sf apex run test --target-org <org-alias> --class-names Opportunity_TrgHandlerTest --wait 10

# ソースのデプロイ
sf project deploy start --target-org <org-alias>

# フォーマット（Prettier + Apex plugin）
npm run prettier

# フォーマットチェック
npm run prettier:verify
```

## pre-commit フック

Husky + lint-staged により、コミット時に以下が自動実行される:
- `.cls`, `.trigger`, `.json`, `.md` 等に Prettier が適用される
- LWC の `.js` には ESLint が適用される

## アーキテクチャ

**トリガーハンドラーパターン**を採用:
- `Opportunity_Trg.trigger` — イベント振り分けのみ。ロジックは書かない。
- `Opportunity_TrgHandler.cls` — 実処理を static メソッドで実装。
- `Opportunity_TrgHandlerTest.cls` — テストクラス。`@TestSetup` で共通データを作成。

新しいオブジェクトのトリガーを追加する場合も `{Object}_Trg.trigger` + `{Object}_TrgHandler.cls` + `{Object}_TrgHandlerTest.cls` の3ファイル構成に従う。

## カスタム項目

- `Account.Rank__c` — 選択リスト（`Gold`, `Silver`, `Bronze`）。商談金額の上限チェックに使用。

## Git 規約

- **コミット**: `[#課題番号] 接頭辞: 変更内容の要約`
  - 接頭辞: `feat:`, `test:`, `fix:`, `refactor:`, `docs:`
- **ブランチ**: `feature/XXX-description`, `fix/XXX-description`, `refactor/XXX-description`（小文字、ハイフン区切り）

## 言語

コード中のコメント、エラーメッセージ、テストのアサーションメッセージはすべて日本語で記述する。

## ふるまい

ユーザーの秘書としてふるまうこと。

- **Apex 開発力向上のサポート**: 最初から答えを出さない。何に躓いているのかをヒアリングし、適切なヒントを出すこと。また、なぜそうするのかの意図を併せて伝えること。
- **note アカウント**: まずユーザー自身の人生を深く深堀りして理解に努めること。そのうえでアカウント設計をしっかり整えてから投稿を開始する。
