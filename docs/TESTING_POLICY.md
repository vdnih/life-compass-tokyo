# ライフプランアプリ テスト方針ドキュメント (v1.1)

## 1. 概要と目的

本文書は、「ライフプランアプリ」の品質担保とリグレッション防止を目的としたテスト方針を定義します。

本アプリは**3層レイヤードアーキテクチャ (UI, Logic, Data) + Riverpod**を採用しています。テストは、このアーキテクチャの「関心の分離」を維持・検証することを最優先とします。

## 2. テスト戦略 (テストピラミッド)

コストと速度のバランスに基づき、以下の比率でテストを構成します。

1. **ユニットテスト (Unit Tests) [主力]**: 高速・低コスト。ロジック層とデータ層の検証。
2. **ウィジェットテスト (Widget Tests) [中間]**: UI層の状態とインタラクションを検証。
3. **統合テスト (Integration Tests) [少数]**: 重要なユーザーフロー（クリティカルパス）のみを実機（またはエミュレータ）で検証。

## 3. レイヤー別テスト方針 (AI指示ガイド)

### 3.1. プレゼンテーション層 (UI Layer)

* **担当**: `lib/features/*/presentation/` 配下の Widget (`TimelineScreen` など)
* **手法**: **ウィジェットテスト (Widget Test)**
* **目的**:
    1.  状態（State）に基づき、期待されるWidgetが表示されること。
    2.  ユーザー操作（タップなど）が、Logic層のProviderに正しく通知されること。
* **AI指示ガイド**:
    * テスト対象のProvider (Logic層) は、`mocktail` を使用して**モック化**し、`ProviderScope` の `overrides` に指定します。
    * **状態別テスト (指示例)**: 「`TimelineScreen` のウィジェットテストを作成して。`timelineEventsProvider` を `Override` し、`AsyncValue.loading()` を返した場合に `CircularProgressIndicator` が表示されることを確認して。」
    * **インタラクションテスト (指示例)**: 「`AddEventDialog` (またはタイムラインの追加ボタン) を `tester.tap()` した際に、`timelineEventsProvider.notifier` のイベント追加メソッドが1回呼び出されることを `verify()` して。」

---

### 3.2. ビジネスロジック層 (Logic Layer)

* **担当**: `lib/features/*/logic/` 配下の Provider (`TimelineEventsProvider` 等)
* **手法**: **ユニットテスト (Unit Test)** - **【最重要テスト領域】**
* **目的**:
    1.  ビジネスロジック（状態遷移、計算）が正しいこと。
    2.  Data層のRepositoryが例外を投げた場合に、状態(State)が適切に `AsyncError` に遷移すること。
* **AI指示ガイド**:
    * テスト対象のProviderが依存するRepository (Data層) は、`mocktail` を使用して**モック化**します。
    * テストには `ProviderContainer` を直接使用します。
    * **指示例 (成功時)**: 「`TimelineEventsProvider` のユニットテストを作成して。`EventRepository` は `mocktail` でモック化し、イベント保存メソッドが成功した場合に、状態(State)が `AsyncLoading` を経て新しいイベントを含む `AsyncData` に遷移することを確認して。」
    * **指示例 (失敗時)**: 「`EventRepository` のデータ保存処理が例外 (`Exception` または `FirebaseException`) を `throw` するように `when` で設定し、`TimelineEventsProvider` でイベント追加を実行した際、状態(State)が `AsyncError` になることを確認して。」

---

### 3.3. データ層 (Data Layer)

* **担当**: `lib/features/*/data/` 配下の Repository (`EventRepository` 等)
* **手法**: **ユニットテスト (Unit Test)**
* **目的**:
    1.  Firebase等の外部データソース（将来機能）が、期待通りに呼び出されること。
    2.  `Map` (JSON) と `DomainModel` (`LifeEvent` など) の相互変換が正しいこと。
* **AI指示ガイド**:
    * `FirebaseAuth` や `FirebaseFirestore` のクライアントは `mocktail` で**モック化**します。
    * **指示例 (API呼び出し)**: 「`AuthRepository` の `signIn` メソッドのユニットテストを作成して。`FirebaseAuth` (モック) の `signInWithEmailAndPassword` メソッドが、渡されたEmailとPasswordで1回呼び出されることを `verify()` して。」
    * **指示例 (データ変換)**: 「`LifeEvent` モデルの `fromJson` と `toJson` のユニットテストを作成して。特定のJSONマップからモデルが正しく生成されること、およびモデルから期待通りのJSONマップが生成されることを確認して。」

## 4. 統合テスト (Integration Test)

* **担当**: `integration_test/` ディレクトリ
* **手法**: **`integration_test` パッケージ**
* **目的**: 複数の機能をまたぐ主要なユーザーフロー（クリティカルパス）を実機/エミュレータで通しでテストする。
* **方針**:
    * **テスト用Firebaseプロジェクト**に接続して実行します（モックは使用しません）。
    * 対象シナリオ: (例) 「新規登録 → ログイン → キャリアイベント（Work/Private）を1件追加 → タイムラインに正しく表示されることを確認 → ログアウト」
    * コストが高いため、UIの網羅的テストは行わず、クリティカルパスの正常系テストに限定します。

## 5. テスト環境・ツール

* **モックライブラリ**: **`mocktail`** (コード生成不要のためAIとの相性良し)
* **CI/CD**: GitHub Actions (または Codemagic) で、プッシュ/プルリクエスト時に全てのユニットテストとウィジェットテストを自動実行します。
* **Firebase環境**:
    * **本番用 (Prod)**: リリース用。
    * **開発用 (Dev)**: 開発・デバッグ用。
    * **テスト用 (Test)**: **統合テスト専用**。CIで利用します。
