# X 投稿ネタストック

Xで発信するネタのメモ。実務や学習で得た気づきをストックしておく。

---

## ネタ1: ContentVersionのVersionDataでヒープ上限超え

**カテゴリ**: 実務での躓き → 解決

**要点**:
- ContentVersionをSOQLで取得する際、SELECT句にVersionData（LOBフィールド）を含めていた
- VersionDataはファイルの実体（バイナリデータ）を持つため、ファイルサイズ分のヒープメモリを消費する
- Visualforceページのコントローラ拡張（同期処理）なのでヒープ上限は6MB
- 後続処理ではIdしか使っておらず、VersionDataは不要だった → SELECT句から除外して解決

**学び**:
- LOBフィールド（VersionData, Attachment.Body, Document.Body）はSELECT句に含めるだけでヒープを大量消費する
- SELECT句には実際に使う項目だけを書く
- テスト時に問題なくても、ファイルサイズが可変の場合は本番で発生しうる「潜在的な爆弾」になる
- ヒープはトランザクション全体の累計で計測される。他の処理との合算も考慮が必要

**関連知識**:
- ContentDocument / ContentVersion / ContentDocumentLink の3オブジェクト構造
- LinkedEntityIdでファイルから親レコードを辿れる
- Id.getSObjectType() でオブジェクト種別を動的に判定可能
