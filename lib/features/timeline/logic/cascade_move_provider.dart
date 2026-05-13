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
///
/// Wave 4 追加: 移動対象イベントの id を parentEventId として持つ
/// マイルストーンも一緒に移動する。マイルストーンと親イベントの月差は保持される。
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

  // Wave 4: visited に含まれるイベントを parentEventId として持つマイルストーンを追従させる
  // マイルストーンは依存グラフに含まれないため、別途処理する。
  // マイルストーンの新しい日付 = マイルストーン元の日付 + deltaMonths（親と同じ差分）
  final milestoneChanges = <EventDateChange>[];
  for (final event in allEvents) {
    if (event.kind != EventKind.milestone) continue;
    if (event.parentEventId == null) continue;
    // 親が visited に含まれる（つまり移動対象グループの一員）かつ
    // まだ changes に含まれていない場合にのみ追加する
    if (!visited.contains(event.parentEventId)) continue;
    if (changes.any((c) => c.eventId == event.id)) continue;

    final updatedDate = _addMonths(event.date, deltaMonths);
    final updatedEndDate =
        event.endDate != null ? _addMonths(event.endDate!, deltaMonths) : null;

    milestoneChanges.add(EventDateChange(
      eventId: event.id,
      oldDate: event.date,
      newDate: updatedDate,
      oldEndDate: event.endDate,
      newEndDate: updatedEndDate,
    ));
  }

  return [...changes, ...milestoneChanges];
}
