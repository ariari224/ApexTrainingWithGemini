# Salesforce DX Project: Next Steps

Now that you’ve created a Salesforce DX project, what’s next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

1. コミット名の命名規則

基本フォーマット[#課題番号] 接頭辞: 変更内容の要約

接頭辞（Prefix）の使い分け

feat:新しい機能やロジックの追加
test:テストクラスの追加修正およびカバレッジ向上
fix:バグやエラーの修正
refactor:機能を変えないコードの整理
docs:READMEやコメントの追加修正

具体例:
[#001] feat: 商談成立時のタスク自動作成ロジック実装
[#002] test: 商談バルク更新時のガバナ制限検証テスト追加
[#003] fix: 取引先未指定時のNullPointer例外を修正
[#001] refactor: 重複コードを共通メソッドへ抽出
[#000] docs: プロジェクトの命名規則をREADMEに記載


2. ブランチの命名規則

基本フォーマット種類/課題番号-概要 （すべて小文字、単語間はハイフン）

種類（Type）の使い分け

feature/: 新機能開発用
fix/: バグ修正用
refactor/: コード整理用

具体例:
feature/001-opportunity-task-logic
feature/002-opportunity-account-sync
fix/003-account-rating-bug