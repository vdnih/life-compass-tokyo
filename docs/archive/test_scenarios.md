# テストシナリオ一覧

**Version**: 1.0
**Last Updated**: 2026-03-09
**Owner**: QA Agent

## 概要

本文書は、ライフプランアプリ（MVP）のテストシナリオを定義する。
SOFTWARE_ARCHITECTURE v4.0 で追加された女性キャリア特化機能（イベントサブカテゴリ、制約チェック）を中心に、
TESTING_POLICY v2.0 のレイヤー別テスト方針に基づいて設計している。

### 参照ドキュメント
- `docs/PRD.md` (Version 3.0)
- `docs/SOFTWARE_ARCHITECTURE.md` (Version 4.0)
- `docs/TESTING_POLICY.md` (Version 2.0)

### 既存テストとの関係
以下の既存テストファイルの内容と重複しないように設計している。
- `test/features/timeline/domain/life_event_test.dart` - EventCategory / EventStatus / LifeEvent 基本テスト
- `test/features/timeline/logic/timeline_events_provider_test.dart` - CRUD基本テスト（追加・削除・エラー）
- `test/features/timeline/presentation/timeline_screen_test.dart` - ビュー切替テスト
- `test/features/timeline/presentation/widgets/add_event_dialog_test.dart` - ダイアログ基本テスト

### 凡例
- P0: 必須（リリースブロッカー）
- P1: 重要（品質基準達成に必要）
- P2: あれば良い（リグレッション防止）

---

## 1. Data層テスト

### 1.1. EventRepository（InMemory）CRUD操作

既存の `timeline_events_provider_test.dart` ではRepositoryをモックしてProvider層をテストしているが、
Repository自体の直接テストは未実施。以下でRepository単体の振る舞いを検証する。

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-D-001 | Data | EventRepository | save後にfetchEventsで取得できること | Repositoryが空 | `saveEvent(event)` を実行後、`fetchEvents()` を呼び出す | 返されたリストに保存したイベントが含まれる | P0 |
| TS-D-002 | Data | EventRepository | 複数イベントを保存して全件取得できること | Repositoryが空 | 3件のイベントを `saveEvent` で保存後、`fetchEvents()` を呼び出す | 3件のイベントすべてが返される | P1 |
| TS-D-003 | Data | EventRepository | deleteEvent後にfetchEventsから除外されること | 1件のイベントが保存済み | `deleteEvent(event)` を実行後、`fetchEvents()` を呼び出す | 返されたリストが空である | P0 |
| TS-D-004 | Data | EventRepository | 存在しないイベントのdeleteが安全に処理されること | Repositoryが空 | 存在しないイベントで `deleteEvent(event)` を実行 | 例外が発生しない、またはドキュメント化された例外が発生する | P1 |
| TS-D-005 | Data | EventRepository | サブカテゴリ付きイベントを保存・取得できること | Repositoryが空 | `workSubCategory: WorkSubCategory.jobChange` を持つイベントを保存後、取得 | サブカテゴリ情報が保持されている | P0 |

### 1.2. LifeEvent モデル（サブカテゴリ拡張）

既存テストは旧モデル（EventCategory）に基づいている。新モデル（WorkSubCategory / PrivateSubCategory）への移行後に必要となるテスト。

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-D-010 | Data | LifeEvent | WorkSubCategory付きイベントが正しく生成されること | なし | `LifeEvent(type: EventType.work, workSubCategory: WorkSubCategory.jobChange, ...)` を生成 | workSubCategoryがjobChange、privateSubCategoryがnull | P0 |
| TS-D-011 | Data | LifeEvent | PrivateSubCategory付きイベントが正しく生成されること | なし | `LifeEvent(type: EventType.private, privateSubCategory: PrivateSubCategory.childbirth, ...)` を生成 | privateSubCategoryがchildbirth、workSubCategoryがnull | P0 |
| TS-D-012 | Data | LifeEvent | fromJson/toJsonでサブカテゴリが正しく変換されること | なし | サブカテゴリ付きLifeEventの `toJson()` 結果を `fromJson()` に渡す | 元のオブジェクトと等しい | P0 |
| TS-D-013 | Data | LifeEvent | サブカテゴリがnullのJSON変換が正しく動作すること | なし | サブカテゴリなしLifeEventの `toJson()` 結果を `fromJson()` に渡す | workSubCategory / privateSubCategory がともにnull | P1 |
| TS-D-014 | Data | LifeEvent | copyWithでサブカテゴリを変更できること | WorkSubCategory.jobChangeのイベントが存在 | `event.copyWith(workSubCategory: WorkSubCategory.promotion)` を実行 | workSubCategoryがpromotionに変更され、他のフィールドは維持 | P1 |

