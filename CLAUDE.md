# CLAUDE.md

Claude Code がこのリポジトリで作業するためのガイド。

**このファイルには「めったに変わらない構造の事実」と「守るべき少数のルール」だけを書く。**
件数・行数・ファイル一覧のような増減する情報は書かない（コードが唯一の情報源）。

## 1. プロジェクト概要

女性がキャリアとプライベートの両面からライフプランを考えるためのタイムラインアプリ。
Flutter 製、Web が主要ターゲット（Firebase Hosting でデプロイ）。

- なぜこのプロダクトか → `docs/PRODUCT_VISION.md`
- 何の機能があるか → `docs/PRD.md`
- ビジネスルール（カタログ定義・制約ルール・テンプレート） → `docs/SPEC.md`
- **実装の詳細は常にコード（`lib/` と `test/`）を正とする。**

## 2. コマンド

```bash
flutter pub get                  # 依存取得（pubspec 変更後は必須）
flutter run -d chrome            # アプリ起動
flutter analyze                  # 静的解析（flutter_lints）
flutter test                     # 全テスト
flutter test path/to/x_test.dart # 単一ファイル
flutter test --plain-name "..."  # テスト名で絞り込み
flutter test --coverage          # coverage/lcov.info を生成

# コード生成（riverpod_generator のみが対象。使用箇所は極めて少ない）
dart run build_runner build --delete-conflicting-outputs

# デプロイ（main への push で GitHub Actions が自動実行）
flutter build web --release
firebase deploy --only hosting   # projectId: my-career-app-559fd
```

## 3. アーキテクチャ

3層レイヤードアーキテクチャ + feature 単位のディレクトリ分割。詳細は `docs/SOFTWARE_ARCHITECTURE.md`。

- **レイヤー**: `presentation/`（`ConsumerWidget`、UIのみ）→ `logic/`（Riverpod Provider、状態＋ビジネスロジック）→ `data/`（Repository、I/O）。ドメインモデルは `domain/`。
- **feature 構成**: `lib/features/{timeline, catalog, user_profile, auth}/`。`catalog` は timeline / goal_template / budget などから参照される共有 feature のため、timeline の下ではなく並列に置いている（依存逆転を避けるため。ADR 参照）。
  - **feature ごとに階層が揃っていない**（`domain/` が無い feature、ほぼフラットな feature がある）。新規ファイルは既存の並びを見て合わせること。階層の統一はリファクタリング課題。
- **Repository の切替**: 認証状態に応じて Repository Provider が実装を選ぶ。**ゲスト（未ログイン）= InMemory 実装**（初期サンプルデータ入り）、**ログイン時 = Firestore 実装**。event / dependency / user すべて同じパターン。認証状態の変化で自動的にリポジトリを取り直す。
- **静的データはハードコード**: 規定イベントカタログ（`lib/features/catalog/data/groups/` を `predefined_catalog_registry.dart` が集約）とゴールテンプレートは Firestore に置かずアプリ内定数。イベントは `catalogId`（kebab-case 文字列）でカタログを参照する。カタログの件数・整合性の正は `test/features/catalog/data/catalog_consistency_test.dart` のアサーション。
- **依存関係と連動移動**: イベント間依存は `event_dependency.dart`（`strength: hard/soft`）。D&D 移動時は `cascade_move_provider.dart` が依存グラフを BFS で辿って連動移動する。**探索は双方向**（連結成分全体がずれる。後続だけではない）。
- **制約チェック**: `constraint_checker_provider.dart` が違反を算出し `constraint_warning.dart` で可視化する。**ドロップ自体はブロックしない**（警告のみ）。
- **ルーティング**: `GoRouter`。実質 `/`（`TimelineScreen`）のみ。認証やイベント編集はダイアログで処理するためルートを持たない。
- **ローカライズ**: 日本語固定（`Locale('ja','JP')`）。

## 4. 実装上の注意（知らないと事故るもの）

