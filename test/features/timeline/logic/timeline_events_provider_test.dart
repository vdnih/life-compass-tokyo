import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';

class MockEventRepository extends Mock implements EventRepository {}

class FakeLifeEvent extends Fake implements LifeEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLifeEvent());
  });

  group('TimelineEventsProvider の機能一覧（仕様）', () {
    late MockEventRepository mockRepository;

    setUp(() {
      mockRepository = MockEventRepository();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('初期状態: EventRepositoryからイベント一覧を取得し、AsyncDataとして状態を保持すること', () async {
      final mockEvents = [
        const LifeEvent(
          id: 'test-id-1',
          date: '2020-01',
          title: 'Test 1',
          description: '',
          category: EventCategory.joining,
        ),
      ];
      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => mockEvents);

      final container = createContainer();

      final events = await container.read(timelineEventsProvider.future);

      expect(events, equals(mockEvents));
      verify(() => mockRepository.fetchEvents()).called(1);
    });

    test('追加成功: 新しいイベントを追加した際、AsyncLoadingを経て新しい一覧のAsyncDataに遷移すること', () async {
      final initialEvents = [
        const LifeEvent(
          id: 'test-id-1',
          date: '2020-01',
          title: 'Test 1',
          description: '',
          category: EventCategory.joining,
        ),
      ];
      const newEvent = LifeEvent(
        id: 'test-id-2',
        date: '2021-01',
        title: 'Test 2',
        description: '',
        category: EventCategory.promotion,
      );
      final updatedEvents = [...initialEvents, newEvent];

      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => initialEvents);
      when(() => mockRepository.saveEvent(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => updatedEvents);

      final states = <AsyncValue<List<LifeEvent>>>[];
      container.listen(timelineEventsProvider, (previous, next) {
        states.add(next);
      });

      await container.read(timelineEventsProvider.notifier).addEvent(newEvent);

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.first is AsyncLoading, isTrue);
      expect(states.last.value, equals(updatedEvents));

      verify(() => mockRepository.saveEvent(newEvent)).called(1);
      verify(() => mockRepository.fetchEvents()).called(2);
    });

    test('削除成功: 既存のイベントを削除した際、AsyncLoadingを経て新しい一覧のAsyncDataに遷移すること', () async {
      const targetEvent = LifeEvent(
        id: 'test-id-1',
        date: '2020-01',
        title: 'Test 1',
        description: '',
        category: EventCategory.joining,
      );
      final initialEvents = [targetEvent];

      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => initialEvents);
      when(() => mockRepository.deleteEvent(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      when(() => mockRepository.fetchEvents()).thenAnswer((_) async => []);

      final states = <AsyncValue<List<LifeEvent>>>[];
      container.listen(timelineEventsProvider, (previous, next) {
        states.add(next);
      });

      await container
          .read(timelineEventsProvider.notifier)
          .deleteEvent(targetEvent);

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.first is AsyncLoading, isTrue);
      expect(states.last.value, isEmpty);

      verify(() => mockRepository.deleteEvent(targetEvent)).called(1);
    });

    test('削除エラー: EventRepositoryの削除処理が例外を投げた場合、状態がAsyncErrorに遷移すること', () async {
      const targetEvent = LifeEvent(
        id: 'test-id-1',
        date: '2020-01',
        title: 'Test 1',
        description: '',
        category: EventCategory.joining,
      );
      final initialEvents = [targetEvent];
      final exception = Exception('Failed to delete event');

      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => initialEvents);
      when(() => mockRepository.deleteEvent(any())).thenThrow(exception);

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      final states = <AsyncValue<List<LifeEvent>>>[];
      container.listen(timelineEventsProvider, (previous, next) {
        states.add(next);
      });

      await container
          .read(timelineEventsProvider.notifier)
          .deleteEvent(targetEvent);

      expect(states.any((s) => s is AsyncError), isTrue);
      verify(() => mockRepository.deleteEvent(targetEvent)).called(1);
    });

    test('エラー発生時: EventRepositoryの処理が例外を投げた場合、状態がAsyncErrorに遷移すること', () async {
      final initialEvents = [
        const LifeEvent(
          id: 'test-id-1',
          date: '2020-01',
          title: 'Test 1',
          description: '',
          category: EventCategory.joining,
        ),
      ];
      const newEvent = LifeEvent(
        id: 'test-id-error',
        date: '2021-01',
        title: 'Error Event',
        description: '',
        category: EventCategory.joining,
      );
      final exception = Exception('Failed to save event');

      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => initialEvents);
      when(() => mockRepository.saveEvent(any())).thenThrow(exception);

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      final states = <AsyncValue<List<LifeEvent>>>[];
      container.listen(timelineEventsProvider, (previous, next) {
        states.add(next);
      });

      await container.read(timelineEventsProvider.notifier).addEvent(newEvent);

      expect(states.any((s) => s is AsyncError), isTrue);
      verify(() => mockRepository.saveEvent(newEvent)).called(1);
    });

    test('moveEvent成功: 指定したIDのイベントの日付が更新されること', () async {
      const targetEvent = LifeEvent(
        id: 'event-move-1',
        date: '2025-01',
        title: '移動するイベント',
        description: '',
        category: EventCategory.jobChange,
      );
      const updatedEvent = LifeEvent(
        id: 'event-move-1',
        date: '2025-06',
        title: '移動するイベント',
        description: '',
        category: EventCategory.jobChange,
      );
      final initialEvents = [targetEvent];
      final updatedEvents = [updatedEvent];

      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => initialEvents);
      when(() => mockRepository.updateEvent(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => updatedEvents);

      final states = <AsyncValue<List<LifeEvent>>>[];
      container.listen(timelineEventsProvider, (previous, next) {
        states.add(next);
      });

      await container
          .read(timelineEventsProvider.notifier)
          .moveEvent('event-move-1', '2025-06');

      expect(states.last.value, equals(updatedEvents));
      verify(() => mockRepository.updateEvent(any())).called(1);
    });
  });
}
