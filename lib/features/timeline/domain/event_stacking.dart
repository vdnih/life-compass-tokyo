import 'life_event.dart';
import 'timeline_scale.dart';

/// イベントを仕事/プライベートのレーンごとに重ならないよう段積みし、
/// 各イベントIDに段（stack level, 0始まり）を割り当てる純粋関数。
///
/// `year_timeline.dart` と `year_month_timeline.dart` に byte 単位で重複していた
/// 実装を統合したもの（#34, #36）。[scale] のスロット単位（`offsetSlots`）で
/// 開始・終了位置を比較するため、年ビュー・月ビューのどちらの [TimelineScale] でも
/// 同じ結果になる。
Map<String, int> computeStackIndices(
  List<LifeEvent> events,
  TimelineScale scale,
) {
  final indices = <String, int>{};
  for (final isWork in [true, false]) {
    final lane = events.where((e) => e.isWork == isWork).toList()
      ..sort((a, b) =>
          scale.offsetSlots(a.yearMonth).compareTo(scale.offsetSlots(b.yearMonth)));
    final stackEndAt = <double>[];
    for (final event in lane) {
      final start = scale.offsetSlots(event.yearMonth);
      final end = event.hasDuration
          ? scale.offsetSlots(event.endYearMonth!) + 1.0
          : start + 1.0;
      int level = stackEndAt.indexWhere((e) => e <= start);
      if (level == -1) {
        level = stackEndAt.length;
        stackEndAt.add(end);
      } else {
        stackEndAt[level] = end;
      }
      indices[event.id] = level;
    }
  }
  return indices;
}

/// [computeStackIndices] の結果から、レーン1本分に必要な高さを算出する。
///
/// 仕事・プライベート両レーンのうち、より深く段積みされた方に合わせる
/// （両レーンとも同じ高さで描画されるため）。
double computeStackedRowHeight({
  required Map<String, int> stackIndices,
  required List<LifeEvent> events,
  required double minRowHeight,
  required double topPadding,
  required double cardHeight,
}) {
  if (events.isEmpty) return minRowHeight;
  int workMax = 0, privateMax = 0;
  for (final e in events) {
    final lvl = (stackIndices[e.id] ?? 0) + 1;
    if (e.isWork) {
      if (lvl > workMax) workMax = lvl;
    } else {
      if (lvl > privateMax) privateMax = lvl;
    }
  }
  final maxStack = workMax > privateMax ? workMax : privateMax;
  final computed = topPadding + maxStack * cardHeight;
  return computed > minRowHeight ? computed : minRowHeight;
}
