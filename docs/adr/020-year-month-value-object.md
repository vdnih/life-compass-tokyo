# ADR-020: yyyy-MM の値オブジェクト YearMonth を導入する

**Date**: 2026-07-26
**Status**: Accepted

## 背景

`LifeEvent.date` / `endDate`（`yyyy-MM` 形式の文字列）に対する月加算アルゴリズムが
4 重に実装されていた（関数名以外バイト同一）:

- `logic/cascade_move_provider.dart` の `_addMonths` / `_dateToMonths`
- `logic/timeline_events_provider.dart` の `_addMonths`
- `logic/goal_template_provider.dart` の `addMonthsToDate`（public。presentation 層の
  `goal_setup_dialog.dart` から直接 import されており、logic の内部実装が presentation から
  参照される形になっていた）
- `logic/constraint_checker_provider.dart` の C-03 チェック内にインライン展開

加えて月インデックスへの逆変換（`year_month_timeline.dart` の依存オフセット編集）は
これらとは別の実装で、`%12==0` の補正が必要な 1-based 絶対値という非対称な形だった。
`.split('-')` によるパースは lib 全体で 23 箇所に散らばっていた。

この分散状態は、2 実装（`year_timeline.dart` / `year_month_timeline.dart`）の統合を
テストで安全に進める前提を欠いている。カスケード移動や制約判定（C-01/C-02/C-03）の
算術を 1 箇所に集約し、テストで固定してから統合作業に入る必要があった。

## 決定

### 1. `YearMonth` を `lib/features/timeline/domain/year_month.dart` に置く

現在の消費者は `features/timeline/` の `domain/` `logic/` `presentation/` のみ。
`catalog` は `offsetMonthsFromGoal` / `durationMonths` を素の `int` で持つだけで `yyyy-MM` を
扱わず、`user_profile` は `yyyy-MM-dd` という別フォーマット、`core/widgets/year_month_picker.dart`
は `DateTime` / `int` のみで文字列パースをしない。`lib/core/` にドメインモデルは 1 つも無いため、
1 クラスのためだけに `core/domain/` を新設しなかった。

**2 つ目の feature が参照するようになったら `lib/core/` への移動を検討する**
（dartdoc にも明記）。 → #46

### 2. 永続化フィールドはこの型に置き換えない

**`LifeEvent.date` / `endDate` は `String` のまま残す。`YearMonth` は計算・比較用の型であり、
永続化の型ではない。** 境界は `LifeEvent.yearMonth` / `endYearMonth` getter と
`toJson` / `fromJson` の2箇所だけに限定する。

これが最も重要な決定である。書いておかないと、将来「仕上げ」として `date` フィールド自体の
型を変える変更が入りかねず、それは既存の Firestore ドキュメント全件のスキーマを破壊する。

### 3. `parse` は strict にする。`tryParse` は入れない

月は 2 桁ゼロ埋め必須（`'2025-3'` は reject し、正規化しない）。理由:

- lib 内の生成側は全て `padLeft(2, '0')` を通しており、非パディングの入力は実際には発生しない
- `goal_setup_dialog.dart` の日付ソート（`events.sort((a, b) => a.date.compareTo(b.date))`
  相当）が固定幅の文字列比較に依存しており、非パディングを許すと静かに壊れる
- 現状も `'2024'` は `RangeError`、`'abc-01'` は `FormatException` で既に例外になっており、
  `FormatException` に統一するのは純粋な改善

`tryParse` は呼び出し元が存在しないため入れなかった。`fromJson` での利用も検討したが、
壊れた 1 件のために `fetchEvents` 全体が失敗するのは現状（`dateTime` 参照時まで遅延する）より
悪化するため見送った。必要になった時点で追加する。

### 4. 月インデックス（`monthIndex` / `fromMonthIndex`）は公開しない

現存する全ての月インデックス利用は「差分」（`differenceInMonths`）か「加算」（`addMonths`）
であり、1-based の絶対値を外部に見せる必要がない。これにより
`year_month_timeline.dart` にあった `%12==0` の補正コードが API から消滅した。

### 5. PR 2 では `.split('-')` の一部（15箇所）を移行しない

