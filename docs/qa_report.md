# QA Report - 2026-03-10

**Version**: 1.0
**テスト実行環境**: macOS (Darwin 25.3.0) / Flutter SDK
**テスト実行日時**: 2026-03-10

## 1. サマリ

| 項目 | 結果 |
|---|---|
| テスト総数 | 56 |
| Pass | 56 |
| Fail | 0 |
| 全体カバレッジ | 63.4% |
| Logic層カバレッジ | 98.6% (目標80%以上: **達成**) |
| 静的解析 error | 0件 |
| 静的解析 warning | 0件 |
| 静的解析 info | 13件 |

### 判定: **PASS**

品質基準（TESTING_POLICY v2.0 セクション6）の3条件をすべて満たしている。

- [x] ユニットテスト + ウィジェットテスト: 全件Pass (56/56)
- [x] `dart analyze`: error 0件
- [x] Logic層テストカバレッジ: 98.6% (目標80%以上)

---

## 2. テスト結果詳細

### 2.1. テストファイル別結果

| テストファイル | テスト数 | 結果 |
|---|---|---|
| `test/features/timeline/domain/life_event_test.dart` | 18 | All Pass |
| `test/features/timeline/domain/constraint_result_test.dart` | 5 | All Pass |
| `test/features/timeline/logic/timeline_events_provider_test.dart` | 5 | All Pass |
| `test/features/timeline/logic/constraint_checker_provider_test.dart` | 12 | All Pass |
| `test/features/timeline/presentation/timeline_screen_test.dart` | 3 | All Pass |
| `test/features/timeline/presentation/widgets/add_event_dialog_test.dart` | 9 | All Pass |
| `test/features/timeline/presentation/widgets/constraint_warning_test.dart` | 4 | All Pass |
| **合計** | **56** | **All Pass** |

### 2.2. カバレッジ詳細

| ファイル | カバレッジ |
|---|---|
| `lib/features/timeline/logic/timeline_events_provider.dart` | 100% |
| `lib/features/timeline/logic/constraint_checker_provider.dart` | 97% |
| `lib/features/timeline/presentation/widgets/constraint_warning.dart` | 100% |
| `lib/features/timeline/domain/life_event.dart` | 80% |
| `lib/features/timeline/presentation/timeline_screen.dart` | 78% |
| `lib/features/timeline/data/event_repository.dart` | 75% |
| `lib/features/timeline/presentation/add_event_dialog.dart` | 73% |
| `lib/features/timeline/presentation/widgets/year_month_timeline.dart` | 59% |
| `lib/features/timeline/presentation/widgets/year_timeline.dart` | 58% |
| `lib/features/timeline/presentation/widgets/event_style.dart` | 40% |
| `lib/features/user_profile/user_profile.dart` | 33% |
| `lib/features/timeline/domain/constraint_result.dart` | 28% |
| `lib/features/user_profile/user_profile.g.dart` | 100% |
| `lib/features/user_profile/profile_settings_dialog.dart` | 2% |

**Logic層カバレッジ**: 98.6% (70/71行)

---

## 3. 静的解析結果

### `dart analyze` 結果

- **error**: 0件
- **warning**: 0件
- **info**: 13件

すべてのinfoは `test/features/timeline/domain/life_event_test.dart` における `prefer_const_constructors` リントルール。テストコード内でLifeEventコンストラクタに `const` キーワードを追加すべきという提案。機能的な問題はない。

| 件数 | ルール | 対象ファイル |
|---|---|---|
| 13 | `prefer_const_constructors` | `test/features/timeline/domain/life_event_test.dart` |

**推奨対応**: Implementerに `const` キーワードの追加を依頼する（Minor）。

---

## 4. テストシナリオカバレッジ分析

`docs/test_scenarios.md` で定義された47シナリオと実装済みテストの対応を分析した。

### 4.1. 実装済みシナリオ

#### Data層 (ConstraintResult モデル)

| シナリオID | 優先度 | 状態 | 実装テスト |
|---|---|---|---|
| TS-D-030 | P0 | **実装済** | `constraint_result_test.dart` - warning の ConstraintResult が正しく生成されること |
| TS-D-031 | P0 | **実装済** | `constraint_result_test.dart` - info の ConstraintResult が正しく生成されること |
| TS-D-032 | P1 | **実装済** | `constraint_result_test.dart` - 同じパラメータの2つの ConstraintResult が等しいこと |
| TS-D-033 | P1 | **実装済** | `constraint_result_test.dart` - values が warning と info の2つであること |

#### Logic層 (ConstraintCheckerProvider)