### 1.3. EventSubCategory enum

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-D-020 | Data | WorkSubCategory | 全8種のサブカテゴリが定義されていること | なし | `WorkSubCategory.values` を確認 | jobChange, promotion, maternityLeave, childcareLeave, returnToWork, retirement, goal, other の8値 | P0 |
| TS-D-021 | Data | PrivateSubCategory | 全5種のサブカテゴリが定義されていること | なし | `PrivateSubCategory.values` を確認 | marriage, childbirth, childcare, nursingCare, other の5値 | P0 |

### 1.4. ConstraintResult モデル

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-D-030 | Data | ConstraintResult | Warning種別の制約結果が正しく生成されること | なし | `ConstraintResult(ruleId: 'C-01', severity: ConstraintSeverity.warning, ...)` を生成 | severityがwarning、ruleIdが'C-01' | P0 |
| TS-D-031 | Data | ConstraintResult | Info種別の制約結果が正しく生成されること | なし | `ConstraintResult(ruleId: 'C-02', severity: ConstraintSeverity.info, ...)` を生成 | severityがinfo、ruleIdが'C-02' | P0 |
| TS-D-032 | Data | ConstraintResult | 同一内容の2つのConstraintResultが等しいこと | なし | 同じパラメータで2つのConstraintResultを生成 | `==` がtrueを返す（freezedの値等価性） | P1 |
| TS-D-033 | Data | ConstraintSeverity | warningとinfoの2値が定義されていること | なし | `ConstraintSeverity.values` を確認 | warning, info の2値 | P1 |

---

## 2. Logic層テスト【最重要】

### 2.1. TimelineEventsProvider 拡張テスト

既存テストは旧モデル（EventCategory）でのCRUDをカバー済み。
新モデルへの移行後に、サブカテゴリ付きイベントでの動作を検証する。

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-L-001 | Logic | TimelineEventsProvider | WorkSubCategory付きイベントの追加が成功すること | 初期データ0件 | `addEvent(LifeEvent(workSubCategory: WorkSubCategory.jobChange, ...))` | AsyncDataに遷移し、サブカテゴリ付きイベントが含まれる | P0 |
| TS-L-002 | Logic | TimelineEventsProvider | PrivateSubCategory付きイベントの追加が成功すること | 初期データ0件 | `addEvent(LifeEvent(privateSubCategory: PrivateSubCategory.childbirth, ...))` | AsyncDataに遷移し、サブカテゴリ付きイベントが含まれる | P0 |
| TS-L-003 | Logic | TimelineEventsProvider | サブカテゴリ付きイベントの削除が成功すること | サブカテゴリ付きイベント1件 | `deleteEvent(event)` | AsyncDataに遷移し、リストが空 | P1 |

### 2.2. ConstraintCheckerProvider テスト（新規・最重要）

PRD v3.0 セクション5「制約チェックルール定義」に基づく。
純粋関数Providerとして実装されるため、モック不要で入出力のみをテストできる。

