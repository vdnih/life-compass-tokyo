import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/data/firestore_event_repository.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreEventRepository repo;

  const testUserId = 'test-user-id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FirestoreEventRepository(testUserId, db: fakeFirestore);
  });

  LifeEvent _makeEvent({
    String id = 'event-1',
    String date = '2024-06',
    String? endDate,
    String title = 'テストイベント',
    EventCategory category = EventCategory.joining,
    EventStatus status = EventStatus.planned,
  }) {
    return LifeEvent(
      id: id,
      date: date,
      endDate: endDate,
      title: title,
      description: 'テスト用の説明',
      category: category,
      status: status,
    );
  }

  group('FirestoreEventRepository', () {
    group('saveEvent() + fetchEvents()', () {
      test('保存したイベントを取得できること', () async {
        final event = _makeEvent();

        await repo.saveEvent(event);
        final events = await repo.fetchEvents();

        expect(events.length, equals(1));
      });

      test('取得したイベントの id が一致すること', () async {
        final event = _makeEvent(id: 'event-xyz');

        await repo.saveEvent(event);
        final events = await repo.fetchEvents();

        expect(events.first.id, equals('event-xyz'));
      });

      test('取得したイベントのカテゴリが一致すること', () async {
        final event = _makeEvent(category: EventCategory.marriage);

        await repo.saveEvent(event);
        final events = await repo.fetchEvents();

        expect(events.first.category, equals(EventCategory.marriage));
      });

      test('取得したイベントのステータスが一致すること', () async {
        final event = _makeEvent(status: EventStatus.goal);

        await repo.saveEvent(event);
        final events = await repo.fetchEvents();

        expect(events.first.status, equals(EventStatus.goal));
      });

      test('複数イベントを date 昇順で取得できること', () async {
        await repo.saveEvent(_makeEvent(id: 'e2', date: '2025-03'));
        await repo.saveEvent(_makeEvent(id: 'e1', date: '2023-01'));

        final events = await repo.fetchEvents();

        expect(events.first.id, equals('e1'));
        expect(events.last.id, equals('e2'));
      });

      test('endDate が null のイベントを正しく保存・取得できること', () async {
        final event = _makeEvent(endDate: null);

        await repo.saveEvent(event);
        final events = await repo.fetchEvents();

        expect(events.first.endDate, isNull);
      });

      test('endDate が設定されたイベントを正しく保存・取得できること', () async {
        final event = _makeEvent(endDate: '2024-09');

        await repo.saveEvent(event);
        final events = await repo.fetchEvents();

        expect(events.first.endDate, equals('2024-09'));
      });
    });

    group('deleteEvent()', () {
      test('削除後はイベントが取得されないこと', () async {
        final event = _makeEvent();
        await repo.saveEvent(event);

        await repo.deleteEvent(event);
        final events = await repo.fetchEvents();

        expect(events, isEmpty);
      });

      test('指定イベントのみが削除されること', () async {
        final e1 = _makeEvent(id: 'e1');
        final e2 = _makeEvent(id: 'e2', date: '2025-01');
        await repo.saveEvent(e1);
        await repo.saveEvent(e2);

        await repo.deleteEvent(e1);
        final events = await repo.fetchEvents();

        expect(events.length, equals(1));
        expect(events.first.id, equals('e2'));
      });
    });

    group('updateEvent()', () {
      test('更新後のタイトルが取得されること', () async {
        final event = _makeEvent(title: '元のタイトル');
        await repo.saveEvent(event);

        final updated = event.copyWith(title: '更新後タイトル');
        await repo.updateEvent(updated);
        final events = await repo.fetchEvents();

        expect(events.first.title, equals('更新後タイトル'));
      });

      test('更新後のカテゴリが取得されること', () async {
        final event = _makeEvent(category: EventCategory.joining);
        await repo.saveEvent(event);

        final updated = event.copyWith(category: EventCategory.jobChange);
        await repo.updateEvent(updated);
        final events = await repo.fetchEvents();

        expect(events.first.category, equals(EventCategory.jobChange));
      });
    });
  });
}
