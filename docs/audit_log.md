# 監査ログ (Audit Log)

> このファイルはメインエージェント（Project Manager）のみが追記する。
> 人間（ユーザー）はこのログを読んでプロジェクトの進行状況を把握する。
> 最新のエントリが上に来るように追記すること（降順）。

---

## 2026-03-27 - [ドキュメント体系再編] ドキュメント構造をリファクタリング

- **判断内容**:
  - `docs/PRD.md` をスリム化。実装詳細・画面構成・制約ルール・テンプレート定義を削除し、ビジョン・フェーズ別機能一覧（概要のみ）に絞った（v4.0 → v5.0）
  - `docs/SPEC.md` を新設。PRD.md から制約ルール（C-01〜C-03）、ゴールテンプレート定義（出産テンプレート）、イベントカテゴリ定義を移管
  - `docs/adr/` ディレクトリを新設。ARCHITECTURE.md 内の設計判断ブロックを5本のADRとして切り出し
    - ADR-001: category フィールド統合
    - ADR-002: 制約チェック結果の非永続化
    - ADR-003: 依存関係を別コレクションで永続化
    - ADR-004: ゴールテンプレートのハードコード
    - ADR-005: 制約チェックのクライアントサイド実行
  - `docs/ARCHITECTURE.md` を `docs/FIREBASE_ARCHITECTURE.md` にリネーム。設計判断ブロックを削除しADRへの参照に置き換え
  - `CLAUDE.md` のドキュメント体系定義を更新。Implementerの触れないファイルリストを更新
- **理由**: PRD.mdが実装詳細・設計根拠・ビジネスルールが混在し、コードとの二重管理・不整合が発生しやすい状態だった。「何がルールか→SPEC.md」「なぜその設計か→ADR」「実装の詳細→コード」という明確な情報源の分離を図るため
- **影響範囲**: `docs/PRD.md`, `docs/SPEC.md`（新規）, `docs/adr/`（新規）, `docs/FIREBASE_ARCHITECTURE.md`（新規）, `docs/ARCHITECTURE.md`（削除）, `CLAUDE.md`

---

## 2026-03-26 - [ドキュメント修正] WBS.md の不整合を解消

- **判断内容**: Phase 4 タスク（I2-01〜I2-07）の状態を `⬜ TODO` → `✅ DONE` に修正
- **理由**: 実装はコミット済み（38a7999, e0261f7, b60ed0f, b704401）だったが、WBS.md のみ更新漏れが発生していた。feature_registry.md・audit_log.md は正しく更新済みだった。
- **影響範囲**: `docs/WBS.md` のみ（実装コードへの変更なし）

---

## 2026-03-26 - [実装完了] Phase 4 UI層実装（I2-06, I2-07）完了

- **判断内容**: 目標逆算機能のUI層を全て実装完了。ゴール設定ダイアログ（GoalSetupDialog）、依存関係コネクタ（DependencyConnector）、ドラッグ&ドロップ対応（LongPressDraggable + DragTarget）、EventCardウィジェット抽出を実施。
- **理由**: Phase 4実装タスクI2-06（UI - ゴール設定ダイアログ）とI2-07（UI - 依存線 & D&D）の実装を完了するため。
- **影響範囲**:
  - **新規ファイル**:
    - `lib/features/timeline/presentation/goal_setup_dialog.dart` - テンプレート選択、日付ピッカー、プレビュー、適用
    - `lib/features/timeline/presentation/widgets/dependency_connector.dart` - CustomPainterで依存タイプ別線描画
    - `lib/features/timeline/presentation/widgets/event_card.dart` - イベントカードをウィジェットとして抽出
    - `test/features/timeline/presentation/goal_setup_dialog_test.dart` - ダイアログ表示・選択・適用テスト10件
    - `test/features/timeline/presentation/widgets/dependency_connector_test.dart` - コネクタ描画・shouldRepaintテスト6件
  - **変更ファイル**:
    - `lib/features/timeline/presentation/timeline_screen.dart` - 目標設定ボタン追加、GoalSetupDialogインポート
    - `lib/features/timeline/presentation/widgets/year_month_timeline.dart` - LongPressDraggable, DragTarget, DependencyConnector統合
    - `lib/features/timeline/presentation/widgets/year_timeline.dart` - 同上
  - **feature_registry.md**: F-21, F-22, F-23を🟢 RELEASEDに更新

---

## 2026-03-26 - [設計変更] コアコンセプト変更と目標逆算機能の設計