`year_timeline.dart` / `year_month_timeline.dart` は座標変換のロジックを含み、次の PR で
`TimelineAxis`（または `TimelineScale`。ADR-016 参照）として書き直され、テストが付く予定。
このコミットでは **コンパイラが型変更で強制する編集のみ**（`LifeEvent.dateTime` /
`endDateTime` の getter 名変更に伴う 13 箇所）を行い、`.split('-')` そのものを使う 15 箇所
（座標計算・プレビュー状態・依存オフセット編集）は次の PR に送った。

理由: `.dateTime` の呼び出しは型が変わるため全箇所がビルドエラーとして検出され漏らせないが、
`.split('-')` は型が変わらないため間違えてもコンパイルが通り、しかもテストが無い状態で
2 ファイルに意味的な書き換えを入れることになる。それを次の PR で TimelineAxis の
ユニットテスト付きで書き直す方が検証が厚い。 → #35

## このコミットのコード量について

`YearMonth` の導入は dartdoc を含めて約120行の追加で、置き換えた重複コードは約90行。
**行数では相殺しない。** 買ったのは「同一アルゴリズム5実装 → 1」と「このアルゴリズムに対する
テスト 0 → 16」の2点であり、行数の削減はこの変更の目的ではない。行数削減は
2 実装統合（`year_timeline.dart` / `year_month_timeline.dart` の共通化）で回収する計画であり、
本変更はその前提として日付計算の型を揃えるために行った。

## 未解決として記録する事項

### `authStateProvider` は `AsyncLoading` から始まる

`valueOrNull == null` が「未認証」と「まだ解決していない」の両方を意味するため、
ログイン済みユーザーも初回フレームだけゲスト（サンプルデータ）扱いになる。修正には
`TimelineEventsNotifier.build()` で `authStateProvider.future` を待つ必要があるが、
現状 authState を override していない大半のテストファイルが
`MobileAuthRepository` → `FirebaseAuth.instance` に到達して失敗するため、影響範囲の調査を
含めて別 PR（Repository Provider を `logic/` に移す PR）で対処する。症状もデータ損失ではなく
「一瞬サンプルが見える＋余分な fetch 1 回」であり、本 PR の2つのバグ修正
（ゲストの削除失敗・ゲストの編集消失）とは性質が異なる。 → #39

### `core/util/sentinel.dart` への共通化は見送った

現時点の消費者は `LifeEvent.copyWith` の1箇所のみ。2個目の消費者
（`UserProfile.copyWith` の `birthDate` クリア）が現れる PR で共通化する。
1 消費者のうちに共通化すると、命名（`sentinel` / `kSentinel` / `Sentinel.instance`）や
public API としての露出形態を決着させる材料が乏しい。 → #46（`YearMonth` の `core/` 移動・
`tryParse` の見送りとあわせて記録）

以降の残課題は本節を追記せず GitHub Issue で管理する（CLAUDE.md §6）。

## 検討したが採らなかった案

- **`applyTemplate` のシグネチャを `YearMonth goalDate` に変更する**: `goal_template_provider.dart`
  の内部では `YearMonth` を使うが、公開シグネチャは `String goalDate` のまま残した。変更すると
  `goal_template_provider_test.dart` の全ケースを機械的に書き換えることになり、このタイミングでは
  得るものがないため。
- **`monthIndex` を公開する**: 呼び出し元が存在しないため見送った（§4 参照）。

## 影響範囲

- `lib/features/timeline/domain/year_month.dart`: 新設
- `lib/features/timeline/domain/life_event.dart`: `dateTime` / `endDateTime` getter を
  `yearMonth` / `endYearMonth` に置き換え（`toJson` / `fromJson` は無変更）
- `lib/features/timeline/logic/*.dart`: 4 重の月加算実装を削除し `YearMonth` に統合
- `lib/features/timeline/presentation/{add_event,edit_event,goal_setup}_dialog.dart`:
  状態フィールドを `YearMonth` に変更、`'yyyy年M月'` 表示を `japaneseLabel` に統一
- `lib/features/timeline/presentation/widgets/{year_timeline,year_month_timeline}.dart`:
  型変更で強制される 13 箇所のみ機械的に置換（`.split('-')` 自体は次の PR で移行）
- `CLAUDE.md` §4: `YearMonth` の存在と注意点を追記

## 関連

- ADR-016（予定）: 2 実装統合の方針。年ビューは `TimelineAxis` ではなく
  フィールド2本の値クラス（`TimelineScale`）で表現する
- CLAUDE.md §4「実装上の注意」
