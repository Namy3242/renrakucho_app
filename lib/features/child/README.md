# features/child

## 概要

- 園児（子供）の作成・編集・削除
- 保護者・クラス・園クラスとの紐付け
- Firestore連携

## 主なファイル

- `view/` ... 園児一覧・作成・編集画面
- `view_model/` ... 園児状態管理（Riverpod）
- `repository/` ... Firestore連携
- `model/` ... 園児モデル

## 備考

- 園児は複数保護者・クラス・園クラスに紐付け可能