#### C-01: 転職から1年未満に出産/産休 -> Warning

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-L-010 | Logic | ConstraintCheckerProvider | C-01: 転職から6ヶ月後に出産イベント -> Warning | なし | 転職(2025-01) + 出産(2025-07) のイベント一覧 | ruleId='C-01', severity=warning の ConstraintResult が1件含まれる | P0 |
| TS-L-011 | Logic | ConstraintCheckerProvider | C-01: 転職から11ヶ月後に産休イベント -> Warning | なし | 転職(2025-01) + 産休(2025-12) のイベント一覧 | ruleId='C-01', severity=warning の ConstraintResult が1件含まれる | P0 |
| TS-L-012 | Logic | ConstraintCheckerProvider | C-01: 転職から1年以上後に出産イベント -> 警告なし | なし | 転職(2025-01) + 出産(2026-02) のイベント一覧 | ruleId='C-01' の ConstraintResult が含まれない | P0 |
| TS-L-013 | Logic | ConstraintCheckerProvider | C-01: 転職からちょうど12ヶ月後に出産 -> 警告なし（境界値） | なし | 転職(2025-01) + 出産(2026-01) のイベント一覧 | ruleId='C-01' の ConstraintResult が含まれない（1年「未満」が条件のため） | P0 |
| TS-L-014 | Logic | ConstraintCheckerProvider | C-01: 転職から1日後に出産 -> Warning（境界値・最小間隔） | なし | 転職(2025-01) + 出産(2025-02) のイベント一覧 | ruleId='C-01', severity=warning の ConstraintResult が含まれる | P1 |
| TS-L-015 | Logic | ConstraintCheckerProvider | C-01: 出産が転職より前の場合 -> 警告なし | なし | 出産(2024-06) + 転職(2025-01) のイベント一覧 | ruleId='C-01' の ConstraintResult が含まれない | P1 |

#### C-02: 出産予定があるが1年以上前に転職なし -> Info

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-L-020 | Logic | ConstraintCheckerProvider | C-02: 出産イベントのみ（転職なし） -> Info | なし | 出産(2026-06) のみのイベント一覧 | ruleId='C-02', severity=info の ConstraintResult が1件含まれる | P0 |
| TS-L-021 | Logic | ConstraintCheckerProvider | C-02: 出産の6ヶ月前に転職（1年未満） -> Info | なし | 転職(2026-01) + 出産(2026-06) のイベント一覧 | ruleId='C-02', severity=info の ConstraintResult が含まれる（1年以上前の転職がないため） | P0 |
| TS-L-022 | Logic | ConstraintCheckerProvider | C-02: 出産の1年以上前に転職あり -> 情報なし | なし | 転職(2025-01) + 出産(2026-06) のイベント一覧 | ruleId='C-02' の ConstraintResult が含まれない | P0 |
| TS-L-023 | Logic | ConstraintCheckerProvider | C-02: 出産のちょうど12ヶ月前に転職（境界値） -> 情報なし | なし | 転職(2025-06) + 出産(2026-06) のイベント一覧 | ruleId='C-02' の ConstraintResult が含まれない（1年「以上」前が条件のため） | P0 |

#### 複合・エッジケース

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-L-030 | Logic | ConstraintCheckerProvider | イベントが空の場合 -> 空リスト | なし | 空のイベント一覧 | 空のList<ConstraintResult>が返される | P0 |
| TS-L-031 | Logic | ConstraintCheckerProvider | 制約に該当しないイベントのみ -> 空リスト | なし | 結婚(2025-01) + 昇進(2025-06) のイベント一覧 | 空のList<ConstraintResult>が返される | P1 |
| TS-L-032 | Logic | ConstraintCheckerProvider | C-01とC-02が同時に発生する場合 | なし | 転職(2026-01) + 出産(2026-06) のイベント一覧（転職は1年未満かつ、1年以上前の転職がない） | ruleId='C-01'(warning) と ruleId='C-02'(info) の両方が含まれる | P0 |
| TS-L-033 | Logic | ConstraintCheckerProvider | 複数の転職イベントがある場合、直近の転職で判定すること | なし | 転職A(2024-01) + 転職B(2026-01) + 出産(2026-06) のイベント一覧 | 転職B(2026-01)からの間隔で判定される（C-01がwarning） | P1 |
| TS-L-034 | Logic | ConstraintCheckerProvider | 複数の出産イベントがある場合、それぞれに制約チェックが適用されること | なし | 転職(2025-01) + 出産A(2025-06) + 出産B(2026-06) のイベント一覧 | 出産AにはC-01のwarning、出産Bには警告なし（1年以上経過） | P1 |
| TS-L-035 | Logic | ConstraintCheckerProvider | TimelineEventsProviderがloading状態の場合 -> 空リスト | TimelineEventsProviderが未初期化 | constraintCheckerProviderをwatch | 空のList<ConstraintResult>が返される | P1 |
| TS-L-036 | Logic | ConstraintCheckerProvider | TimelineEventsProviderがerror状態の場合 -> 空リスト | TimelineEventsProviderがエラー状態 | constraintCheckerProviderをwatch | 空のList<ConstraintResult>が返される | P1 |
| TS-L-037 | Logic | ConstraintCheckerProvider | 産休イベント(WorkSubCategory.maternityLeave)でもC-01が発火すること | なし | 転職(2025-01) + 産休(2025-08) のイベント一覧 | ruleId='C-01', severity=warning の ConstraintResult が含まれる | P0 |

