# インフラアーキテクチャ設計書

## 1. 概要
本ドキュメントは、Flutterで開発する「ライフプランアプリ」のバックエンドインフラのアーキテクチャを定義するものです。
本アプリは、女性が自身のキャリアとプライベートの両面でライフプランを考えるためのタイムラインアプリです。ユーザー認証機能、イベントデータ（Work/Privateのライフイベント等）の保存・管理機能、添付ファイル（画像やドキュメント）の保存機能、およびWeb版のホスティング機能を持ちます。インフラの構築・管理コストを最小限に抑えつつ、スケーラビリティとリアルタイム性を確保するため、Firebase (BaaS - Backend as a Service) を全面的に採用します。

## 2. アーキテクチャ概要
本アプリのインフラは、クライアント（Flutterアプリ）とFirebaseの各サービスが直接通信する「サーバーレスアーキテクチャ」を採用します。Cloud Functions等のバックエンドロジックは初期リリースでは採用せず、クライアントサイドの処理で完結させます。

### 主要コンポーネント
* **クライアント (Client)**
    * **Flutterアプリ (iOS / Android / Web)**: ユーザーインターフェースとビジネスロジックを担当。Firebase SDKを通じて直接バックエンドサービスと通信します。
* **バックエンド (Firebase)**
    * **Firebase Authentication**: ユーザー認証基盤。
    * **Cloud Firestore**: メインデータベース（NoSQL）。
    * **Cloud Storage for Firebase**: オブジェクトストレージ（画像や添付ファイルの保存）。
    * **Firebase Hosting**: Web版アプリのホスティング。

## 3. 使用サービス詳細

### 3.1. Firebase Authentication (認証)
* **目的**: アプリのユーザー認証管理。
* **利用プロバイダ**: メール / パスワード
* **連携**: 発行されるユーザーID (uid) を、DBおよびStorageのセキュリティキーとして使用。

### 3.2. Cloud Firestore (データベース)
* **目的**: ユーザー情報とキャリア・イベントデータの永続化。
* **ロケーション**: `asia-northeast1` (東京)
* **データモデル (Sub-collection pattern)**:
    セキュリティとパフォーマンスを最適化するため、ユーザー単位のサブコレクションを採用。
    ```text
    users/{userId}
       └ events/{eventId}
           ├ title: String (イベント名)
           ├ type: String ("Work" or "Private")
           ├ startDate: Timestamp
           ├ endDate: Timestamp (Optional)
           └ attachmentUrls: List<String>  (StorageのダウンロードURL)
    ```

### 3.3. Cloud Storage for Firebase (ストレージ)
* **目的**: キャリアに関連する画像や証明書ファイルなどの実体保存。
* **ロケーション**: `asia-northeast1` (東京)
* **フォルダ構成**:
    DB構造と対称性を持たせ、管理を容易にする。
    ```text
    users/{userId}/events/{eventId}/{timestamp}.jpg
    ```
* **クライアントサイド処理 (Soft Limit)**:
    コスト削減とUX向上のため、アップロード前にアプリ側で加工を行う。
    * **ライブラリ**: `flutter_image_compress` などを想定
    * **目標**: アップロード時のファイルサイズ最適化（1ファイルあたり 1MB以下）

### 3.4. Firebase Hosting (ホスティング)
* **目的**: Flutter Webの公開。
* **特徴**: SSL自動適用、グローバルCDN配信。

## 4. セキュリティ設計 (Security Rules)
「Deny-by-default（原則拒否）」を採用し、認証済み本人以外のアクセスを遮断します。

### 4.1. Firestore ルール
* **スコープ**: `users/{userId}` 配下のみ、本人が読み書き可能。

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4.2. Storage ルール (コスト対策)

* **スコープ**: `users/{userId}` 配下のみ、本人が読み書き可能。
* **制約**: アップロード可能なサイズ制限（例: 5MB）を設け、物理的にブロック。

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    function isValidFile() {
      return request.resource.size < 5 * 1024 * 1024;
    }
    match /users/{userId}/{allPaths=**} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId) && isValidFile();
    }
  }
}
```

## 5. 運用・管理

* **デプロイ**: Firebase CLI (`firebase deploy`) を使用。
* **監視**: GCPコンソールにて予算アラートを設定。

## 6. リスク対策と既知の制限事項

### 6.1. EDoS (Economic Denial of Sustainability) 対策

クラウド破産を防ぐための多層防御。

1. **Hard Limit (Storage Rules)**: 5MB上限などにより、攻撃的な巨大ファイル投下を無効化。
2. **Soft Limit (App Logic)**: 画像圧縮等により、正規利用時の容量を最小化。
3. **Monitoring**: 予算アラートによる早期検知。

### 6.2. 既知の制限事項 (Known Limitations)

本アーキテクチャは「サーバーレス（Cloud Functionsなし）」構成のため、以下の制限を許容しています。

* **データの不整合（ゴミファイルの残留）**:
  Firestore上のイベントデータ (`events/{eventId}`) を削除しても、Storage内のファイルは自動削除されません（オーファンファイル）。
    * *対策*: 個人利用範囲では容量コストへの影響が軽微なため、現状は許容する。将来的にCloud Functionsを導入した際、トリガーによる自動削除 (`onDocumentDeleted`) を実装することを視野に入れる。
