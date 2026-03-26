import '../domain/event_dependency.dart';
import '../domain/life_event.dart';

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

/// 日付文字列に月数を加算した文字列を返す
///
/// 年境界を正しく処理する（例: 2025-11 + 3 = 2026-02）。
String _addMonths(String dateStr, int months) {
  final parts = dateStr.split('-');
  int year = int.parse(parts[0]);
  int month = int.parse(parts[1]) + months;

  while (month > 12) {
    year++;
    month -= 12;
  }
  while (month < 1) {
    year--;
    month += 12;
  }

  return '$year-${month.toString().padLeft(2, '0')}';
}

/// yyyy-MM 形式の日付文字列を月数に変換する
int _dateToMonths(String dateStr) {
  final parts = dateStr.split('-');
  return int.parse(parts[0]) * 12 + int.parse(parts[1]);
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
  final oldMonths = _dateToMonths(movedEvent.date);
  final newMonths = _dateToMonths(newDate);
  final deltaMonths = newMonths - oldMonths;

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

    // current を source とする依存関係のターゲットを次のキューに追加
    final nextIds = allDependencies
        .where((d) => d.sourceEventId == current)
        .map((d) => d.targetEventId)
        .where((id) => !visited.contains(id));

    queue.addAll(nextIds);
  }

  // 各到達可能なイベントの日付変更を計算（visited セットに移動元自身も含まれている）
  final changes = <EventDateChange>[];
  for (final eventId in visited) {
    final event = eventMap[eventId];
    if (event == null) continue;

    final updatedDate = _addMonths(event.date, deltaMonths);
    final updatedEndDate =
        event.endDate != null ? _addMonths(event.endDate!, deltaMonths) : null;

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