---

## 3. Presentation層テスト

### 3.1. タイムライン画面 サブカテゴリ関連

既存テストはビュー切替（年/年月）をカバー済み。サブカテゴリ表示と制約警告表示を追加検証。

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-P-001 | Presentation | TimelineScreen | サブカテゴリ付きイベントがタイムラインに表示されること | WorkSubCategory.jobChangeのイベント1件をStub | 画面を表示 | イベントカードが表示され、サブカテゴリに応じたアイコン/色が適用されている | P1 |
| TS-P-002 | Presentation | TimelineScreen | 仕事イベントが上段レーン、プライベートイベントが下段レーンに表示されること | 仕事1件 + プライベート1件をStub | 画面を表示 | 各イベントが正しいレーンに配置されている | P1 |
| TS-P-003 | Presentation | TimelineScreen | 制約違反のあるイベントカードに警告アイコンが表示されること | C-01に該当するイベント構成をStub | 画面を表示 | 該当イベントカードに警告アイコンが表示される | P1 |

### 3.2. イベント追加ダイアログ サブカテゴリ選択

既存テストは仕事/プライベートの切替とカテゴリ表示をカバー済み。
新モデルのサブカテゴリ選択UIを検証する。

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-P-010 | Presentation | AddEventDialog | 仕事選択時にWorkSubCategoryの選択肢が表示されること | ダイアログを開く | 仕事（デフォルト）を選択 | 入社・転職、昇進・昇格、産休取得、育休取得、復職、退職、目標、その他 の選択肢が表示される | P0 |
| TS-P-011 | Presentation | AddEventDialog | プライベート選択時にPrivateSubCategoryの選択肢が表示されること | ダイアログを開く | プライベートを選択 | 結婚、妊娠・出産、育児、介護、その他 の選択肢が表示される | P0 |
| TS-P-012 | Presentation | AddEventDialog | サブカテゴリを選択してイベントを追加できること | ダイアログを開く | 仕事 > 入社・転職 を選択し、タイトル入力後に追加 | ダイアログが閉じ、WorkSubCategory.jobChangeのイベントが追加される | P0 |
| TS-P-013 | Presentation | AddEventDialog | 種別切替時にサブカテゴリ選択がリセットされること | ダイアログを開く | 仕事 > 産休取得 を選択後、プライベートに切替 | WorkSubCategoryの選択肢が消え、PrivateSubCategoryの選択肢が表示される | P1 |
| TS-P-014 | Presentation | AddEventDialog | 制約チェック結果がダイアログ内に表示されること | C-01に該当するイベント構成が既に存在 | 出産イベントを追加しようとする | 警告メッセージ「転職から1年未満のため...」がダイアログ内に表示される | P0 |
| TS-P-015 | Presentation | AddEventDialog | 警告があっても追加ボタンで保存できること（非ブロッキング） | C-01の警告が表示されている状態 | 追加ボタンをタップ | イベントが追加され、ダイアログが閉じる | P0 |

### 3.3. 制約警告ウィジェット (constraint_warning.dart)

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-P-020 | Presentation | ConstraintWarning | Warning種別の制約が正しく表示されること | severity=warningのConstraintResult | ウィジェットを描画 | Amber系の背景色で警告メッセージが表示される | P0 |
| TS-P-021 | Presentation | ConstraintWarning | Info種別の制約が正しく表示されること | severity=infoのConstraintResult | ウィジェットを描画 | Light Blue系の背景色で情報メッセージが表示される | P0 |
| TS-P-022 | Presentation | ConstraintWarning | 制約結果が空の場合、ウィジェットが非表示であること | 空のList<ConstraintResult> | ウィジェットを描画 | 何も表示されない（SizedBox.shrink等） | P0 |
| TS-P-023 | Presentation | ConstraintWarning | 複数の制約結果がある場合、すべて表示されること | warning1件 + info1件のConstraintResult | ウィジェットを描画 | 2件のメッセージがそれぞれ適切な色で表示される | P1 |
| TS-P-024 | Presentation | ConstraintWarning | WarningにはWarningアイコンが表示されること | severity=warningのConstraintResult | ウィジェットを描画 | Icons.warning または類似の警告アイコンが表示される | P2 |
| TS-P-025 | Presentation | ConstraintWarning | InfoにはInfoアイコンが表示されること | severity=infoのConstraintResult | ウィジェットを描画 | Icons.info または類似の情報アイコンが表示される | P2 |

