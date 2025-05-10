# features/post

## 概要

- 投稿の作成・一覧・詳細・削除
- コメント機能（追加・削除）
- Firestore連携

## 主なファイル

- `view/` ... 投稿一覧・詳細・作成画面
- `view/widgets/` ... コメントセクション・コメントアイテム
- `view_model/` ... 投稿・コメント状態管理（Riverpod）
- `repository/` ... Firestore連携
- `model/` ... 投稿・コメントモデル

## 備考

- 投稿・コメントともにFirestoreのコレクションを利用
- 投稿詳細からコメント追加・削除可能
