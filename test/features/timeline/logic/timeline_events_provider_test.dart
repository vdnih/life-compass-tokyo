import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/catalog/data/predefined_catalog_registry.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';

import '../../../support/mocks.dart';
import '../../../support/pump.dart' as support;

void main() {
  setUpAll(registerCommonFallbackValues);

  group('TimelineEventsProvider の機能一覧（仕様）', () {
    late MockEventRepository mockRepository;

    setUp(() {
      mockRepository = stubEventRepository();
    });

    ProviderContainer createContainer() {
      return support.createContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockRepository)],
      );
    }

    test('初期状態: EventRepositoryからイベント一覧を取得し、AsyncDataとして状態を保持すること', () async {
      final mockEvents = [
        const LifeEvent(
          id: 'test-id-1',
          date: '2020-01',
          title: 'Test 1',
          description: '',
          catalogId: 'joining-company',
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
          catalogId: 'joining-company',
        ),
      ];
      const newEvent = LifeEvent(
        id: 'test-id-2',
        date: '2021-01',
        title: 'Test 2',
        description: '',
        catalogId: 'promotion',
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
        catalogId: 'joining-company',
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
        catalogId: 'joining-company',
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
          catalogId: 'joining-company',
        ),
      ];
      const newEvent = LifeEvent(
        id: 'test-id-error',
        date: '2021-01',
        title: 'Error Event',
        description: '',
        catalogId: 'joining-company',
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
        catalogId: 'job-change',
      );
      const updatedEvent = LifeEvent(
        id: 'event-move-1',
        date: '2025-06',
        title: '移動するイベント',
        description: '',
        catalogId: 'job-change',
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

    test('moveEvent成功: 期間イベントのendDateも同時に更新されること', () async {
      const targetEvent = LifeEvent(
        id: 'event-move-2',
        date: '2025-04',
        endDate: '2026-04',
        title: '期間イベント',
        description: '',
        catalogId: 'childcare-leave',
      );
      const updatedEvent = LifeEvent(
        id: 'event-move-2',
        date: '2025-07',
        endDate: '2026-07',
        title: '期間イベント',
        description: '',
        catalogId: 'childcare-leave',
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
          .moveEvent('event-move-2', '2025-07', newEndDate: '2026-07');

      expect(states.last.value, equals(updatedEvents));
      verify(() => mockRepository.updateEvent(any())).called(1);
    });

    test('addEventFromCatalog: 結婚式（wedding-ceremony）を追加すると単一のイベントが生成されること',
        () async {
      when(() => mockRepository.fetchEvents()).thenAnswer((_) async => []);
      when(() => mockRepository.saveEvent(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      // saveEvent が呼ばれた引数を記録するためにモックを設定
      final savedEvents = <LifeEvent>[];
      when(() => mockRepository.saveEvent(any())).thenAnswer((invocation) async {
        savedEvents.add(invocation.positionalArguments[0] as LifeEvent);
      });
      when(() => mockRepository.fetchEvents())
          .thenAnswer((_) async => List.unmodifiable(savedEvents));

      final catalog = PredefinedCatalogRegistry.findById('wedding-ceremony')!;
      await container
          .read(timelineEventsProvider.notifier)
          .addEventFromCatalog(catalog, '2026-06');

      // マイルストーン機能廃止後はカタログから1件のみ生成される
      expect(savedEvents.length, equals(1));
    });

    test('addEventFromCatalog: 生成されたイベントの catalogId が正しいこと', () async {
      when(() => mockRepository.fetchEvents()).thenAnswer((_) async => []);
      when(() => mockRepository.saveEvent(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      final savedEvents = <LifeEvent>[];
      when(() => mockRepository.saveEvent(any())).thenAnswer((invocation) async {
        savedEvents.add(invocation.positionalArguments[0] as LifeEvent);
      });
      when(() => mockRepository.fetchEvents())
          .thenAnswer((_) async => List.unmodifiable(savedEvents));

      final catalog = PredefinedCatalogRegistry.findById('wedding-ceremony')!;
      await container
          .read(timelineEventsProvider.notifier)
          .addEventFromCatalog(catalog, '2026-06');

      expect(savedEvents.single.catalogId, equals('wedding-ceremony'));
    });

    test('addEventFromCatalog: budgetYen に catalog.defaultBudgetYen が設定されること', () async {
      when(() => mockRepository.fetchEvents()).thenAnswer((_) async => []);
      when(() => mockRepository.saveEvent(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      final savedEvents = <LifeEvent>[];
      when(() => mockRepository.saveEvent(any())).thenAnswer((invocation) async {
        savedEvents.add(invocation.positionalArguments[0] as LifeEvent);
      });
      when(() => mockRepository.fetchEvents())
          .thenAnswer((_) async => List.unmodifiable(savedEvents));

      final catalog = PredefinedCatalogRegistry.findById('wedding-ceremony')!;
      await container
          .read(timelineEventsProvider.notifier)
          .addEventFromCatalog(catalog, '2026-06');

      expect(savedEvents.single.budgetYen, equals(3000000));
    });

    test(
        'addEventFromCatalog: defaultDurationMonths を持つカタログ（childcare-leave=12ヶ月）をドロップすると endDate が設定されること',
        () async {
      when(() => mockRepository.fetchEvents()).thenAnswer((_) async => []);
      when(() => mockRepository.saveEvent(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      final savedEvents = <LifeEvent>[];
      when(() => mockRepository.saveEvent(any())).thenAnswer((invocation) async {
        savedEvents.add(invocation.positionalArguments[0] as LifeEvent);
      });
      when(() => mockRepository.fetchEvents())
          .thenAnswer((_) async => List.unmodifiable(savedEvents));

      // childcare-leave は defaultDurationMonths: 12
      final catalog = PredefinedCatalogRegistry.findById('childcare-leave')!;
      await container
          .read(timelineEventsProvider.notifier)
          .addEventFromCatalog(catalog, '2026-03');

      // 2026-03 + 12ヶ月 = 2027-03
      expect(savedEvents.single.endDate, equals('2027-03'));
    });

    test(
        'addEventFromCatalog: defaultDurationMonths を持たないカタログ（childbirth）をドロップすると endDate が null になること',
        () async {
      when(() => mockRepository.fetchEvents()).thenAnswer((_) async => []);
      when(() => mockRepository.saveEvent(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      final savedEvents = <LifeEvent>[];
      when(() => mockRepository.saveEvent(any())).thenAnswer((invocation) async {
        savedEvents.add(invocation.positionalArguments[0] as LifeEvent);
      });
      when(() => mockRepository.fetchEvents())
          .thenAnswer((_) async => List.unmodifiable(savedEvents));

      // childbirth は defaultDurationMonths を持たない（null）
      final catalog = PredefinedCatalogRegistry.findById('childbirth')!;
      await container
          .read(timelineEventsProvider.notifier)
          .addEventFromCatalog(catalog, '2026-03');

      expect(savedEvents.single.endDate, isNull);
    });
  });
}