- **判断内容**: アプリのコアコンセプトを「わたしの人生を、一本のタイムラインに。」から「目標から逆算して、わたしの人生をデザインする。」に変更。目標逆算機能群（F-20〜F-24）をPhase 2として設計した。
- **理由**: ユーザーから「目標から逆算して人生設計できるアプリ」というビジョンが提示された。ライフゴール（例: 出産）を設定すると、妊活・産休・育休・旅行リミット・転職リミットなどの時間的制約が自動的に逆算され、イベント間の依存関係で連動する仕組みが求められた。プロジェクトマネジメント的思想（ゴールからの逆算、マイルストーン設定、タスク依存関係）をライフプランニングに適用する。
- **影響範囲**:
  - `docs/PRD.md` v3.0 → v4.0: コンセプト変更、F-20〜F-24追加、出産テンプレート定義、C-03制約追加
  - `docs/ARCHITECTURE.md` v3.1 → v4.0: eventsにid/goalId/isGoal追加、dependenciesコレクション新設
  - `docs/SOFTWARE_ARCHITECTURE.md` v4.1 → v5.0: EventDependency/GoalTemplateモデル、新Provider群、LifeEventにid復活
  - `docs/test_scenarios.md` v1.0 → v2.0: Phase 2用31テストシナリオ追加
  - `docs/WBS.md`: Phase 3（設計v2）、Phase 4（実装v2）追加
  - `docs/feature_registry.md`: F-20〜F-24追加、旧Phase 2機能をPhase 3に移動

### 主要な設計判断の詳細

1. **LifeEventにidフィールドを復活**: v4.1で削除されたidを復活。依存関係（F-20）でイベントを一意に識別するためにUUIDが必須。`uuid`パッケージを使用する。
2. **依存関係の4タイプ設計（prerequisite/consequence/deadline/companion）**: ライフイベント間の多様な関係性を表現するために4種類に分類。出産テンプレートでは主にprerequisite、consequence、deadlineを使用する。
3. **ゴールテンプレートのアプリ内ハードコード**: テンプレートは静的データであり、Firestore保存の利点がない。Phase 2 MVPでは「出産」テンプレートのみ。
4. **カスケード移動のBFSアルゴリズム**: トポロジカルソートで依存順序を決定し、BFS探索で連鎖移動を計算。循環依存は事前に検出・拒否する設計。
5. **ドラッグ&ドロップは長押し開始**: 横スクロールとの競合を回避するため、`LongPressDraggable`を採用。
6. **旧Phase 2機能（F-04, F-05, F-11, F-12）をPhase 3に移動**: 目標逆算機能がPhase 2の中核となるため、優先度の低い既存計画機能をPhase 3に繰り延べ。

---

## 2026-03-09 - [機能追加] タイムラインタップによるイベント追加機能を実装

- **判断内容**: `YearMonthTimeline` と `YearTimeline` の空きエリアをタップすると、タップした年月・レーン（仕事/プライベート）を初期値にした `AddEventDialog` が開く機能を追加した。
- **理由**: ユーザーがタイムライン上を直接タップしてイベントを追加できるようにすることで、UX を向上させるため。FAB からの追加と併用可能。
- **実装方針**:
  - 各タイムラインウィジェット内の水平スクロール配下に `GestureDetector`（`behavior: HitTestBehavior.translucent`）を追加。
  - `onTapUp` でタップ座標を取得し、X 座標から月/年インデックス、Y 座標から仕事/プライベートを算出。
  - 軸エリア（axisHeight 未満）と範囲外タップは無視。
  - イベントカードの `GestureDetector` が先に処理するため、既存のイベント詳細表示動作と干渉しない。
- **影響範囲**:
  - `lib/features/timeline/presentation/widgets/year_month_timeline.dart`: `GestureDetector` 追加、`add_event_dialog.dart` インポート追加
  - `lib/features/timeline/presentation/widgets/year_timeline.dart`: 同上
  - `test/features/timeline/presentation/timeline_screen_test.dart`: タップ系テスト 7 件追加

---

## 2026-03-10 - [環境・バグ修正] IDE 指摘事項の修正

- **判断内容**: Androidビルドで発生していた「Unsupported class file major version 69」エラーと、テストコードの `const` コンストラクタ警告を修正。
- **理由**: 環境のJava 25がGradle 8.14で未サポートだったため、Android StudioバンドルのJDK 21を使用するよう設定を追加した。また、テストのパフォーマンス向上のため `const` を適用した。
- **影響範囲**:
  - `android/gradle.properties`: `org.gradle.java.home` にAndroid StudioのJDKパスを指定
  - `test/features/timeline/domain/life_event_test.dart`: `LifeEvent` の呼び出しを `const` に変更

