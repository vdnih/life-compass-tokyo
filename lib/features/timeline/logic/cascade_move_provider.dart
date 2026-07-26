import '../domain/event_dependency.dart';
import '../domain/life_event.dart';
import '../domain/year_month.dart';

/// イベントの日付変更を表すモデル
class EventDateChange {
  /// 変更対象のイベントID
  final String eventId;

  /// 変更前の日付
  final String oldDate;

  /// 変更後の日付
  final String newDate;

  /// 変更前の終了日（期間イベントの場合のみ）
  final String? oldEndDate;

  /// 変更後の終了日（期間イベントの場合のみ）
  final String? newEndDate;

  const EventDateChange({
    required this.eventId,
    required this.oldDate,
    required this.newDate,
    this.oldEndDate,
    this.newEndDate,
  });
}

/// イベントを移動したときに連動して変更すべき日付の一覧を計算する純粋関数
///
/// 移動差分（deltaMonths）を BFS で依存グラフを辿り、
/// 到達可能な全イベントに同じ差分を適用する。
/// 移動元イベント自身も結果に含まれる。
/// 差分が 0 の場合は空リストを返す。
List<EventDateChange> computeCascadeUpdates({
  required String movedEventId,
  required String newDate,
  required List<LifeEvent> allEvents,
  required List<EventDependency> allDependencies,
}) {
  // 移動対象のイベントを取得
  final movedEvent = allEvents.firstWhere((e) => e.id == movedEventId);
  final deltaMonths = YearMonth.parse(newDate)
      .differenceInMonths(YearMonth.parse(movedEvent.date));

  // 0ヶ月移動は変更なし
  if (deltaMonths == 0) return [];

  // イベントIDをキーとするマップを作成
  final eventMap = {for (final e in allEvents) e.id: e};

  // BFS で移動元から到達可能なすべてのイベントIDを収集（移動元自身を含む）
  final visited = <String>{};
  final queue = <String>[movedEventId];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (visited.contains(current)) continue;
    visited.add(current);

    // current を source または target とする依存関係の反対側を次のキューに追加
    final nextIds = allDependencies
        .where((d) => d.sourceEventId == current || d.targetEventId == current)
        .map((d) => d.sourceEventId == current ? d.targetEventId : d.sourceEventId)
        .where((id) => !visited.contains(id));

    queue.addAll(nextIds);
  }

  // 各到達可能なイベントの日付変更を計算（visited セットに移動元自身も含まれている）
  final changes = <EventDateChange>[];
  for (final eventId in visited) {
    final event = eventMap[eventId];
    if (event == null) continue;

    final updatedDate =
        YearMonth.parse(event.date).addMonths(deltaMonths).toString();
    final updatedEndDate = event.endDate != null
        ? YearMonth.parse(event.endDate!).addMonths(deltaMonths).toString()
        : null;

    changes.add(EventDateChange(
      eventId: eventId,
      oldDate: event.date,
      newDate: updatedDate,
      oldEndDate: event.endDate,
      newEndDate: updatedEndDate,
    ));
  }

  return changes;
}