| シナリオID | 優先度 | 状態 | 実装テスト |
|---|---|---|---|
| TS-L-010 | P0 | **実装済** | 転職(2025-01) + 出産(2025-07) で C-01 warning |
| TS-L-011 | P0 | **実装済** | 転職(2025-01) + 産休(2025-12) で C-01 warning |
| TS-L-012 | P0 | **実装済** | 転職(2025-01) + 出産(2026-02) で警告なし |
| TS-L-013 | P0 | **実装済** | 転職(2025-01) + 出産(2026-01) で境界値テスト |
| TS-L-015 | P1 | **実装済** | 出産(2024-06) + 転職(2025-01) で順序テスト |
| TS-L-020 | P0 | **実装済** | 出産(2026-06) のみで C-02 info |
| TS-L-021 | P0 | **実装済** | 転職(2026-01) + 出産(2026-06) で C-02 info |
| TS-L-022 | P0 | **実装済** | 転職(2025-01) + 出産(2026-06) で情報なし |
| TS-L-023 | P0 | **実装済** | 転職(2025-06) + 出産(2026-06) で境界値テスト |
| TS-L-030 | P0 | **実装済** | 空のイベントリストで空リスト |
| TS-L-031 | P1 | **実装済** | 結婚 + 昇進で空リスト |
| TS-L-032 | P0 | **実装済** | C-01とC-02が同時に発生するケース |
| TS-L-037 | P0 | **実装済** | 産休イベントでC-01が発火すること |

#### Presentation層 (ConstraintWarning)

| シナリオID | 優先度 | 状態 | 実装テスト |
|---|---|---|---|
| TS-P-020 | P0 | **実装済** | Warning種別の制約結果が正しく表示されること |
| TS-P-021 | P0 | **実装済** | Info種別の制約結果が正しく表示されること |
| TS-P-022 | P0 | **実装済** | 空リストの場合、何も表示されないこと |
| TS-P-023 | P1 | **実装済** | 複数の制約結果がある場合、すべて表示されること |

### 4.2. 未実装シナリオ

#### 未実装 P0 シナリオ (3件)

| シナリオID | テスト層 | シナリオ名 | 理由/備考 |
|---|---|---|---|
| TS-D-001 | Data | save後にfetchEventsで取得できること | EventRepository単体テスト未作成。`test/features/timeline/data/` ディレクトリは空。Provider経由の間接テストは存在するが、Repository直接テストが必要。 |
| TS-D-003 | Data | deleteEvent後にfetchEventsから除外されること | 同上 |
| TS-D-005 | Data | サブカテゴリ付きイベントを保存・取得できること | 同上 |

**補足**: TS-D-001, TS-D-003 に相当するRepository操作は `timeline_events_provider_test.dart` でモック経由で間接的に検証されているが、Repository単体の振る舞い保証としては不十分。

#### 未実装 P0 シナリオ - モデル関連 (3件)

| シナリオID | テスト層 | シナリオ名 | 理由/備考 |
|---|---|---|---|
| TS-D-010 | Data | WorkSubCategory付きイベントが正しく生成されること | 実装がSoftware Architecture v4.0で定義されたWorkSubCategory/PrivateSubCategoryの分離モデルではなく、EventCategoryの単一enumモデルを使用している。設計と実装の乖離あり（後述Issue-001参照）。 |
| TS-D-011 | Data | PrivateSubCategory付きイベントが正しく生成されること | 同上 |
| TS-D-012 | Data | fromJson/toJsonでサブカテゴリが正しく変換されること | 同上 |

#### 未実装 P0 シナリオ - Presentation関連 (4件)

| シナリオID | テスト層 | シナリオ名 | 理由/備考 |
|---|---|---|---|
| TS-D-020 | Data | WorkSubCategory enum全8種の定義確認 | 設計と実装の乖離によりenumが存在しない |
| TS-D-021 | Data | PrivateSubCategory enum全5種の定義確認 | 同上 |
| TS-P-010 | Presentation | 仕事選択時にWorkSubCategory選択肢が表示されること | 既存テストはEventCategoryベースのカテゴリ表示をテスト済み（部分的にカバー） |
| TS-P-011 | Presentation | プライベート選択時にPrivateSubCategory選択肢が表示されること | 同上 |

#### 未実装 P0 シナリオ - Logic関連 (2件)

| シナリオID | テスト層 | シナリオ名 | 理由/備考 |
|---|---|---|---|
| TS-L-001 | Logic | WorkSubCategory付きイベントの追加が成功すること | 設計と実装の乖離により該当フィールドが存在しない |
| TS-L-002 | Logic | PrivateSubCategory付きイベントの追加が成功すること | 同上 |

