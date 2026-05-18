# Feature Registry

## 凡例
- 🟢 RELEASED: 実装・テスト済み。変更する場合は影響分析が必要。
- 🟡 IN_PROGRESS: 実装中。
- ⚪ PLANNED: PRD定義済み・未実装。
- 🔵 MODIFY: 既存機能に変更が必要。変更内容を備考に記載。

## Phase 1 (MVP)

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-01 | タイムライン表示 | 🟢 RELEASED | `lib/features/timeline/presentation/timeline_screen.dart`, `widgets/year_month_timeline.dart`, `widgets/year_timeline.dart` | `test/features/timeline/presentation/timeline_screen_test.dart` | 制約警告アイコン表示、依存線描画、D&D対応済み。デフォルト表示を年月表示に修正 |
| F-02 | イベント管理 | 🟢 RELEASED | `lib/features/timeline/data/event_repository.dart`, `logic/timeline_events_provider.dart`, `presentation/add_event_dialog.dart`, `presentation/edit_event_dialog.dart` | `test/features/timeline/logic/timeline_events_provider_test.dart`, `test/features/timeline/presentation/widgets/add_event_dialog_test.dart`, `test/features/timeline/presentation/edit_event_dialog_test.dart` | v6.0: LifeEventにcatalogId/parentEventId/kind/budgetYen追加。Wave4: EditEventDialogに予算フィールド追加 |
| F-02-SUB | イベントサブカテゴリ | 🟢 RELEASED | `lib/features/timeline/domain/life_event.dart`, `presentation/widgets/event_style.dart` | `test/features/timeline/domain/life_event_test.dart` | v6.0: EventCategory enumを廃止、catalogId文字列 + PredefinedCatalogRegistryに移行。event_style.dart の categoryColor/categoryIcon を catalogColor/catalogIcon に置換 |
| F-03 | プロフィール設定 | 🟢 RELEASED | `lib/features/user_profile/user_profile.dart`, `profile_settings_dialog.dart` | - | - |
| F-10 | ライフイベント制約の可視化 | 🟢 RELEASED | `lib/features/timeline/domain/constraint_result.dart`, `logic/constraint_checker_provider.dart`, `presentation/widgets/constraint_warning.dart` | `test/features/timeline/domain/constraint_result_test.dart`, `test/features/timeline/logic/constraint_checker_provider_test.dart`, `test/features/timeline/presentation/widgets/constraint_warning_test.dart` | v6.0: C-01/C-02/C-03ルールをcatalogId参照方式に移行。C-03オフセット検証テストのID形式バグ修正 |
| F-MVP-DATA | データ永続化（ローカル） | 🟢 RELEASED | `lib/features/timeline/data/event_repository.dart` | - | InMemory実装（ゲストモード用に継続使用） |