---

## 4. 統合テスト（シナリオ）

### 4.1. 女性キャリアプランニング E2Eシナリオ

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-I-001 | 統合 | タイムライン全体 | 転職 -> 出産（1年未満）-> 警告表示の一連フロー | アプリ起動、イベント0件 | (1) FABタップ (2) 仕事 > 入社・転職 を選択、タイトル入力、開始年月を2025-01に設定、追加 (3) FABタップ (4) プライベート > 妊娠・出産 を選択、タイトル入力、開始年月を2025-08に設定 (5) 制約チェック結果を確認 (6) 追加 | (5)でC-01の警告メッセージがダイアログ内に表示される。(6)で追加後、タイムライン上に2件のイベントが表示され、出産イベントに警告アイコンが付与される | P0 |
| TS-I-002 | 統合 | タイムライン全体 | 出産のみ登録 -> 転職推奨情報の表示 | アプリ起動、イベント0件 | (1) FABタップ (2) プライベート > 妊娠・出産 を選択、タイトル入力、開始年月を2026-06に設定 (3) 制約チェック結果を確認 (4) 追加 | (3)でC-02の情報メッセージがダイアログ内に表示される。(4)で追加後、タイムライン上にイベントが表示される | P1 |
| TS-I-003 | 統合 | タイムライン全体 | 転職 -> 出産（1年以上後）-> 警告なしの確認 | アプリ起動、イベント0件 | (1) 転職(2025-01)を追加 (2) 出産(2026-06)を追加しようとする (3) 制約チェック結果を確認 | (3)でC-01の警告が表示されないことを確認 | P1 |
| TS-I-004 | 統合 | タイムライン全体 | イベント削除後に制約警告が消えること | 転職(2025-01) + 出産(2025-08) が登録済み | (1) 転職イベントを削除 (2) タイムラインを確認 | 出産イベントからC-01の警告アイコンが消える（転職イベントが存在しないため、C-01は非該当。C-02のInfoに変わる可能性あり） | P1 |

---

## 5. テストシナリオ サマリ

| テスト層 | P0 | P1 | P2 | 合計 |
|---|---|---|---|---|
| Data層 | 7 | 5 | 0 | 12 |
| Logic層 | 11 | 8 | 0 | 19 |
| Presentation層 | 6 | 4 | 2 | 12 |
| 統合テスト | 1 | 3 | 0 | 4 |
| **合計** | **25** | **20** | **2** | **47** |

テストピラミッドの比率: Data+Logic(66%) / Presentation(26%) / 統合(8%)
TESTING_POLICY v2.0 の目安（70% / 25% / 5%）にほぼ合致している。

---

---

## 6. Phase 2: 目標逆算機能テスト

### 参照ドキュメント
- `docs/PRD.md` (Version 4.0)
- `docs/SOFTWARE_ARCHITECTURE.md` (Version 5.0)

### 6.1. EventDependency モデルテスト

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-DEP-001 | Data | EventDependency | 依存関係モデルが正しく生成されること | なし | `EventDependency(type: DependencyType.prerequisite, offsetMonths: -12, ...)` を生成 | 全フィールドが正しく設定される | P0 |
| TS-DEP-002 | Data | EventDependency | 全4種のDependencyTypeが定義されていること | なし | `DependencyType.values` を確認 | prerequisite, consequence, deadline, companion の4値 | P0 |
| TS-DEP-003 | Data | EventDependency | copyWithで依存関係を変更できること | prerequisiteの依存関係が存在 | `dep.copyWith(type: DependencyType.deadline)` を実行 | typeが変更され、他フィールドは維持 | P1 |

