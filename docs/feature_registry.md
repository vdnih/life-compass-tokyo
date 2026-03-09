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
| F-02 | イベント管理 | 🟢 RELEASED | `lib/features/timeline/data/event_repository.dart`, `logic/timeline_events_provider.dart`, `presentation/add_event_dialog.dart` | `test/features/timeline/logic/timeline_events_provider_test.dart`, `test/features/timeline/presentation/widgets/add_event_dialog_test.dart` | - |
| F-02-SUB | イベントサブカテゴリ | 🟢 RELEASED | `lib/features/timeline/domain/life_event.dart`（EventCategory enum）, `presentation/widgets/event_style.dart` | `test/features/timeline/domain/life_event_test.dart` | maternityLeave追加。既存EventCategoryを拡張 |
| F-03 | プロフィール設定 | 🟢 RELEASED | `lib/features/user_profile/user_profile.dart`, `profile_settings_dialog.dart` | - | - |
| F-10 | ライフイベント制約の可視化 | 🟢 RELEASED | `lib/features/timeline/domain/constraint_result.dart`, `logic/constraint_checker_provider.dart`, `presentation/widgets/constraint_warning.dart` | `test/features/timeline/domain/constraint_result_test.dart`, `test/features/timeline/logic/constraint_checker_provider_test.dart`, `test/features/timeline/presentation/widgets/constraint_warning_test.dart` | C-01, C-02 ルール実装済み |
| F-MVP-DATA | データ永続化（ローカル） | 🟢 RELEASED | `lib/features/timeline/data/event_repository.dart` | - | InMemory実装 |

## Phase 2

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-04 | カテゴリ拡充（ユーザー定義） | ⚪ PLANNED | - | - | - |
| F-05 | 将来計画モード | ⚪ PLANNED | - | - | - |
| F-06 | イベント編集 | ⚪ PLANNED | - | - | 新規画面。F-02のrepositoryにupdate()追加が必要 |
| F-11 | キャリアブランク可視化 | ⚪ PLANNED | - | - | - |
| F-12 | 制約チェッカー（高度版） | ⚪ PLANNED | - | - | F-10の拡張 |