#### 未実装 P0 シナリオ - Presentation (2件)

| シナリオID | テスト層 | シナリオ名 | 理由/備考 |
|---|---|---|---|
| TS-P-012 | Presentation | サブカテゴリを選択してイベントを追加できること | 設計と実装の乖離 |
| TS-P-014 | Presentation | 制約チェック結果がダイアログ内に表示されること | AddEventDialogに制約チェック表示が未統合の可能性あり（テスト未実装） |

#### 未実装 P0 シナリオ - 統合テスト (1件)

| シナリオID | テスト層 | シナリオ名 | 理由/備考 |
|---|---|---|---|
| TS-I-001 | 統合 | 転職 -> 出産 -> 警告表示の一連フロー | 統合テストは未着手（`integration_test/` ディレクトリ未作成）。MVP段階では統合テストは比率5%のため優先度を下げてよいが、P0の1件は対応が望ましい。 |

#### 未実装 P1 シナリオ (11件)

| シナリオID | テスト層 | シナリオ名 |
|---|---|---|
| TS-D-002 | Data | 複数イベントを保存して全件取得できること |
| TS-D-004 | Data | 存在しないイベントのdeleteが安全に処理されること |
| TS-D-013 | Data | サブカテゴリがnullのJSON変換 |
| TS-D-014 | Data | copyWithでサブカテゴリを変更できること |
| TS-L-003 | Logic | サブカテゴリ付きイベントの削除が成功すること |
| TS-L-014 | Logic | C-01: 転職から1日後に出産の境界値テスト |
| TS-L-033 | Logic | 複数の転職イベントがある場合の直近判定 |
| TS-L-034 | Logic | 複数の出産イベントがある場合の個別制約チェック |
| TS-L-035 | Logic | TimelineEventsProviderがloading状態の場合 |
| TS-L-036 | Logic | TimelineEventsProviderがerror状態の場合 |
| TS-P-013 | Presentation | 種別切替時にサブカテゴリ選択がリセットされること |

#### 未実装 P2 シナリオ (2件)

| シナリオID | テスト層 | シナリオ名 |
|---|---|---|
| TS-P-024 | Presentation | WarningにはWarningアイコンが表示されること |
| TS-P-025 | Presentation | InfoにはInfoアイコンが表示されること |

**補足**: TS-P-024, TS-P-025 はTS-P-020, TS-P-021のテスト内でアイコンのfind検証が含まれているため、実質的にカバーされている。

### 4.3. シナリオカバレッジ サマリ

| 優先度 | 定義数 | 実装済 | 未実装 | カバレッジ |
|---|---|---|---|---|
| P0 | 25 | 10 | 15 | 40% |
| P1 | 20 | 5 | 15 | 25% |
| P2 | 2 | 0 (実質2) | 0 | 100% (実質) |
| **合計** | **47** | **15** | **30** | **36%** |

**重要な注意**: 未実装P0シナリオの大半(12件)は、SOFTWARE_ARCHITECTURE v4.0で定義されたWorkSubCategory/PrivateSubCategoryの2enum分離モデルと、実際の実装（EventCategoryの単一enumモデル）との乖離に起因する。実装が現行のEventCategoryベースである限り、これらのシナリオは対象外となる。

---

## 5. 発見された問題

### Issue-001: SOFTWARE_ARCHITECTURE v4.0 と実装のモデル乖離

- **深刻度**: Major
- **対象**: `lib/features/timeline/domain/life_event.dart` / `docs/SOFTWARE_ARCHITECTURE.md`
- **説明**: SOFTWARE_ARCHITECTURE v4.0 では `WorkSubCategory` と `PrivateSubCategory` の2つの独立したenumを定義し、LifeEventモデルに `workSubCategory: WorkSubCategory?` と `privateSubCategory: PrivateSubCategory?` のフィールドを持たせる設計になっている。しかし、実際の実装では `EventCategory` という単一のenumですべてのカテゴリ（仕事系8種+プライベート系8種）を扱い、`isWork` ゲッターで種別を判定する方式を採用している。
- **影響範囲**:
  - LifeEventモデルのフィールド構成
  - テストシナリオ TS-D-010 ~ TS-D-021, TS-L-001 ~ TS-L-003, TS-P-010 ~ TS-P-013 が実行不可能
  - 制約チェックロジックは `EventCategory.jobChange` / `EventCategory.childbirth` / `EventCategory.maternityLeave` を直接参照する形で正しく動作している
