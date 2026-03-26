import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/cascade_move_provider.dart';

LifeEvent _event({required String id, required String date, String? endDate}) {
  return LifeEvent(
    id: id,
    date: date,
    endDate: endDate,
    title: 'Event $id',
    description: '',
    category: EventCategory.jobChange,
  );
}

EventDependency _dep({
  required String id,
  required String sourceId,
  required String targetId,
  int offsetMonths = 0,
}) {
  return EventDependency(
    id: id,
    sourceEventId: sourceId,
    targetEventId: targetId,
    type: DependencyType.consequence,
    offsetMonths: offsetMonths,
  );
}

void main() {
  group('computeCascadeUpdates', () {
    test('単一依存: A->B でAを+3ヶ月移動するとBも+3ヶ月移動すること', () {
      final events = [
        _event(id: 'a', date: '2025-01'),
        _event(id: 'b', date: '2025-04'),
      ];
      final dependencies = [
        _dep(id: 'dep-ab', sourceId: 'a', targetId: 'b'),
      ];

      final changes = computeCascadeUpdates(
        movedEventId: 'a',
        newDate: '2025-04',
        allEvents: events,
        allDependencies: dependencies,
      );

      final bChange = changes.firstWhere((c) => c.eventId == 'b');
      expect(bChange.newDate, equals('2025-07'));
    });

    test('チェーン: A->B->C でAを移動すると全イベントが移動すること', () {
      final events = [
        _event(id: 'a', date: '2025-01'),
        _event(id: 'b', date: '2025-04'),
        _event(id: 'c', date: '2025-07'),
      ];
      final dependencies = [
        _dep(id: 'dep-ab', sourceId: 'a', targetId: 'b'),
        _dep(id: 'dep-bc', sourceId: 'b', targetId: 'c'),
      ];

      final changes = computeCascadeUpdates(
        movedEventId: 'a',
        newDate: '2025-04',
        allEvents: events,
        allDependencies: dependencies,
      );

      final bChange = changes.firstWhere((c) => c.eventId == 'b');
      final cChange = changes.firstWhere((c) => c.eventId == 'c');
      expect(bChange.newDate, equals('2025-07'));
      expect(cChange.newDate, equals('2025-10'));
    });

    test('独立したイベントは移動しないこと', () {
      final events = [
        _event(id: 'a', date: '2025-01'),
        _event(id: 'b', date: '2025-04'),
        _event(id: 'x', date: '2025-06'),
      ];
      final dependencies = [
        _dep(id: 'dep-ab', sourceId: 'a', targetId: 'b'),
      ];

      final changes = computeCascadeUpdates(
        movedEventId: 'a',
        newDate: '2025-04',
        allEvents: events,
        allDependencies: dependencies,
      );

      final xChanges = changes.where((c) => c.eventId == 'x').toList();
      expect(xChanges, isEmpty);
    });

    test('0ヶ月移動の場合は空リストを返すこと', () {
      final events = [
        _event(id: 'a', date: '2025-01'),
        _event(id: 'b', date: '2025-04'),
      ];
      final dependencies = [
        _dep(id: 'dep-ab', sourceId: 'a', targetId: 'b'),
      ];

      final changes = computeCascadeUpdates(
        movedEventId: 'a',
        newDate: '2025-01',
        allEvents: events,
        allDependencies: dependencies,
      );

      expect(changes, isEmpty);
    });

    test('後退移動: Aを-3ヶ月移動するとBも-3ヶ月移動すること', () {
      final events = [
        _event(id: 'a', date: '2025-04'),
        _event(id: 'b', date: '2025-07'),
      ];
      final dependencies = [
        _dep(id: 'dep-ab', sourceId: 'a', targetId: 'b'),
      ];

      final changes = computeCascadeUpdates(
        movedEventId: 'a',
        newDate: '2025-01',
        allEvents: events,
        allDependencies: dependencies,
      );

      final bChange = changes.firstWhere((c) => c.eventId == 'b');
      expect(bChange.newDate, equals('2025-04'));
    });

    test('移動されたイベント自身も変更リストに含まれること', () {
      final events = [
        _event(id: 'a', date: '2025-01'),
        _event(id: 'b', date: '2025-04'),
      ];
      final dependencies = [
        _dep(id: 'dep-ab', sourceId: 'a', targetId: 'b'),
      ];

      final changes = computeCascadeUpdates(
        movedEventId: 'a',
        newDate: '2025-04',
        allEvents: events,
        allDependencies: dependencies,
      );

      final aChange = changes.firstWhere((c) => c.eventId == 'a');
      expect(aChange.newDate, equals('2025-04'));
    });

    test('期間イベントのendDateも連動して移動すること', () {
      final events = [
        _event(id: 'a', date: '2025-01'),
        _event(id: 'b', date: '2025-04', endDate: '2026-04'),
      ];
      final dependencies = [
        _dep(id: 'dep-ab', sourceId: 'a', targetId: 'b'),
      ];

      final changes = computeCascadeUpdates(
        movedEventId: 'a',
        newDate: '2025-04',
        allEvents: events,
        allDependencies: dependencies,
      );

      final bChange = changes.firstWhere((c) => c.eventId == 'b');
      expect(bChange.newEndDate, equals('2026-07'));
    });

    test('年境界: 2025-11を+3ヶ月移動すると2026-02になること', () {
      final events = [
        _event(id: 'a', date: '2025-08'),
        _event(id: 'b', date: '2025-11'),
      ];
      final dependencies = [
        _dep(id: 'dep-ab', sourceId: 'a', targetId: 'b'),
      ];

      final changes = computeCascadeUpdates(
        movedEventId: 'a',
        newDate: '2025-11',
        allEvents: events,
        allDependencies: dependencies,
      );

      final bChange = changes.firstWhere((c) => c.eventId == 'b');
      expect(bChange.newDate, equals('2026-02'));
    });
  });
}
