# WBS（Work Breakdown Structure）

**Last Updated**: 2026-03-26
**Owner**: メインエージェント（Project Manager）

## Phase 1: 設計（Architect主導）

| ID | タスク | 担当Agent | 状態 | 成果物 |
|---|---|---|---|---|
| D-01 | PRD策定（女性キャリア特化機能追加: F-02-SUB, F-10） | Architect | ✅ DONE | `docs/PRD.md` v3.0 |
| D-02 | インフラ設計（subCategoryフィールド追加、制約非永続化方針） | Architect | ✅ DONE | `docs/ARCHITECTURE.md` v3.0 |
| D-03 | ソフトウェア設計（SubCategory enum, ConstraintChecker追加） | Architect | ✅ DONE | `docs/SOFTWARE_ARCHITECTURE.md` v4.0 |
| D-04 | テストシナリオ設計（47シナリオ、P0: 25件） | QA | ✅ DONE | `docs/test_scenarios.md` v1.0 |
| D-05 | **人間レビュー待ち** | Human | ⬜ BLOCKED | - |

## Phase 2: 実装（Implementer主導）

| ID | タスク | 担当Agent | 状態 | 成果物 |
|---|---|---|---|---|
| I-01 | プロジェクト初期化（flutter create, pubspec.yaml） | Implementer | ✅ DONE | `pubspec.yaml` |
| I-02 | ドメインモデル拡張（maternityLeave追加, ConstraintResult新規） | Implementer | ✅ DONE | `lib/features/timeline/domain/` |
| I-03 | Repository実装（InMemory） | Implementer | ✅ DONE | `lib/features/*/data/` |
| I-04 | Logic層実装（ConstraintCheckerProvider新規） | Implementer | ✅ DONE | `lib/features/timeline/logic/` |
| I-05 | UI実装（制約警告表示、サブカテゴリカラー対応） | Implementer | ✅ DONE | `lib/features/timeline/presentation/` |
| I-06 | UI実装（プロフィール設定） | Implementer | ✅ DONE | `lib/features/profile/presentation/` |
| I-07 | ルーティング設定 | Implementer | ✅ DONE | `lib/core/router/`（MVPでは単一画面のため不要） |
| I-08 | QA検証 | QA | ✅ DONE | `docs/qa_report.md` v1.0 (判定: PASS) |

## Phase 3: 設計v2（目標逆算機能 - Architect主導）

| ID | タスク | 担当Agent | 状態 | 成果物 |
|---|---|---|---|---|
| D2-01 | PRD v4.0 策定（コンセプト変更、F-20〜F-24追加） | Architect | ✅ DONE | `docs/PRD.md` v4.0 |
| D2-02 | インフラ設計 v4.0（dependencies コレクション追加） | Architect | ✅ DONE | `docs/ARCHITECTURE.md` v4.0 |
| D2-03 | ソフトウェア設計 v5.0（新モデル・プロバイダー追加） | Architect | ✅ DONE | `docs/SOFTWARE_ARCHITECTURE.md` v5.0 |
| D2-04 | テストシナリオ v2.0（Phase 2用31シナリオ追加） | QA | ✅ DONE | `docs/test_scenarios.md` v2.0 |
| D2-05 | **人間レビュー待ち** | Human | ⬜ BLOCKED | - |

## Phase 4: 実装v2（目標逆算機能 - Implementer主導）

| ID | タスク | 担当Agent | 状態 | 成果物 |
|---|---|---|---|---|
| I2-01 | ドメインモデル拡張（LifeEvent id追加、EventDependency、GoalTemplate新規） | Implementer | ✅ DONE | `lib/features/timeline/domain/` |
| I2-02 | Repository層拡張（updateEvent追加、DependencyRepository新規） | Implementer | ✅ DONE | `lib/features/timeline/data/` |
| I2-03 | ゴールテンプレートデータ定義（出産テンプレート） | Implementer | ✅ DONE | `lib/features/timeline/data/goal_template_data.dart` |
| I2-04 | Logic層実装（DependencyProvider、GoalTemplateProvider、CascadeMoveProvider） | Implementer | ✅ DONE | `lib/features/timeline/logic/` |
| I2-05 | 制約チェッカー拡張（C-03: 依存オフセット違反） | Implementer | ✅ DONE | `lib/features/timeline/logic/constraint_checker_provider.dart` |
| I2-06 | UI実装（ゴール設定ダイアログ、テンプレート選択） | Implementer | ✅ DONE | `lib/features/timeline/presentation/` |
| I2-07 | UI実装（依存関係線の描画、ドラッグ&ドロップ） | Implementer | ✅ DONE | `lib/features/timeline/presentation/widgets/` |
| I2-08 | QA検証 | QA | ⬜ TODO | `docs/qa_report_v2.md` |

## 状態の定義

- ⬜ TODO: 未着手
- 🔄 IN_PROGRESS: 作業中
- ✅ DONE: 完了
- ❌ BLOCKED: ブロック中（理由を備考に記載）
- 🔁 REDO: 差し戻し（QAまたは人間からのフィードバック）
