# ADR-021: 年ビュー・月ビューの2実装を1つの TimelineView に統合する

**Date**: 2026-08-01
**Status**: Accepted

## 背景

`year_timeline.dart`（年ビュー、1514行）と `year_month_timeline.dart`（月ビュー、1742行）は
ほぼ重複した2実装で、CLAUDE.md §4 が「リファクタリングの筆頭課題」と明記していた。D&D 周りの
修正は原則両方に入れる必要があり、過去にこの2ファイル間でコンフリクトが発生していた
（#1 として起票、#34 に整理）。

ADR-020（`YearMonth` 導入）と #35（`TimelineScale` 切り出し）で、両ファイルの座標変換を
`origin` / `pixelsPerSlot` / `monthsPerSlot` の3フィールドに正規化した。その結果、
両ファイルを実際に読み比べると、座標変換以外の大半のメソッドも byte 単位で完全に同一
であることが確認できた（`_computeStackIndices` / `_buildDropPreview` / `_buildDropTarget` /
`_buildEventCards` / `_showEventDetails` など、実質16メソッド）。#36（同一ヘルパーの共通化）は
当初 #34 とは別 PR に分離される想定だったが、読み比べた結果2つの Issue は実質同じ作業であり、
分けると中途半端な重複が残ると判断した。

このリファクタリングの目的はプロダクトピボット（PDR-006, #47）前に肥大化したコードを
整理することであり、機能追加や仕様確定はピボットで無駄になりうるため行わない方針とした。

## 決定

### 1. 2ファイルを `TimelineView`（`presentation/widgets/timeline_view.dart`）に統合する

表示単位の違いは `TimelineViewMode` enum（`yearMonth` / `year`）のフィールドとして表現する:
`pixelsPerSlot` / `monthsPerSlot` / `defaultBackSlots` / `defaultForwardSlots` /
`eventBackPadSlots` / `eventForwardPadSlots` / `heroTag` / `scrollTooltip`。

表示範囲の計算（従来は年単位・月単位で別々に書かれていた `build()` 冒頭のロジック）は、
「現在時刻をこのビューのスロット境界に正規化する」`TimelineViewMode.anchorOf()` を軸に
1つのアルゴリズムへ統合した。年ビューは常に1月境界に丸める（従来の非対称性はそのまま
保持。ADR-020 §5 で触れた「年ビューは1月にスナップする」性質に変更はない）。

グリッド線・軸ラベルの「1月だけを濃く/大きく表示する」判定（旧 `isJan`）も月ビュー側の
実装をそのまま両ビュー共通にした。年ビューの `TimelineScale` は `monthsPerSlot: 12` かつ
`origin` が常に1月始まりのため、`scale.dateAtSlot(i).month == 1` は年ビューでは常に true に
なり、判定を共通化しても年ビューの見た目（全スロットが一律の濃さ、年+年齢のみの表示）は
変わらない。

### 2. 純粋関数を `domain/` に切り出す

- `event_stacking.dart`: `computeStackIndices` / `computeStackedRowHeight`
  （イベントの段積みロジック）
- `catalog_placement_check.dart`: `checkCatalogPlacement`
  （カタログドロップ時の hard/soft 先行ルール判定。`Color` は返さず
  `CatalogPlacementSeverity` を返す。domain 層に Flutter の色を持ち込まないため、
  色への対応づけは呼び出し側の presentation で行う）

### 3. 表示部品を分割する（#38 の実体をあわせて解消）

統合直後の `timeline_view.dart` が約1350行になったため、状態を持たない純粋な描画部分を
移動のみで分割した:

- `timeline_lane_labels.dart`: 仕事・プライベートのレーンラベル
- `timeline_axis.dart`: グリッド線・現在マーカー・軸ラベル
- `catalog_drop_preview.dart`: カタログドロップ時のプレビューゴーストカード
- `event_detail_dialog.dart`: イベント詳細ダイアログ（制約タイル・依存タイル・削除確認込み）

残る `timeline_view.dart` は State と D&D 結線のみで約890行
（統合前は年ビュー1514行 + 月ビュー1742行の合計3256行）。

### 4. 月ビューにのみ存在した依存関係の連動期間編集UIを削除する

`_buildDependencyTile` の「編集」ボタンと `_showEditOffsetDialog` / `_applyOffsetChange`
（連動期間 `offsetMonths` を変更するダイアログ、約180行）は月ビューにのみ存在し、年ビューには
無かった。これは CLAUDE.md が警告する「2ファイル間の食い違い」の実例だった。

年ビューに機能を追加するとプロダクト改善になり、ピボットで無駄になる可能性があるため、
「コード量が少なく単純になる方」に倒して削除し、月ビューを年ビューに揃えた。連動期間は
D&D の連動移動でも実質変更できるため機能として必須ではない。UIとして本当に必要かは
ピボット後のUI方針が固まってから判断する。 → #50

## 検討したが採らなかった案

- **#36（同一ヘルパー共通化）と #34（2実装統合）を別 PR に保つ**: Issue 上は「PRを小さく保つ
  ため分離した」とあったが、読み比べた結果ほぼ全てのメソッドが同一で、分けると
  「グリッド線とチケットだけ共通化され、他は2ファイルのまま」という中途半端な状態が残る。
  最終的なコード量が最小になる統合を優先した。
- **年ビューにも連動期間編集UIを追加する**: 機能追加そのものであり、ピボット前提の方針に反する。

## 影響範囲

- 新設: `lib/features/timeline/domain/event_stacking.dart`,
  `lib/features/timeline/domain/catalog_placement_check.dart`,
  `lib/features/timeline/presentation/widgets/timeline_view.dart`,
  `lib/features/timeline/presentation/widgets/timeline_lane_labels.dart`,
  `lib/features/timeline/presentation/widgets/timeline_axis.dart`,
  `lib/features/timeline/presentation/widgets/catalog_drop_preview.dart`,
  `lib/features/timeline/presentation/widgets/event_detail_dialog.dart`
- 削除: `lib/features/timeline/presentation/widgets/year_timeline.dart`,
  `lib/features/timeline/presentation/widgets/year_month_timeline.dart`
- `lib/features/timeline/presentation/timeline_screen.dart`: `TimelineViewMode` の定義元を
  `timeline_view.dart` に移設（`export` で再公開）、ウィジェット呼び出しを `TimelineView(mode:)`
  1箇所に統一
- `CLAUDE.md` §4: 2実装重複の注意書きを削除
- テスト: `event_stacking_test.dart` / `catalog_placement_check_test.dart` を新設、
  `year_month_timeline_test.dart` を `timeline_view_test.dart` にリネームし
  `TimelineView(mode:)` に差し替え。年ビューの D&D 結線テストが今回追加され、#44
  （年ビューにテストが1本も無い）を解消した

## 関連

- #34（2実装統合）, #35（TimelineScale 切り出し）, #36（同一ヘルパー共通化）, #38（ウィジェット分割）,
  #44（年ビューのテスト不在） — 本 PR で解消
- #50（連動期間編集UIの要否）, #51（「現在に戻る」の位置ズレ） — 未決事項として新規起票
- ADR-020（YearMonth 導入）
- CLAUDE.md §4「実装上の注意」