### 6.2. DependencyRepository テスト

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-DEP-010 | Data | DependencyRepository | 依存関係の保存・取得ができること | Repositoryが空 | `saveDependency(dep)` → `fetchDependencies()` | 保存した依存関係が含まれる | P0 |
| TS-DEP-011 | Data | DependencyRepository | 依存関係の削除ができること | 1件の依存関係が保存済み | `deleteDependency(dep)` → `fetchDependencies()` | リストが空 | P0 |
| TS-DEP-012 | Data | DependencyRepository | イベントIDで関連する依存関係を取得できること | 複数の依存関係が保存済み | `fetchDependenciesForEvent(eventId)` | 指定イベントに関連する依存関係のみ返される | P0 |

### 6.3. DependencyProvider テスト

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-DEP-020 | Logic | DependencyProvider | 依存関係の追加が成功すること | 初期データ0件 | `addDependency(dep)` | 依存関係がリストに追加される | P0 |
| TS-DEP-021 | Logic | DependencyProvider | 循環依存が検出されること | A→Bの依存関係が存在 | `wouldCreateCycle('B', 'A')` | trueが返される | P0 |
| TS-DEP-022 | Logic | DependencyProvider | 間接的な循環依存が検出されること | A→B、B→Cの依存関係が存在 | `wouldCreateCycle('C', 'A')` | trueが返される | P0 |
| TS-DEP-023 | Logic | DependencyProvider | 循環でない依存関係が許可されること | A→Bの依存関係が存在 | `wouldCreateCycle('A', 'C')` | falseが返される | P1 |
| TS-DEP-024 | Logic | DependencyProvider | イベント削除時に関連依存関係も削除されること | A→B、A→Cの依存関係が存在 | `removeDependenciesForEvent('A')` | A関連の依存関係がすべて削除される | P0 |

### 6.4. GoalTemplate テスト

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-TMPL-001 | Data | GoalTemplate | 出産テンプレートが正しく定義されていること | なし | テンプレートレジストリから出産テンプレートを取得 | 7件の関連イベントが定義されている | P0 |
| TS-TMPL-002 | Logic | GoalTemplateProvider | 出産テンプレート適用で正しいイベント群が生成されること | なし | `applyTemplate(childbirth, '2028-06')` | 妊活(-12m)、転職リミット(-12m)、旅行リミット(-4m)、産休(-2m)、出産(0m)、育休(0~+12m)、復職(+12m) が生成 | P0 |
| TS-TMPL-003 | Logic | GoalTemplateProvider | テンプレート生成イベントの日付が正しく逆算されること | なし | `applyTemplate(childbirth, '2028-06')` | 妊活=2027-06、転職リミット=2027-06、旅行リミット=2028-02、産休=2028-04 | P0 |
| TS-TMPL-004 | Logic | GoalTemplateProvider | テンプレート生成時に依存関係も正しく生成されること | なし | `applyTemplate(childbirth, '2028-06')` | 生成イベント間の依存関係が正しいタイプとオフセットで生成される | P0 |
| TS-TMPL-005 | Logic | GoalTemplateProvider | 年を跨ぐオフセット計算が正しいこと | なし | `applyTemplate(childbirth, '2028-01')` | 妊活=2027-01（12ヶ月前）が正しく計算される | P1 |

### 6.5. CascadeMoveProvider テスト

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-MOVE-001 | Logic | CascadeMoveProvider | 単一依存イベントが連動移動すること | A→B（offset: +6m）が存在 | Aを3ヶ月後に移動 | Bも3ヶ月後に移動する | P0 |
| TS-MOVE-002 | Logic | CascadeMoveProvider | チェーン依存（A→B→C）で全て連動移動すること | A→B（+6m）、B→C（+3m）が存在 | Aを2ヶ月後に移動 | B, Cもそれぞれ2ヶ月後に移動する | P0 |
| TS-MOVE-003 | Logic | CascadeMoveProvider | 依存関係のないイベントは移動しないこと | A→B（+6m）、C（独立）が存在 | Aを3ヶ月後に移動 | Bは移動するがCは移動しない | P0 |
| TS-MOVE-004 | Logic | CascadeMoveProvider | 移動後に制約チェックが再実行されること | A→B（+6m）が存在、C-01該当条件 | Aを移動してC-01条件を満たす位置に配置 | C-01の警告が生成される | P0 |
| TS-MOVE-005 | Logic | CascadeMoveProvider | 逆方向移動（過去へ）でも連動すること | A→B（+6m）が存在 | Aを3ヶ月前に移動 | Bも3ヶ月前に移動する | P1 |
| TS-MOVE-006 | Logic | CascadeMoveProvider | 0ヶ月移動では何も変わらないこと | A→B（+6m）が存在 | Aを同じ日付に移動 | 空の変更リストが返される | P1 |