- **`year_timeline.dart` と `year_month_timeline.dart` はほぼ重複した2実装。** D&D 周りの修正は原則**両方**に入れる必要がある。過去にこの2ファイル間でコンフリクトが起きている。この重複解消はリファクタリングの筆頭課題。
- **`*_provider.dart` という名前でも Provider を含まない純関数ファイルがある**（例: `cascade_move_provider.dart`）。名前を信用せず中身を見ること。
- **Freezed / json_serializable は導入していない。** ドメインモデルは手書きのイミュータブルクラス（`copyWith` / `==` / `hashCode` / `toJson` / `fromJson` を手書き）。`copyWith` で null をクリアする場合は既存の `_sentinel` パターンに倣う。
- **Riverpod のコード生成はほぼ使っていない。** `@riverpod` アノテーションの使用箇所は1つだけ。新規 Provider は周囲に合わせて手書きする（`NotifierProvider` / `AsyncNotifier` / `StateProvider` / `Provider`）。
- **認証は `kIsWeb` で実行時に実装が分岐する**（Web は Firebase のポップアップ、モバイルは `google_sign_in`）。
- **`firestore.rules` / `storage.rules` はリポジトリに無い。** セキュリティルールは Firebase コンソールで管理している。変更した場合は `docs/FIREBASE_ARCHITECTURE.md` に反映すること。

## 5. 実装規約とテスト方針

| 判断ポイント | 方針 |
|---|---|
| エラーハンドリング | `AsyncValue` の `loading` / `error` / `data` の3状態を必ず処理する |
| null 安全性 | `required` パラメータを優先。Optional は明示的に `?` と `??` で処理 |
| 命名規則 | Dart 公式スタイルガイド（lowerCamelCase / UpperCamelCase） |
| コメント | 公開 API（public class / method）には dartdoc コメントを付ける |
| 新規パッケージの追加 | pub.dev の Like 数 500 以上、最終更新 6ヶ月以内を目安とする |
| 大きなウィジェットの分割 | タイムライン系ウィジェットは既に肥大化している。機能追加のついでに分割しない。分割は独立した PR で行う |

**テスト方針**:

- `domain/` と `logic/` はユニットテスト、`presentation/` はウィジェットテスト。モックは `mocktail`。
- `test/features/` は `lib/features/` と対称に置く。
- 現状 `auth` / `user_profile` / `core` にはテストが無い。テストの拡充は今後まとめて行う課題であり、新規実装のテストを書かない口実にはしない。
- **`flutter analyze` と `flutter test` は CI の必須ゲート**（`.github/workflows/ci.yml`）。PR を出す前にローカルで両方通すこと。

## 6. Git と経緯の残し方

- feature ブランチを切って作業 → PR → `main` にマージ（GitHub Actions が自動デプロイ）。**`main` に直接コミットしない。**
- ブランチ名: `claude/<内容がわかる名前>` または `<topic>/<内容>`
- commit は論理的な作業単位ごとに。prefix は `feat:` / `fix:` / `refactor:` / `test:` / `docs:` / `chore:`

### 経緯の記録（このリポジトリで唯一の必須ルール）

一人で開発しているため、**なぜそうしたかを残すことが最も重要**。以下を守れば他の運用ルールは不要。

1. **PR 説明に必ず書く** — 以下のテンプレートに従う。

   ```markdown
   ## なぜ
   （解決したい課題・きっかけとなったフィードバック）

   ## 何をしたか
   （変更の要点。ファイル一覧はコミット差分で足りるので書かない）

   ## 検討したが採らなかった案
   （あれば。なければ省略可）

   ## 検証
   （flutter analyze / flutter test の結果、実機で確認した挙動）
   ```

2. **後戻りしにくい技術判断は ADR に残す** — `docs/adr/NNN-kebab-case-title.md`
   対象: データモデルの変更、永続化方式、外部依存の追加、レイヤー構成の変更。
3. **機能の要否・優先順位の判断は PDR に残す** — `docs/pdr/PDR-NNN-kebab-case-title.md`
4. **判断を覆したときは元の ADR / PDR に `Superseded by ADR-NNN` を追記する。**
   消さずに、なぜ覆したかを併記する（`docs/adr/011-milestone-as-child-event.md` が良い前例）。

## 7. ドキュメント体系

```
docs/
├── PRODUCT_VISION.md           # Mission・Vision・Values
├── PRD.md                      # ターゲット・フェーズ別機能一覧
├── SPEC.md                     # ビジネスルール仕様
├── SOFTWARE_ARCHITECTURE.md    # レイヤー構成・Riverpod 規約
├── FIREBASE_ARCHITECTURE.md    # Firestore スキーマ・セキュリティルール
├── adr/                        # Architecture Decision Records（なぜその設計か）
├── pdr/                        # Product Decision Records（なぜこの機能・優先順位か）
└── archive/                    # 更新を停止した歴史的ドキュメント（参照のみ）
```

- `docs/archive/` の中身は**現状の仕様ではない**。仕様を知る目的で読まないこと。
- 設計ドキュメントとコードが食い違っていたら、**コードが正**。気付いた時点でドキュメント側を直すか、直せない場合は PR 説明に食い違いを記録する。
