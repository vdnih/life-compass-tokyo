# Feature Registry

## 凡例
- 🟢 RELEASED: 実装・テスト済み。変更する場合は影響分析が必要。
- 🟡 IN_PROGRESS: 実装中。
- ⚪ PLANNED: PRD定義済み・未実装。
- 🔵 MODIFY: 既存機能に変更が必要。変更内容を備考に記載。

## Phase 1 (MVP)

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-01 | タイムライン表示 | 🟢 RELEASED | `lib/features/timeline/presentation/timeline_screen.dart`, `widgets/year_month_timeline.dart`, `widgets/year_timeline.dart` | `test/features/timeline/presentation/timeline_screen_test.dart` | 制約警告アイコン表示対応済み |
| F-02 | イベント管理 | 🟢 RELEASED | `lib/features/timeline/data/event_repository.dart`, `logic/timeline_events_provider.dart`, `presentation/add_event_dialog.dart` | `test/features/timeline/logic/timeline_events_provider_test.dart`, `test/features/timeline/presentation/widgets/add_event_dialog_test.dart` | updateEvent/moveEvent追加済み（I2-01） |
| F-02-SUB | イベントサブカテゴリ | 🟢 RELEASED | `lib/features/timeline/domain/life_event.dart`（EventCategory enum）, `presentation/widgets/event_style.dart` | `test/features/timeline/domain/life_event_test.dart` | maternityLeave追加。既存EventCategoryを拡張 |
| F-03 | プロフィール設定 | 🟢 RELEASED | `lib/features/user_profile/user_profile.dart`, `profile_settings_dialog.dart` | - | - |
| F-10 | ライフイベント制約の可視化 | 🟢 RELEASED | `lib/features/timeline/domain/constraint_result.dart`, `logic/constraint_checker_provider.dart`, `presentation/widgets/constraint_warning.dart` | `test/features/timeline/domain/constraint_result_test.dart`, `test/features/timeline/logic/constraint_checker_provider_test.dart`, `test/features/timeline/presentation/widgets/constraint_warning_test.dart` | C-01, C-02, C-03 ルール実装済み（I2-05） |
| F-MVP-DATA | データ永続化（ローカル） | 🟢 RELEASED | `lib/features/timeline/data/event_repository.dart` | - | InMemory実装 |

## Phase 2（目標逆算機能）

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-06 | イベント編集 | ⚪ PLANNED | - | - | 新規画面。F-02のrepositoryにupdate()追加が必要 |
| F-20 | イベント依存関係 | 🟢 RELEASED | `lib/features/timeline/domain/event_dependency.dart`, `lib/features/timeline/data/dependency_repository.dart`, `lib/features/timeline/logic/dependency_provider.dart` | `test/features/timeline/domain/event_dependency_test.dart`, `test/features/timeline/data/dependency_repository_test.dart`, `test/features/timeline/logic/dependency_provider_test.dart` | ドメインモデル・repository・provider実装済み（I2-01, I2-02, I2-04）。循環検出BFS実装済み |
| F-21 | ゴールテンプレート | 🟢 RELEASED | `lib/features/timeline/domain/goal_template.dart`, `lib/features/timeline/data/goal_template_data.dart`, `lib/features/timeline/logic/goal_template_provider.dart` | `test/features/timeline/domain/goal_template_test.dart`, `test/features/timeline/logic/goal_template_provider_test.dart` | 出産テンプレート実装済み（I2-03, I2-04）。7件のイベント自動生成 |
| F-22 | ドラッグ&ドロップ移動 | 🟡 IN_PROGRESS | `lib/features/timeline/logic/cascade_move_provider.dart`, `presentation/widgets/draggable_event_card.dart`（未実装） | `test/features/timeline/logic/cascade_move_provider_test.dart`, `presentation/widgets/draggable_event_card_test.dart`（未実装） | カスケード移動ロジック実装済み（I2-04）。UI（DraggableEventCard）は後続タスク |
| F-23 | 依存関係の可視化 | ⚪ PLANNED | `presentation/widgets/dependency_connector.dart` | `presentation/widgets/dependency_connector_test.dart` | CustomPainterで線描画 |

## Phase 3（将来構想）

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-04 | カテゴリ拡充（ユーザー定義） | ⚪ PLANNED | - | - | - |
| F-05 | 将来計画モード | ⚪ PLANNED | - | - | - |
| F-11 | キャリアブランク可視化 | ⚪ PLANNED | - | - | - |
| F-12 | 制約チェッカー（高度版） | ⚪ PLANNED | - | - | F-10の拡張 |
| F-24 | 逆算タイムライン表示 | ⚪ PLANNED | - | - | ゴールから現在に向かって逆順表示 |