- **対応方針**: 以下のいずれかの対応をArchitectとImplementerで協議して決定すること。
  - (A) 設計ドキュメントを実装に合わせて更新する（EventCategory単一enumモデルを正式採用）
  - (B) 実装を設計に合わせてリファクタリングする（WorkSubCategory/PrivateSubCategory分離モデルへ移行）
- **推奨**: 現行の単一enumモデルは十分に機能しており、テストも全件パスしている。設計ドキュメントの更新 (A) が工数対効果の観点で妥当と考える。

### Issue-002: EventRepository 単体テスト未作成

- **深刻度**: Minor
- **対象**: `test/features/timeline/data/` (空ディレクトリ)
- **説明**: `test/features/timeline/data/` ディレクトリは存在するがテストファイルがない。EventRepositoryのCRUD操作は `timeline_events_provider_test.dart` でモック経由で間接テストされているが、InMemory実装のRepository自体の振る舞い検証（TS-D-001 ~ TS-D-005）が未実施。
- **期待動作**: Repository単体でsave/delete/fetchが正しく動作すること。
- **対応依頼**: Implementerに `test/features/timeline/data/event_repository_test.dart` の作成を依頼する。

### Issue-003: ConstraintResult の freezed コード生成部分のカバレッジが低い

- **深刻度**: Minor
- **対象**: `lib/features/timeline/domain/constraint_result.dart`
- **説明**: カバレッジが28%と低い。これはfreezedが自動生成する `toJson`/`fromJson`/`toString`/`hashCode` 等のメソッドが未テストであるため。手動で書いたロジックはすべてカバーされている。
- **対応方針**: freezed自動生成コードのテストは優先度を下げてよい。必要に応じてTS-D-012（fromJson/toJson往復テスト）の追加を検討する。

### Issue-004: AddEventDialog に制約チェック結果表示が未統合の可能性

- **深刻度**: Major
- **対象**: `lib/features/timeline/presentation/add_event_dialog.dart`
- **説明**: PRD v3.0 セクション4.2「イベント追加ダイアログ」では「制約チェック結果表示エリア」が定義されているが、AddEventDialogのテストに制約チェック結果表示に関するテストケース（TS-P-014, TS-P-015に相当）が存在しない。ダイアログ内での制約警告表示が未実装の可能性がある。
- **対応依頼**: Implementerに実装状況を確認し、未実装であればダイアログ内への ConstraintWarningList 統合を依頼する。

### Issue-005: profile_settings_dialog.dart のテストカバレッジが極めて低い

- **深刻度**: Minor
- **対象**: `lib/features/user_profile/profile_settings_dialog.dart`
- **説明**: カバレッジが2%。プロフィール設定ダイアログのテストがほぼ存在しない。ただし、プロフィール機能はタイムライン機能と比較して優先度が低く、MVPの核心機能ではないため、現時点ではブロッカーとしない。
- **対応方針**: Phase 2の追加タスクとしてプロフィール関連テストの追加をバックログに記録する。

---

## 6. 静的解析 info 詳細

以下のinfo指摘はすべてテストコード内の `prefer_const_constructors` ルールによるもの。

- **対象ファイル**: `test/features/timeline/domain/life_event_test.dart`
- **該当行**: 62, 74, 88, 99, 111, 122, 128, 140, 151, 163, 183, 196, 202行目
- **内容**: LifeEventコンストラクタ呼び出しに `const` キーワードを追加すべきという提案
- **対応優先度**: Low（機能影響なし、パフォーマンス向上のみ）

---

## 7. 推奨事項

### 即時対応 (Implementer向け)

1. **Issue-001 の解決**: ArchitectとImplementerでモデル設計方針を確定する。設計ドキュメントと実装の乖離を解消すること。
2. **Issue-004 の確認**: AddEventDialog内での制約チェック結果表示（PRD v3.0 セクション4.2）の実装状況を確認し、未実装であれば対応する。

### 次回リリースまでに対応

3. **Issue-002**: EventRepository単体テスト（`event_repository_test.dart`）を作成する。
4. **TS-L-014, TS-L-033, TS-L-034**: P1の制約チェック追加テスト（境界値、複数イベント判定）を追加する。
5. **テストコードのconst修正**: `life_event_test.dart` の13箇所にconstを追加する。

### 中長期

6. **統合テスト**: TS-I-001（転職 -> 出産 -> 警告表示の一連フロー）の統合テストを `integration_test/` に作成する。
7. **Presentation層テストの充実**: タイムライン描画ウィジェット（year_month_timeline, year_timeline）のカバレッジ向上。

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|---|---|---|
| 1.0 | 2026-03-10 | 初版作成。Phase 2 実装完了に伴うQA検証結果。 |
