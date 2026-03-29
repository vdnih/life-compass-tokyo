# Feature Registry

## 凡例
- 🟢 RELEASED: 実装・テスト済み。変更する場合は影響分析が必要。
- 🟡 IN_PROGRESS: 実装中。
- ⚪ PLANNED: PRD定義済み・未実装。
- 🔵 MODIFY: 既存機能に変更が必要。変更内容を備考に記載。

## Phase 1 (MVP)

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-01 | タイムライン表示 | 🟢 RELEASED | `lib/features/timeline/presentation/timeline_screen.dart`, `widgets/year_month_timeline.dart`, `widgets/year_timeline.dart` | `test/features/timeline/presentation/timeline_screen_test.dart` | 制約警告アイコン表示、依存線描画、D&D対応済み。目標設定ボタン追加（I2-06） |
| F-02 | イベント管理 | 🟢 RELEASED | `lib/features/timeline/data/event_repository.dart`, `logic/timeline_events_provider.dart`, `presentation/add_event_dialog.dart`, `presentation/edit_event_dialog.dart` | `test/features/timeline/logic/timeline_events_provider_test.dart`, `test/features/timeline/presentation/widgets/add_event_dialog_test.dart` | updateEvent/moveEvent/deleteEvent実装済み。EditEventDialog追加（I3-01） |
| F-02-SUB | イベントサブカテゴリ | 🟢 RELEASED | `lib/features/timeline/domain/life_event.dart`（EventCategory enum）, `presentation/widgets/event_style.dart` | `test/features/timeline/domain/life_event_test.dart` | maternityLeave追加。既存EventCategoryを拡張 |
| F-03 | プロフィール設定 | 🟢 RELEASED | `lib/features/user_profile/user_profile.dart`, `profile_settings_dialog.dart` | - | - |
| F-10 | ライフイベント制約の可視化 | 🟢 RELEASED | `lib/features/timeline/domain/constraint_result.dart`, `logic/constraint_checker_provider.dart`, `presentation/widgets/constraint_warning.dart` | `test/features/timeline/domain/constraint_result_test.dart`, `test/features/timeline/logic/constraint_checker_provider_test.dart`, `test/features/timeline/presentation/widgets/constraint_warning_test.dart` | C-01, C-02, C-03 ルール実装済み（I2-05） |
| F-MVP-DATA | データ永続化（ローカル） | 🟢 RELEASED | `lib/features/timeline/data/event_repository.dart` | - | InMemory実装（ゲストモード用に継続使用） |

## Phase 2（目標逆算機能）

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-06 | イベント編集・削除 | 🟢 RELEASED | `lib/features/timeline/presentation/edit_event_dialog.dart`, `logic/timeline_events_provider.dart` | - | EditEventDialog（全フィールド編集、endDateクリア対応）。削除は確認ダイアログ付き・依存関係も連動削除。詳細ダイアログから起動（I3-01） |
| F-20 | イベント依存関係 | 🟢 RELEASED | `lib/features/timeline/domain/event_dependency.dart`, `lib/features/timeline/data/dependency_repository.dart`, `lib/features/timeline/logic/dependency_provider.dart` | `test/features/timeline/domain/event_dependency_test.dart`, `test/features/timeline/data/dependency_repository_test.dart`, `test/features/timeline/logic/dependency_provider_test.dart` | ドメインモデル・repository・provider実装済み（I2-01, I2-02, I2-04）。循環検出BFS実装済み |
| F-21 | ゴールテンプレート | 🟢 RELEASED | `lib/features/timeline/domain/goal_template.dart`, `lib/features/timeline/data/goal_template_data.dart`, `lib/features/timeline/logic/goal_template_provider.dart`, `lib/features/timeline/presentation/goal_setup_dialog.dart` | `test/features/timeline/domain/goal_template_test.dart`, `test/features/timeline/logic/goal_template_provider_test.dart`, `test/features/timeline/presentation/goal_setup_dialog_test.dart` | 出産テンプレート実装済み（I2-03, I2-04, I2-06）。7件のイベント自動生成。ゴール設定ダイアログUI実装済み |
| F-22 | ドラッグ&ドロップ移動 | 🟢 RELEASED | `lib/features/timeline/logic/cascade_move_provider.dart`, `lib/features/timeline/presentation/widgets/year_month_timeline.dart`, `lib/features/timeline/presentation/widgets/year_timeline.dart`, `lib/features/timeline/presentation/widgets/event_card.dart` | `test/features/timeline/logic/cascade_move_provider_test.dart` | LongPressDraggable + DragTarget + カスケード移動ロジック実装済み（I2-04, I2-07）。ドラッグ中にゴーストカードでリアルタイムプレビュー追加（I3-03） |
| F-23 | 依存関係の可視化 | 🟢 RELEASED | `lib/features/timeline/presentation/widgets/dependency_connector.dart` | `test/features/timeline/presentation/widgets/dependency_connector_test.dart` | CustomPainterで依存タイプ別線描画（実線/点線/矢印）実装済み（I2-07） |
| F-25 | イベント縦積み表示 | 🟢 RELEASED | `lib/features/timeline/presentation/widgets/year_month_timeline.dart`, `widgets/year_timeline.dart` | - | 同月同レーンの複数イベントを縦スタック表示。スタック数に応じて行高を動的計算（I3-02） |
| F-26 | 依存関係の手動管理UI | 🟢 RELEASED | `lib/features/timeline/presentation/widgets/year_month_timeline.dart`, `widgets/year_timeline.dart` | - | リンクモードで2イベントを選択し依存種別を選んで関連付け。詳細ダイアログで既存関連の「解除」可能。循環依存ブロック（I3-04） |

## Phase 3（認証・クラウド同期 ← 実装済み）

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-30 | Google認証（ゲストモード付き） | 🟢 RELEASED | `lib/features/auth/data/auth_repository.dart`, `web_auth_repository.dart`, `mobile_auth_repository.dart`, `logic/auth_provider.dart`, `presentation/sign_in_dialog.dart`, `presentation/signup_profile_dialog.dart` | - | Web: signInWithPopup / Mobile: google_sign_in。未認証でUI閲覧可能 |
| F-31 | Firestoreデータ永続化 | 🟢 RELEASED | `lib/features/timeline/data/firestore_event_repository.dart`, `firestore_dependency_repository.dart`, `data/event_repository.dart`（auth連動切替） | - | 認証状態に応じてInMemory↔Firestoreを自動切替 |
| F-32 | ユーザープロフィールのクラウド保存 | 🟢 RELEASED | `lib/features/user_profile/data/user_repository.dart`, `user_profile.dart`（AsyncNotifier化） | - | サインアップ時に名前・誕生日を収集しFirestoreに保存 |

## Phase 4（将来構想）

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-04 | カテゴリ拡充（ユーザー定義） | ⚪ PLANNED | - | - | - |
| F-05 | 将来計画モード | ⚪ PLANNED | - | - | - |
| F-11 | キャリアブランク可視化 | ⚪ PLANNED | - | - | - |
| F-12 | 制約チェッカー（高度版） | ⚪ PLANNED | - | - | F-10の拡張 |
| F-24 | 逆算タイムライン表示 | ⚪ PLANNED | - | - | ゴールから現在に向かって逆順表示 |
