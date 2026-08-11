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

# デプロイ（main への push で GitHub Actions が自動実行）
flutter build web --release
firebase deploy --only hosting   # projectId: my-career-app-559fd
```

## 3. アーキテクチャ

3層レイヤードアーキテクチャ + feature 単位のディレクトリ分割。詳細は `docs/SOFTWARE_ARCHITECTURE.md`。

- **レイヤー**: `presentation/`（`ConsumerWidget`、UIのみ）→ `logic/`（Riverpod Provider、状態＋ビジネスロジック）→ `data/`（Repository、I/O）。ドメインモデルは `domain/`。
- **feature 構成**: `lib/features/{timeline, catalog, user_profile, auth}/`。`catalog` は timeline / goal_template / budget などから参照される共有 feature のため、timeline の下ではなく並列に置いている（依存逆転を避けるため。ADR 参照）。
  - **feature ごとに階層が揃っていない**（`domain/` が無い feature、ほぼフラットな feature がある）。新規ファイルは既存の並びを見て合わせること。階層の統一はリファクタリング課題（#37）。
- **Repository の切替**: 認証状態に応じて Repository Provider が実装を選ぶ。**ゲスト（未ログイン）= InMemory 実装**（初期サンプルデータ入り）、**ログイン時 = Firestore 実装**。event / dependency / user すべて同じパターン。認証状態の変化で自動的にリポジトリを取り直す。
- **静的データはハードコード**: 規定イベントカタログ（`lib/features/catalog/data/groups/` を `predefined_catalog_registry.dart` が集約）とゴールテンプレートは Firestore に置かずアプリ内定数。イベントは `catalogId`（kebab-case 文字列）でカタログを参照する。カタログの件数・整合性の正は `test/features/catalog/data/catalog_consistency_test.dart` のアサーション。
- **依存関係と連動移動**: イベント間依存は `event_dependency.dart`（`strength: hard/soft`）。D&D 移動時は `cascade_move_provider.dart` が依存グラフを BFS で辿って連動移動する。**探索は双方向**（連結成分全体がずれる。後続だけではない）。
- **制約チェック**: `constraint_checker_provider.dart` が違反を算出し `constraint_warning.dart` で可視化する。**ドロップ自体はブロックしない**（警告のみ）。
- **ルーティング**: `GoRouter`。実質 `/`（`TimelineScreen`）のみ。認証やイベント編集はダイアログで処理するためルートを持たない。
- **ローカライズ**: 日本語固定（`Locale('ja','JP')`）。

## 4. 実装上の注意（知らないと事故るもの）

- **年ビュー・月ビューは `presentation/widgets/timeline_view.dart` に統合済み**（ADR-021）。`TimelineViewMode` enum で表示単位（1スロットが何ヶ月か）を切り替える。表示部品は `timeline_lane_labels.dart` / `timeline_axis.dart` / `catalog_drop_preview.dart` / `event_detail_dialog.dart` に分割している。
- **`*_provider.dart` という名前でも Provider を含まない純関数ファイルがある**（例: `cascade_move_provider.dart`）。名前を信用せず中身を見ること。
- **Freezed / json_serializable は導入していない。** ドメインモデルは手書きのイミュータブルクラス（`copyWith` / `==` / `hashCode` / `toJson` / `fromJson` を手書き）。`copyWith` で null をクリアする場合は既存の `_sentinel` パターンに倣う。
- **Riverpod のコード生成（riverpod_generator / build_runner）は導入していない。** 新規 Provider は周囲に合わせて手書きする（`NotifierProvider` / `AsyncNotifierProvider` / `Provider`）。riverpod 3 系（ADR-022）で `StateProvider` は legacy 扱いのため、単純な状態は `Notifier` + `NotifierProvider` を使う。
- **認証は `kIsWeb` で実行時に実装が分岐する**（Web は Firebase のポップアップ、モバイルは `google_sign_in`）。
- **Firestore のセキュリティルール・インデックスは `firestore.rules` / `firestore.indexes.json` がリポジトリの正。** `firebase deploy --only firestore:rules,firestore:indexes` で反映する（CI では自動デプロイされず手動運用。理由は ADR-015）。コンソールで直接編集するとリポジトリと乖離するため、変更は必ずこれらのファイル経由で行い、`docs/FIREBASE_ARCHITECTURE.md` にも反映すること。なお `storage.rules` は無い（Cloud Storage は未使用）。
- **`yyyy-MM` の日付計算は `timeline/domain/year_month.dart` の `YearMonth` に集約している。** 月加算・月差分・比較を自分で書かないこと（過去に同一アルゴリズムが4重実装されていた）。**永続化フィールド（`LifeEvent.date` / `endDate`）は `String` のまま**で、境界は `LifeEvent.yearMonth` / `endYearMonth` getter と `toJson` / `fromJson` だけ（ADR-020）。`toString()` は Firestore 形式（`2025-03`）、UI 表示は `japaneseLabel`（`2025年3月`）。`Text('$ym')` と書くと保存形式が画面に出る。
- **ゲスト用の InMemory 実装は `inMemory*RepositoryProvider` が保持している。** `eventRepositoryProvider` / `dependencyRepositoryProvider` の中で直接 `InMemoryEventRepository()` 等を生成すると、`authStateProvider` の emission ごと（トークンリフレッシュ等）に作り直されてゲストの編集が消える（一度やらかしている）。この Provider を autoDispose にしても同じことが起きる。
- **`authStateProvider` は `AsyncLoading` から始まる。** `.value == null` は「未認証」と「まだ解決していない」の両方を意味するため、ログイン済みユーザーも初回フレームだけゲスト（サンプルデータ）扱いになる。未修正（ADR-020 に記録、#39）。
- **riverpod 3 では listener の無い `StreamProvider` の購読が一時停止される。** `ProviderContainer` を直接使うテストで `container.read(provider.future)` を単独で呼ぶと、購読開始前に一時停止されて永遠に解決しないことがある（ADR-022）。`container.listen` で能動的な listener を張ってから待つこと。`authStateProvider` については `test/support/pump.dart` の `awaitAuthState()` を使う。

## 5. 実装規約とテスト方針

| 判断ポイント | 方針 |
|---|---|
| エラーハンドリング | `AsyncValue` の `loading` / `error` / `data` の3状態を必ず処理する |
| null 安全性 | `required` パラメータを優先。Optional は明示的に `?` と `??` で処理 |
| 命名規則 | Dart 公式スタイルガイド（lowerCamelCase / UpperCamelCase） |
| コメント | 公開 API（public class / method）には dartdoc コメントを付ける |
| 大きなウィジェットの分割 | `timeline_view.dart` は ADR-021 で表示部品を分割済み（#38 大半解消）。それでも肥大化するようなら機能追加のついでに分割しない。分割は独立した PR で行う |

**テスト方針**:

**判断基準: 「このテストが落ちたとき、何が壊れているか」を一言で言えないテストは書かない。**
値を書いて読み返すだけのテストは、壊れたことを教えてくれず保守コストだけが残る。
過去のテスト方針（`docs/archive/TESTING_POLICY.md`）が「比率目標」と「書くべきパターンの列挙」しか
持たず、増やす圧力にしかならなかった反省による。判断の経緯は ADR-019。

| 層 | 対象 | 担保すること | 担保しないこと |
|---|---|---|---|
| 純ロジック | `domain/` と `logic/` の純粋関数 | 計算結果と境界値。**ここを網羅する** | 見た目・配線 |
| 状態 | Notifier の状態遷移、`AsyncValue`、Repository 切替 | 遷移の順序、エラー時の復元、Repository 呼び出しの引数 | 描画 |
| ウィジェット | `presentation/` | **配線のみ**（操作 → 正しい Provider / 関数が呼ばれる、状態 → 表示に出る）。各経路 1 本 | ピクセル・色・レイアウト詳細 |

重心は純ロジック層に置く。ウィジェットテストを厚くするのではなく、**厚くしなくて済むよう
ロジックを純粋関数として切り出す**。D&D も同様に、座標→日付の変換は純粋関数側で網羅し、
ウィジェットテストは「ジェスチャが `DragTarget` に届き結果が Provider に渡る」配線のみを見る。

**書かないもの**:

- getter の単純委譲、`==` / `hashCode` の全フィールド列挙（`copyWith` は null クリアの分岐だけ）
- 色・フォントサイズ・パディングなど見た目の値、Flutter フレームワーク自体の挙動
- **具象クラス名への依存**（`find.byType(YearMonthTimeline)`）と**画面座標のハードコード**。
  実装差し替えやレイアウト変更で壊れる。`timeline_keys.dart` の Key か、
  描画済み矩形からの導出（`tester.getRect`）を使う

**構成**:

- `test/` は `lib/` と対称に置く。共有ヘルパーは `test/support/` のみ（モック・ビルダー・`pumpApp`）。
  モックやテスト用ウィジェットを各ファイルで再定義しない。
- 1 lib ファイル : 1 test ファイルを原則とする。
- テスト名は「〜であること」で仕様として読める形に。
- **`flutter analyze` と `flutter test` は CI の必須ゲート**（`.github/workflows/ci.yml`）。PR を出す前にローカルで両方通すこと。

## 6. Git と経緯の残し方

- feature ブランチを切って作業 → PR → `main` にマージ（GitHub Actions が自動デプロイ）。**`main` に直接コミットしない。**
- **マージは Squash and merge。** GitHub 設定で squash コミットメッセージは `COMMIT_MESSAGES` になっており、個々の commit メッセージは squash コミットの本文にそのまま残るため、コミット粒度の記録は失われない（[ADR-023](docs/adr/023-squash-merge-policy.md)）。ADR など経緯を残す文書からコミットハッシュを参照する場合は、squash で潰れないよう **PR 番号**（例: `#42`）を使う。
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
5. **残課題・後続タスク・スコープアウト事項は GitHub Issue で管理する。** ADR / PDR は
   「なぜそうしたか」の確定した記録であり、後から書き換えない。「まだ終わっていないこと」は
   Issue を立て、ADR / PDR 側からは `→ #N` の形で番号だけ参照する（例: `docs/adr/020-*.md`）。
   **ADR に「Follow-up（別タスク）」節を新設しない。** Issue の粒度は雑でよく、
   タイトルと出典（どの ADR/PDR/ファイルから来たか）が書いてあれば十分。
   PR 説明の `## なぜ` は `Closes #N` で代替してよい。

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
