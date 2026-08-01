import 'package:flutter/foundation.dart';

import 'year_month.dart';

/// タイムラインの座標系（`YearMonth` ⇔ 画面上のX座標）を表す値オブジェクト。
///
/// `year_timeline.dart`（年ビュー）と `year_month_timeline.dart`（月ビュー）は
/// 表示単位が違うだけで座標変換の式は同一であり、この3フィールドに正規化すると畳める（ADR-020 §5、#35）。
///
/// - 月ビュー: `origin` = 表示開始月、`pixelsPerSlot` = 60.0、`monthsPerSlot` = 1
/// - 年ビュー: `origin` = 表示開始年の1月、`pixelsPerSlot` = 80.0、`monthsPerSlot` = 12
///
/// 年ビューが常に1月にスナップする非対称性（ADR-020）は特別扱いしていない。
/// `monthsPerSlot=12` のときに [dateAtSlot] が自動的に1月刻みになることから導かれる。
@immutable
class TimelineScale {
  /// スロット0（画面左端）が表す年月
  final YearMonth origin;

  /// 1スロットあたりのピクセル幅
  final double pixelsPerSlot;

  /// 1スロットが表す月数（月ビュー: 1、年ビュー: 12）
  final int monthsPerSlot;

  /// 表示するスロット数（月ビュー: totalMonths、年ビュー: totalYears）
  final int slotCount;

  /// 軸の左端に空ける余白。両ビューで共通のレイアウト定数。
  static const double leftPadding = 20.0;

  const TimelineScale({
    required this.origin,
    required this.pixelsPerSlot,
    required this.monthsPerSlot,
    required this.slotCount,
  });

  /// [ym] の原点からのスロット数（小数）
  double offsetSlots(YearMonth ym) =>
      ym.differenceInMonths(origin) / monthsPerSlot;

  /// [ym] のX座標
  double xOf(YearMonth ym) => leftPadding + offsetSlots(ym) * pixelsPerSlot;

  /// スロットインデックス [index] のX座標（グリッド線・軸ラベル・スナップ枠用）
  double xOfSlot(int index) => leftPadding + index * pixelsPerSlot;

  /// X座標 [dx] が属するスロットインデックス（ドロップ位置の判定用）
  int slotIndexAt(double dx) => ((dx - leftPadding) / pixelsPerSlot).floor();

  /// スロットインデックス [index] が表す年月
  YearMonth dateAtSlot(int index) => origin.addMonths(index * monthsPerSlot);

  /// [index] が表示範囲内（`0 <= index < slotCount`）か
  bool containsSlot(int index) => index >= 0 && index < slotCount;

  /// [ym] が表示範囲内か
  bool contains(YearMonth ym) {
    final offset = offsetSlots(ym);
    return offset >= 0 && offset < slotCount;
  }

  /// [months] ヶ月分の幅をピクセルで返す（期間バーの長さ用）
  double widthOfMonths(int months) => months / monthsPerSlot * pixelsPerSlot;

  /// 表示範囲全体の幅（右端の余白込み）
  double get totalWidth => slotCount * pixelsPerSlot + 100;
}