## 2026-03-10 - [設計更新] Issue-001 解消：設計ドキュメントを実装に整合

- **判断内容**: QA検証で指摘された Issue-001（SOFTWARE_ARCHITECTURE v4.0 と実装のモデル乖離）を解消。設計ドキュメントを実装に合わせて更新（QAレポート推奨の方針A）。
- **理由**: 実装の EventCategory 単一 enum モデルは十分に機能しており全テスト pass。2 enum 分離へのリファクタリングは工数対効果が低い。
- **影響範囲**:
  - `docs/SOFTWARE_ARCHITECTURE.md` v4.0 → v4.1: EventSubCategory の2 enum 定義を EventCategory 単一 enum に変更、LifeEvent モデルを実態に合わせて更新
  - `docs/ARCHITECTURE.md` v3.0 → v3.1: Firestore データモデルの subCategory を category に変更

---

## 2026-03-10 - [QA検証完了] Phase 2 品質検証結果: PASS

- **判断内容**: QA Agent による品質検証が完了。判定: PASS。
- **理由**: 品質基準3条件をすべて達成（56テスト全 pass / dart analyze エラー0件 / Logic層カバレッジ 98.6%）
- **影響範囲**: `docs/qa_report.md`（新規作成）
- **指摘事項**: 5件（Major 2件 → Issue-001解消済み、Issue-004は実装済みだがテスト未実装 / Minor 3件）

---

## 2026-03-10 - [実装完了] Phase 2 実装タスク I-02〜I-07 完了

- **判断内容**: 女性キャリア特化機能の全実装を完了。全56テスト pass、dart analyze エラー0件。
- **理由**: TDD方式でドメインモデル → ロジック → UI の順に実装。
- **影響範囲**:
  - **新規ファイル**: `constraint_result.dart`, `constraint_checker_provider.dart`, `constraint_warning.dart` + 対応テスト3ファイル
  - **変更ファイル**: `life_event.dart`（maternityLeave追加）, `event_style.dart`（カテゴリ別カラー）, `timeline_screen.dart`, `year_month_timeline.dart`, `year_timeline.dart`（制約警告表示）, `add_event_dialog.dart`（制約プレビュー）
  - **テスト結果**: 56テスト pass（既存41 + 新規15）

---

## 2026-03-09 - [実装判断] EventCategory enum の設計適応

- **判断内容**: SOFTWARE_ARCHITECTURE v4.0 で提案された `WorkSubCategory` / `PrivateSubCategory` の2 enum分離を見送り、既存の `EventCategory` enum を拡張する方針とした。
- **理由**:
  1. 既存の `EventCategory` は `isWork` フラグで仕事/プライベートを区別しており、設計の2 enum方式と機能的に等価。
  2. 既存コード（LifeEvent, EventRepository, Provider, UI, テスト全15+件）がすべて `EventCategory` に依存しており、2 enumへのリファクタリングは大量の破壊的変更を伴う。
  3. 既存の `EventCategory` には設計で必要なカテゴリの大半（jobChange, promotion, retirement, childbirth, childcareLeave, returnToWork, caregiving, marriage）が既に存在する。
  4. 不足しているのは `maternityLeave`（産休取得）のみ。
- **影響範囲**:
  - `lib/features/timeline/domain/life_event.dart` - `maternityLeave` を追加
  - `lib/features/timeline/presentation/widgets/event_style.dart` - アイコン・カラー追加
  - 既存テストは変更不要（後方互換性維持）

---

## 2026-03-09 - [Phase 2 開始] 実装フェーズ着手

- **判断内容**: Phase 1（設計フェーズ）の人間レビュー承認を受け、Phase 2（実装フェーズ）を開始。
- **理由**: ユーザーから「問題ありません。進めてください。」の承認を取得。
- **影響範囲**: WBS Phase 2 の全タスク（I-02〜I-08）

---

## 2026-03-09 - [Phase 1 完了] 設計フェーズ全タスク完了

- **判断内容**: Phase 1（設計フェーズ）の全タスク D-01〜D-04 を完了。人間レビュー待ち（D-05）に遷移。
- **理由**: PRD v3.0、ARCHITECTURE v3.0、SOFTWARE_ARCHITECTURE v4.0、test_scenarios v1.0 の4成果物が揃い、設計の整合性を確認済み。
- **影響範囲**: `docs/WBS.md` のステータスを全て DONE に更新。

