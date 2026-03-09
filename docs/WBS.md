# WBS（Work Breakdown Structure）

**Last Updated**: 2025-XX-XX
**Owner**: メインエージェント（Project Manager）

## Phase 1: 設計（Architect主導）

| ID | タスク | 担当Agent | 状態 | 成果物 |
|---|---|---|---|---|
| D-01 | PRD策定 | Architect | ⬜ TODO | `docs/PRD.md` |
| D-02 | インフラ設計 | Architect | ⬜ TODO | `docs/ARCHITECTURE.md` |
| D-03 | ソフトウェア設計 | Architect | ⬜ TODO | `docs/SOFTWARE_ARCHITECTURE.md` |
| D-04 | テストシナリオ設計 | QA | ⬜ TODO | `docs/test_scenarios.md` |
| D-05 | **人間レビュー待ち** | Human | ⬜ BLOCKED | - |

## Phase 2: 実装（Implementer主導）

| ID | タスク | 担当Agent | 状態 | 成果物 |
|---|---|---|---|---|
| I-01 | プロジェクト初期化（flutter create, pubspec.yaml） | Implementer | ⬜ TODO | `pubspec.yaml` |
| I-02 | ドメインモデル実装（LifeEvent, UserProfile） | Implementer | ⬜ TODO | `lib/features/*/domain/` |
| I-03 | Repository実装（InMemory） | Implementer | ⬜ TODO | `lib/features/*/data/` |
| I-04 | Logic層実装（Provider） | Implementer | ⬜ TODO | `lib/features/*/logic/` |
| I-05 | UI実装（タイムライン画面） | Implementer | ⬜ TODO | `lib/features/timeline/presentation/` |
| I-06 | UI実装（プロフィール設定） | Implementer | ⬜ TODO | `lib/features/profile/presentation/` |
| I-07 | ルーティング設定 | Implementer | ⬜ TODO | `lib/core/router/` |
| I-08 | QA検証 | QA | ⬜ TODO | `docs/qa_report.md` |

## 状態の定義

- ⬜ TODO: 未着手
- 🔄 IN_PROGRESS: 作業中
- ✅ DONE: 完了
- ❌ BLOCKED: ブロック中（理由を備考に記載）
- 🔁 REDO: 差し戻し（QAまたは人間からのフィードバック）