## Phase 2（目標逆算機能 + カタログD&Dピボット）

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-06 | イベント編集・削除 | 🟢 RELEASED | `lib/features/timeline/presentation/edit_event_dialog.dart`, `logic/timeline_events_provider.dart` | `test/features/timeline/presentation/edit_event_dialog_test.dart` | Wave4: 予算フィールド（budgetYen）追加。catalogのdefaultBudgetYenをプレースホルダーに表示 |
| F-20 | イベント依存関係 | 🟢 RELEASED | `lib/features/timeline/domain/event_dependency.dart`, `lib/features/timeline/data/dependency_repository.dart`, `lib/features/timeline/logic/dependency_provider.dart` | `test/features/timeline/domain/event_dependency_test.dart`, `test/features/timeline/data/dependency_repository_test.dart`, `test/features/timeline/logic/dependency_provider_test.dart` | v6.0: EventDependencyに`strength: hard/soft`を追加（ADR-012） |
| F-21 | ゴールテンプレート | 🟢 RELEASED | `lib/features/timeline/domain/goal_template.dart`, `lib/features/timeline/data/goal_template_data.dart`, `lib/features/timeline/logic/goal_template_provider.dart`, `lib/features/timeline/presentation/goal_setup_dialog.dart` | `test/features/timeline/domain/goal_template_test.dart`, `test/features/timeline/logic/goal_template_provider_test.dart`, `test/features/timeline/presentation/goal_setup_dialog_test.dart` | Wave4: 結婚(tmpl-marriage)/転職(tmpl-job-change)/住宅購入(tmpl-home-purchase)テンプレートを追加 |
| F-22 | ドラッグ&ドロップ移動 | 🟢 RELEASED | `lib/features/timeline/logic/cascade_move_provider.dart`, `lib/features/timeline/presentation/widgets/year_month_timeline.dart`, `widgets/year_timeline.dart`, `widgets/event_card.dart` | `test/features/timeline/logic/cascade_move_provider_test.dart` | Wave4: 子マイルストーン（parentEventIdによる親子関係）がカスケード移動に追従するよう修正 |
| F-23 | 依存関係の可視化 | 🟢 RELEASED | `lib/features/timeline/presentation/widgets/dependency_connector.dart` | `test/features/timeline/presentation/widgets/dependency_connector_test.dart` | - |
| F-25 | イベント縦積み表示 | 🟢 RELEASED | `lib/features/timeline/presentation/widgets/year_month_timeline.dart`, `widgets/year_timeline.dart` | - | - |
| F-26 | 依存関係の手動管理UI | 🟢 RELEASED | `lib/features/timeline/presentation/widgets/year_month_timeline.dart`, `widgets/year_timeline.dart` | - | - |
| **F-30** | **規定イベントカタログ** | 🟢 RELEASED | `lib/features/catalog/domain/predefined_life_event.dart`, `lib/features/catalog/data/predefined_catalog_registry.dart`, `lib/features/catalog/data/groups/*.dart`, `lib/features/catalog/logic/catalog_provider.dart` | `test/features/catalog/domain/predefined_life_event_test.dart`, `test/features/catalog/data/catalog_consistency_test.dart`, `test/features/catalog/logic/catalog_provider_test.dart` | Wave4: lifestyle グループに home-purchase/home-search/home-purchase-signing/move-in の4件追加（計44件）。catalogSearchQueryProviderは既存済みを確認 |
| **F-31** | **マイルストーン管理** | ⚪ PLANNED | (Wave 3-4) | - | ADR-011: parentEventIdで親イベントの子要素として配置。MilestoneTemplateから既定生成 |
| **F-32** | **予算プリセット** | 🟢 RELEASED | `lib/features/timeline/presentation/edit_event_dialog.dart` | `test/features/timeline/presentation/edit_event_dialog_test.dart` | Wave4: EditEventDialogにbudgetYen入力欄追加。catalogのdefaultBudgetYenをプレースホルダー表示 |
| **F-33** | **制約強度の可視化（hard/soft）** | ⚪ PLANNED | (Wave 3-4) | - | ADR-012: hard違反=赤、soft違反=黄。ドロップはブロックしない |
| F-09 | テンプレート拡充（Wave4） | 🟢 RELEASED | `lib/features/timeline/data/goal_template_data.dart` | `test/features/timeline/logic/goal_template_provider_test.dart` | Wave4: 結婚/転職/住宅購入の3テンプレートを追加 |

## Phase 3（認証・クラウド同期 ← 実装済み）

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-AUTH | Google認証（ゲストモード付き） | 🟢 RELEASED | `lib/features/auth/data/auth_repository.dart`, `web_auth_repository.dart`, `mobile_auth_repository.dart`, `logic/auth_provider.dart`, `presentation/sign_in_dialog.dart`, `presentation/signup_profile_dialog.dart` | - | - |
| F-FIRESTORE | Firestoreデータ永続化 | 🔵 MODIFY | `lib/features/timeline/data/firestore_event_repository.dart`, `firestore_dependency_repository.dart`, `data/event_repository.dart`（auth連動切替） | - | v6.0: events スキーマから category 削除、catalogId/parentEventId/kind/budgetYen 追加。dependencies に strength 追加 |
| F-USER | ユーザープロフィールのクラウド保存 | 🟢 RELEASED | `lib/features/user_profile/data/user_repository.dart`, `user_profile.dart`（AsyncNotifier化） | - | - |

> 旧 F-30 (Google認証) はピボットに伴い F-AUTH に改名（F-30 を新規機能IDに割り当てるため）。
> 同様に旧 F-31 → F-FIRESTORE、旧 F-32 → F-USER に改名。

## Phase 4（将来構想）

| Feature ID | 機能名 | 状態 | 実装ファイル | テストファイル | 備考 |
|---|---|---|---|---|---|
| F-04 | ユーザー定義カタログ | ⚪ PLANNED | - | - | 規定カタログにない項目をユーザーが自由追加 |
| F-05 | 将来計画モード | ⚪ PLANNED | - | - | - |
| F-11 | キャリアブランク可視化 | ⚪ PLANNED | - | - | - |
| F-12 | 制約チェッカー（高度版） | ⚪ PLANNED | - | - | F-10 / F-33 の拡張 |
| F-24 | 逆算タイムライン表示 | ⚪ PLANNED | - | - | ゴールから現在に向かって逆順表示 |
| F-99 | 介護グループのカタログ追加 | ⚪ PLANNED | - | - | 初版スコープ外。ターゲットを40代以降に広げる際に再検討（PDR-005） |
