# ADR-025: タイムラインの座標系を「境界（線）」から「区間（面）」に変える

**Date**: 2026-08-21
**Status**: Accepted

## 背景

月ビューでイベントアイコンが「月と月の境界線の上」に描画されており、そのアイコンがどちらの月に
属するのか視覚的に判別できないという指摘があった。#75（ドラッグ操作の着地日が約1ヶ月手前に
ズレる不具合）はこの曖昧さの一症状で、`PointEventMarker.anchorInset` による補正で数値上の
着地位置は直ったが、見た目の曖昧さ自体は残っていた。

コードを見ると、実装は既に「線」と「面」の意味論が混在していた:

| 場所 | 意味論 |
|---|---|
| `TimelineScale.slotIndexAt()`（`floor()`） | 面（座標はブロックに属する） |
| ドロップ中のスナップ枠（`timeline_view.dart` の `_buildDropTarget`） | 面（1スロット幅を塗る） |
| `event_stacking.dart` の `computeStackIndices`（`end = start + 1.0`） | 面（イベントは1スロット分の幅を占める前提） |
| グリッド線・軸ラベル（`timeline_axis.dart`）、旧 `TimelineScale.xOf()` によるマーカー配置 | 線（境界の上に載る） |

「ドラッグ中はブロックがハイライトされるのに、離すとアイコンはそのブロックの左端の線上に載る」
という不一致が、使いづらさの正体だった。

## 決定

タイムラインの座標系を **面（ブロック）モデルに統一する**。線 = 月の境界（グリッド線のみ）、
面 = その月そのもの（軸ラベル・点イベントのアイコン・期間バー・現在マーカー・ドロップ枠すべて）。

### 1. `TimelineScale` にブロック座標を追加し、境界座標（`xOf`）を廃止する

```dart
int slotIndexOf(YearMonth ym);            // ym が属するブロックのインデックス
double xOfBlock(YearMonth ym);            // ブロック左端X（期間バー・ドロップ枠用）
double xCenterOf(YearMonth ym);           // ブロック中央X（点イベント・軸ラベル用）
double inclusiveWidth(YearMonth a, YearMonth b); // 両端含みの幅（期間バー用）
```

旧 `xOf()`（`offsetSlots(ym) * pixelsPerSlot` による連続座標）は UI 側の呼び出しが残っていると
「配置方法が2通りある」状態に逆戻りするため削除した。連続座標そのもの（`offsetSlots`）は
`event_stacking.dart` の段積み判定で引き続き使うため残している。

### 2. 期間イベントのバーは両端を含む

`2025-03` 〜 `2025-06`（4ヶ月イベント）は4ブロック分の幅になる（旧実装は3ブロック分で、
終了月のブロックが塗られていないように見えた）。これは `event_stacking.dart` が
既に採用していた `end = start + 1.0` という意味論と一致させる変更でもある。

**トレードオフ**: 期間バーの見た目の長さが変わる（1ブロック分長くなる）。データ
（`LifeEvent.endDate`）自体は変更しない。

### 3. 年ビューは年内の小数位置を失う

`TimelineScale` は月ビュー・年ビュー共通の実装（ADR-020 §5, #35）。面モデルでは
`xCenterOf` / `xOfBlock` は `slotIndexOf`（`floor()`）で丸めるため、年ビューでは
「同じ年に属する月はすべて同じブロック中央に描画される」。旧 `xOf()` は年ビューでも
年内の月に応じた小数位置（例: `2021-07` は `2021-01` から1.5スロット）を返していたが、
これは年ビューが常に1月にスナップする表示（軸ラベル・グリッド線は元々1月にしか出ない）と
噛み合っておらず、実質使われていなかった。

### 4. 「現在」マーカーは当月ブロックの塗りにする

縦の細線1本 → ブロック全体を薄く塗り、左右に細い境界線。ドラッグ中のスナップ枠
（`alpha: 0.14`）よりも薄い `alpha: 0.08` にして、ドラッグ中に現在ブロックと
混同しないようにしている。

### 5. `PointEventMarker.anchorInset` はブロック中央基準に変える

`hasDuration ? 0 : markerWidth / 2`（マーカー中央 = 基準月そのもの）から
`hasDuration ? 0 : (markerWidth - pixelsPerSlot) / 2`（マーカー中央 = ブロック中央）に変更。
#75 で入れた「描画時に引いたオフセットをドロップ計算で足し戻す」という往復の仕組み自体は
変えていない。値の基準だけがブロック左端に変わった。

## 検討したが採らなかった案

- **月ビューだけに適用する**: 年ビューとの見た目の一貫性が崩れる。`TimelineScale` が
  両ビュー共通の実装であり、追加コストがほぼ無いため両方に適用した。
- **期間バーの長さを現状維持する**: 「3月から6月まで」という自然な読みと矛盾したまま残る
  ことになり、根本原因（線と面の意味論の混在）を期間バーにだけ残すことになるため採らなかった。
- **交互の背景色（ゼブラ）でブロックを強調する**: 今回のスコープには含めなかった。
  ブロック中央寄せのラベルと現在マーカーの塗りだけで「面」として伝わるか実機で確認し、
  それでも線に見えるようなら別 Issue で検討する。

## 影響範囲

- `lib/features/timeline/domain/timeline_scale.dart`: `xOf` を削除し `slotIndexOf` /
  `xOfBlock` / `xCenterOf` / `inclusiveWidth` を追加
- `lib/features/timeline/presentation/widgets/point_event_marker.dart`: `anchorInset` の
  基準をブロック中央に変更（シグネチャに `pixelsPerSlot` を追加）
- `lib/features/timeline/presentation/widgets/timeline_axis.dart`: 軸ラベルをブロック中央に、
  現在マーカーを縦線からブロック塗りに変更。ラベル下の目盛りの縦棒は廃止（境界を指す部品の
  ため、ブロック中央に置くと再び「線」の誤読を招く）
- `lib/features/timeline/presentation/widgets/timeline_view.dart`: イベントカード・
  カスケードプレビュー・スクロール位置（`_scrollToNow` 等）・依存線の接続点（`eventPositions`）
  をブロック基準の座標に変更
- `lib/features/timeline/presentation/widgets/catalog_drop_preview.dart`: プレビューの
  位置・バー幅をドロップ後の実カードと同じ式に統一
- `test/features/timeline/domain/timeline_scale_test.dart`: 新しい座標変換のテストを追加、
  ドラッグ着地月の往復不変条件テストを新基準に更新

## 関連

- ADR-020: `YearMonth` 値オブジェクトの導入（座標変換の入力となる日付型）
- ADR-021: 年ビュー・月ビューの `TimelineView` 統合（`TimelineScale` が両ビュー共通の理由）
- #75: ドラッグ着地日のズレ修正（本 ADR が対処する曖昧さの一症状）