### 6.6. ConstraintChecker C-03 テスト

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-C03-001 | Logic | ConstraintChecker | C-03: 依存オフセット違反を検出すること | A→B（offset: -12m）が存在、実際の間隔が6ヶ月 | 制約チェック実行 | ruleId='C-03', severity=warning | P0 |
| TS-C03-002 | Logic | ConstraintChecker | C-03: オフセットが満たされている場合は警告なし | A→B（offset: -12m）が存在、実際の間隔が12ヶ月以上 | 制約チェック実行 | C-03の結果が含まれない | P0 |
| TS-C03-003 | Logic | ConstraintChecker | C-03: 前提イベントが結果イベントの後にある場合を検出 | A(prerequisite)→B、AがBより後 | 制約チェック実行 | ruleId='C-03', severity=warning | P0 |

### 6.7. Presentation層テスト（Phase 2）

| ID | テスト層 | テスト対象 | シナリオ名 | 前提条件 | 操作/入力 | 期待結果 | 優先度 |
|---|---|---|---|---|---|---|---|
| TS-P2-001 | Presentation | GoalSetupDialog | テンプレート一覧が表示されること | ダイアログを開く | - | 出産テンプレートが選択肢として表示される | P0 |
| TS-P2-002 | Presentation | GoalSetupDialog | ゴール日設定後にプレビューが表示されること | テンプレート選択済み | ゴール日を2028-06に設定 | 7件の関連イベントがプレビュー表示される | P0 |
| TS-P2-003 | Presentation | GoalSetupDialog | 適用ボタンでイベントがタイムラインに追加されること | プレビュー表示済み | 適用ボタンタップ | ダイアログが閉じ、タイムラインに関連イベント群が表示される | P0 |
| TS-P2-004 | Presentation | DependencyConnector | 依存関係線が正しく描画されること | 依存関係を持つイベント2件をStub | 画面を表示 | 2つのイベント間にコネクタ線が表示される | P1 |
| TS-P2-005 | Presentation | DraggableEventCard | 長押しでドラッグが開始されること | イベントカードを表示 | 長押し操作 | ドラッグフィードバックが表示される | P1 |
| TS-P2-006 | Presentation | DraggableEventCard | ドロップでイベント日付が更新されること | ドラッグ中 | 新しい位置にドロップ | イベントの日付が更新され、連動イベントも移動する | P1 |

---

## 7. テストシナリオ サマリ（Phase 1 + Phase 2）

| テスト層 | P0 | P1 | P2 | 合計 |
|---|---|---|---|---|
| Data層（Phase 1） | 7 | 5 | 0 | 12 |
| Logic層（Phase 1） | 11 | 8 | 0 | 19 |
| Presentation層（Phase 1） | 6 | 4 | 2 | 12 |
| 統合テスト（Phase 1） | 1 | 3 | 0 | 4 |
| Data層（Phase 2） | 5 | 2 | 0 | 7 |
| Logic層（Phase 2） | 14 | 4 | 0 | 18 |
| Presentation層（Phase 2） | 3 | 3 | 0 | 6 |
| **合計** | **47** | **29** | **2** | **78** |

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|---|---|---|
| 1.0 | 2026-03-09 | 初版作成。SOFTWARE_ARCHITECTURE v4.0 の女性キャリア特化機能（サブカテゴリ、制約チェック）に対応するテストシナリオを設計。既存テスト4ファイルとの重複を排除。 |
| 2.0 | 2026-03-26 | Phase 2（目標逆算機能）のテストシナリオを追加。EventDependency、DependencyProvider、GoalTemplate、CascadeMoveProvider、C-03制約、ゴール設定UI、D&Dのテストを設計。Phase 2で31シナリオ追加（P0: 22件、P1: 9件）。 |
