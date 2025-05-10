# renrakucho_app

Flutter + Firebase（Firestore, Auth）による連絡帳アプリ

## 主な機能

- ユーザー認証（保護者・教員・管理者）
- 投稿（作成・一覧・詳細・コメント・削除）
- クラス管理（作成・編集・削除・メンバー管理・担任選択）
- コメント機能（投稿へのコメント追加・削除）
- 画面遷移はGoRouter、状態管理はRiverpodを利用

## ディレクトリ構成

```
lib/
  features/
    auth/      ... 認証・ユーザー管理
    class/     ... クラス管理
    home/      ... ホーム画面
    post/      ... 投稿・コメント
    common/    ... 共通ウィジェット・画面
    core/      ... 共通ロジック・ユーティリティ
  providers/   ... グローバルProvider
  routes/      ... ルーティング
  firebase_options.dart ... Firebase設定
  main.dart    ... エントリポイント
```

## 開発メモ

- Firestoreのインデックスが必要な場合はエラーメッセージのリンクから作成
- クラス作成・編集時に担任選択可能（デフォルトは作成者）
- 投稿・コメント・クラスのCRUDは全てFirestore連携
- ログアウトはGoRouterのredirectで自動遷移
- 状態管理はRiverpod（FutureProvider/StateNotifierProvider/StreamProvider等）

## Structure

```mermaid
graph TB
    subgraph App
        Main --> Router
        Router --> Auth
        Router --> Home
        Router --> Class
        Router --> Post
    end

    subgraph Auth[認証機能]
        AuthView[画面層] --> AuthViewModel[ビジネスロジック層]
        AuthViewModel --> AuthRepository[データ層]
        AuthRepository --> Firebase[Firebase Auth]
        AuthModel[モデル層] --> AuthViewModel
    end

    subgraph Post[投稿機能]
        PostView[画面層] --> PostViewModel[ビジネスロジック層]
        PostViewModel --> PostRepository[データ層]
        PostRepository --> Firestore[Cloud Firestore]
        PostModel[モデル層] --> PostViewModel
        Comment[コメント機能] --> PostView
    end

    subgraph Class[クラス管理]
        ClassView[画面層] --> ClassViewModel[ビジネスロジック層]
        ClassViewModel --> ClassRepository[データ層]
        ClassRepository --> Firestore
        ClassModel[モデル層] --> ClassViewModel
    end

    subgraph Home[ホーム機能]
        HomeView[画面層]
        HomeView --> PostView
        HomeView --> ClassView
    end
```

## 画面遷移図

```mermaid
stateDiagram-v2
    [*] --> Login
    Login --> Register: 新規登録
    Register --> Login: 登録完了
    Login --> Home: ログイン成功
    Home --> PostList: 投稿一覧
    Home --> ClassList: クラス一覧
    PostList --> PostDetail: 投稿選択
    PostDetail --> Comment: コメント
    ClassList --> ClassDetail: クラス選択
    Home --> Profile: プロフィール
    Profile --> [*]: ログアウト
```

## 状態管理

```mermaid
flowchart TB
    subgraph Providers[状態管理]
        AuthProvider[認証Provider]
        PostProvider[投稿Provider]
        CommentProvider[コメントProvider]
        ClassProvider[クラスProvider]
    end

    subgraph States[状態]
        AuthState[認証状態]
        PostState[投稿状態]
        CommentState[コメント状態]
        ClassState[クラス状態]
    end

    AuthProvider --> AuthState
    PostProvider --> PostState
    CommentProvider --> CommentState
    ClassProvider --> ClassState
    
    AuthState --> Views[画面更新]
    PostState --> Views
    CommentState --> Views
    ClassState --> Views
```

## 今後のTODO

- プロフィール画面の実装
- 投稿画像・動画アップロード
- 通知機能