---

## 2026-03-09 - [テストシナリオ設計] test_scenarios.md v1.0 作成

- **判断内容**: TESTING_POLICY v2.0 に基づき、47件のテストシナリオを設計（P0: 25件、P1: 20件、P2: 2件）。
- **理由**: 女性キャリア特化機能（サブカテゴリ、制約チェック）の品質担保に必要。既存テスト4ファイルとの重複を排除。
- **影響範囲**: `docs/test_scenarios.md`（新規作成）
- **テストピラミッド比率**: Data+Logic 66% / Presentation 26% / 統合 8%（目安 70/25/5 にほぼ合致）

---

## 2026-03-09 - [アーキテクチャ判断] 女性キャリア特化機能の設計追加

- **判断内容**: PRD v3.0、ARCHITECTURE v3.0、SOFTWARE_ARCHITECTURE v4.0 を策定。女性キャリア検討に不可欠なイベントサブカテゴリ（産休・育休・復職等）と制約チェック機能（転職-出産間の育休取得可能性チェック）を設計に追加した。
- **理由**: 女性のキャリア検討では、転職と産休・育休のタイミングが法的制約（育児・介護休業法の労使協定による入社1年未満除外規定）により密接に関連する。この制約をアプリ上で可視化することが、プロダクトのコアバリューである「主体的なライフプラン検討」に直結する。
- **影響範囲**:
  - `docs/PRD.md` - F-02-SUB（サブカテゴリ）、F-10（制約可視化）をMVPに追加、F-11/F-12をPhase 2に配置
  - `docs/ARCHITECTURE.md` - Firestoreデータモデルに `subCategory` フィールド追加、`iconType` を統合廃止
  - `docs/SOFTWARE_ARCHITECTURE.md` - EventSubCategory enum、ConstraintResult モデル、ConstraintCheckerProvider、関連ウィジェット・テストファイルを追加

### 主要な設計判断の詳細

1. **iconType廃止とsubCategoryへの統合**: サブカテゴリとアイコンが1対1対応するため、別フィールド管理は冗長。統合により data model を簡潔化。
2. **サブカテゴリを2つのenumに分離（WorkSubCategory / PrivateSubCategory）**: 単一enumだとwork/privateの親子関係をコンパイル時に検証できない。Freezedとの相性も考慮。
3. **制約チェック結果の非永続化**: イベント一覧から毎回算出する導出データとし、DB保存しない。イベント変更時の整合性維持コスト回避と、MVP規模（数十件）での性能の十分さが根拠。
4. **ConstraintCheckerをRiverpod Providerとして実装**: ref.watchによる自動再計算で常に最新状態を反映。純粋関数としてテスト容易性を確保。
5. **MVPスコープの管理**: F-10の基本部分（2ルール: C-01, C-02）のみMVPに含め、高度な制約チェック（F-12）とブランク可視化（F-11）はPhase 2に配置。

---

## 2026-03-26 - [実装] タイムライン UI 改善 5機能

- **判断内容**: 以下の5機能を実装した
  1. 同タイミングのイベントを縦積み表示（スタック）— 同日同レーンのイベントをインデックス順に縦に並べ、行高を動的に計算
  2. イベントの編集・削除 — `EditEventDialog` 新規作成、`updateEvent()` を Provider に追加、詳細ダイアログに「編集」「削除（確認付き）」ボタン追加
  3. イベント間の関連付け・解除 UI — 詳細ダイアログの「関連を追加」でリンクモードに入り、別イベントをタップして依存種別を選択; 詳細ダイアログで既存関連を「解除」可能
  4. カスケード連動移動 — 既存機能を維持しつつドラッグ drop 後にまとめて移動
  5. ドラッグ中ゴーストカード — `DragTarget.onMove` で連動対象イベントの移動先にリアルタイムでゴーストカードを表示
- **理由**: ユーザー要求に基づく UX 改善
- **影響範囲**:
  - `lib/features/timeline/logic/timeline_events_provider.dart` — updateEvent() 追加
  - `lib/features/timeline/presentation/edit_event_dialog.dart` — 新規作成
  - `lib/features/timeline/presentation/widgets/year_month_timeline.dart` — 全面改修
  - `lib/features/timeline/presentation/widgets/year_timeline.dart` — 全面改修

<!-- ここより上に新しいエントリを追記する -->
