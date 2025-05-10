# features/auth

## 概要

- Firebase Authによるユーザー認証
- ユーザー登録（保護者・教員）
- ログイン・ログアウト
- ユーザー情報取得・検索

## 主なファイル

- `view/` ... ログイン・登録画面
- `view_model/` ... 認証状態管理（Riverpod）
- `repository/` ... Firebase Auth/Firestore連携
- `model/` ... ユーザーモデル・ロール定義

## 備考

- ログアウトはGoRouterのredirectで自動遷移
- 保護者検索はメールアドレスで部分一致
