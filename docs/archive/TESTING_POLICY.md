# テスト方針ドキュメント

**Version**: 2.0
**Last Updated**: 2025-XX-XX
**Owner**: QA Agent

## 1. 概要

本文書は、ライフプランアプリの品質担保とリグレッション防止を目的としたテスト方針を定義する。
3層レイヤードアーキテクチャ（UI, Logic, Data）+ Riverpodの「関心の分離」を維持・検証することを最優先とする。

## 2. テスト戦略（テストピラミッド）

| 優先度 | テスト種別 | 対象 | 比率目安 |
|---|---|---|---|
| 1（主力） | ユニットテスト | Logic層・Data層 | 70% |
| 2（中間） | ウィジェットテスト | Presentation層 | 25% |
| 3（少数） | 統合テスト | クリティカルパス | 5% |

## 3. レイヤー別テスト方針

### 3.1. Presentation層（ウィジェットテスト）

- **対象**: `lib/features/*/presentation/` 配下のWidget
- **検証項目**:
  1. 状態（AsyncValue）に基づき、期待されるWidgetが表示されること
  2. ユーザー操作が Logic層の Provider に正しく通知されること
- **モック戦略**: Logic層のProviderを `mocktail` でモック化し、`ProviderScope.overrides` に指定

#### テストパターン

**状態別テスト**:
- `AsyncValue.loading()` → `CircularProgressIndicator` が表示される
- `AsyncValue.data([])` → 空状態メッセージが表示される
- `AsyncValue.data([event1, event2])` → イベントカードが2つ表示される
- `AsyncValue.error(Exception('...'))` → エラーメッセージが表示される

**インタラクションテスト**:
- FABタップ → `AddEventDialog` が表示される
- イベント追加ボタンタップ → `provider.notifier.addEvent()` が1回呼び出される
- 削除ボタンタップ → `provider.notifier.deleteEvent()` が1回呼び出される

### 3.2. Logic層（ユニットテスト）【最重要】

- **対象**: `lib/features/*/logic/` 配下のProvider
- **検証項目**:
  1. ビジネスロジック（状態遷移）が正しいこと
  2. Repository例外時に `AsyncError` へ遷移すること
- **モック戦略**: Data層のRepositoryを `mocktail` でモック化
- **テスト基盤**: `ProviderContainer` を直接使用

#### テストパターン

**正常系**:
- イベント追加成功 → state が `AsyncData` に遷移し、新イベントを含む
- イベント削除成功 → state が `AsyncData` に遷移し、該当イベントが含まれない
- イベント一覧取得成功 → state が `AsyncLoading` → `AsyncData` に遷移

**異常系**:
- Repository が Exception を throw → state が `AsyncError` に遷移
- 空のタイトルでイベント追加 → バリデーションエラー

### 3.3. Data層（ユニットテスト）

- **対象**: `lib/features/*/data/` 配下のRepository
- **検証項目**:
  1. 外部データソースが期待通りに呼び出されること（Phase 3）
  2. `Map`（JSON）と `DomainModel` の相互変換が正しいこと
- **モック戦略**: MVP時はインメモリ実装のため、モック不要で直接テスト可能

#### テストパターン

**データ変換**:
- `LifeEvent.fromJson(validMap)` → 正しいモデルが生成される
- `LifeEvent(...).toJson()` → 期待通りのMapが生成される
- 不正なJSON（必須フィールド欠損）→ 例外が発生する

**Repository操作（InMemory）**:
- `save(event)` → `getAll()` に含まれる
- `delete(id)` → `getAll()` に含まれない
- 存在しないIDで `delete` → 例外 or 何も起きない（仕様を明確にする）

## 4. 統合テスト

- **対象**: `integration_test/` ディレクトリ
- **方針**: クリティカルパスの正常系のみ。網羅的UIテストは行わない。
- **シナリオ例**: 「アプリ起動 → イベント追加 → タイムライン表示確認 → イベント削除」
- **Phase 3追加シナリオ**: 「新規登録 → ログイン → イベント追加 → タイムライン確認 → ログアウト」

## 5. テスト環境・ツール

| 項目 | 選定 |
|---|---|
| モックライブラリ | `mocktail`（コード生成不要） |
| CI/CD | GitHub Actions（push / PR時に自動実行） |
| カバレッジ | `flutter test --coverage` + `lcov` |

## 6. 品質基準（リリースゲート）

- ユニットテスト + ウィジェットテスト: **全件Pass**
- `dart analyze`: **error 0件**
- Logic層のテストカバレッジ: **80%以上**（目標）

## 変更履歴

| バージョン | 日付 | 変更内容 |
|---|---|---|
| 1.0 | - | 初版作成 |
| 1.1 | - | AI指示ガイドを追加 |
| 2.0 | - | Claude Code体制に合わせて再構成。具体的なテストパターンを追記。品質基準を明確化。 |
