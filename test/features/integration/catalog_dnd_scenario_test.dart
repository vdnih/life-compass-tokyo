import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/catalog/data/predefined_catalog_registry.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/budget_summary_provider.dart';
import 'package:my_career_app/features/timeline/logic/constraint_checker_provider.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';

class MockEventRepository extends Mock implements EventRepository {}

class FakeLifeEvent extends Fake implements LifeEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLifeEvent());
  });

  group('シナリオA: 結婚式を配置するとマイルストーンが自動生成される', () {
    late MockEventRepository mockRepository;

    setUp(() {
      mockRepository = MockEventRepository();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('addEventFromCatalog(weddingCeremony) で親イベント1件＋マイルストーン3件が生成されること', () async {
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
          .addEventFromCatalog(catalog, '2027-06');

      // 親1件 + マイルストーン3件（衣装合わせ・招待状発送・最終打合せ）
      expect(savedEvents.length, equals(4));

      final parentEvents = savedEvents.where((e) => e.kind == EventKind.event).toList();
      final milestoneEvents = savedEvents.where((e) => e.kind == EventKind.milestone).toList();
      expect(parentEvents.length, equals(1));
      expect(milestoneEvents.length, equals(3));
    });

    test('kind=event の wedding-ceremony と kind=milestone の3件が生成されること', () async {
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
          .addEventFromCatalog(catalog, '2027-06');

      final parent = savedEvents.firstWhere((e) => e.kind == EventKind.event);
      expect(parent.catalogId, equals('wedding-ceremony'));

      final milestones = savedEvents.where((e) => e.kind == EventKind.milestone).toList();
      final milestoneTitles = milestones.map((m) => m.title).toSet();
      expect(milestoneTitles.contains('衣装合わせ'), isTrue);
      expect(milestoneTitles.contains('招待状発送'), isTrue);
      expect(milestoneTitles.contains('最終打合せ'), isTrue);
    });

    test('生成されたマイルストーンの parentEventId が親の id と一致すること', () async {
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
          .addEventFromCatalog(catalog, '2027-06');

      final parent = savedEvents.firstWhere((e) => e.kind == EventKind.event);
      final milestones = savedEvents.where((e) => e.kind == EventKind.milestone).toList();

      expect(milestones.every((m) => m.parentEventId == parent.id), isTrue);
    });
  });

  group('シナリオB: hard違反チェック（propose未配置でwedding-ceremony配置）', () {
    test('venue-decision が未配置のとき wedding-ceremony に hard違反が検出されること', () {
      // プロポーズと式場決定なしに結婚式を配置した状態
      const weddingEvent = LifeEvent(
        id: 'wedding-1',
        catalogId: 'wedding-ceremony',
        date: '2027-06',
        title: '結婚式',
        description: '',
        kind: EventKind.event,
      );

      final events = [weddingEvent];
      final catalog = PredefinedCatalogRegistry.findById('wedding-ceremony')!;

      // hard違反: venue-decision が配置済みイベントにない
      final placedCatalogIds = events.map((e) => e.catalogId).toSet();
      final hardViolations = catalog.hardRules
          .where((rule) => !placedCatalogIds.contains(rule.predecessorCatalogId))
          .toList();

      expect(hardViolations, isNotEmpty);
      expect(
        hardViolations.any((v) => v.predecessorCatalogId == 'venue-decision'),
        isTrue,
      );
    });

    test('venue-decision が配置済みのとき wedding-ceremony の hard違反が0件になること', () {
      const venueEvent = LifeEvent(
        id: 'venue-1',
        catalogId: 'venue-decision',
        date: '2026-12',
        title: '結婚式場決定',
        description: '',
        kind: EventKind.event,
      );
      const weddingEvent = LifeEvent(
        id: 'wedding-1',
        catalogId: 'wedding-ceremony',
        date: '2027-06',
        title: '結婚式',
        description: '',
        kind: EventKind.event,
      );

      final events = [venueEvent, weddingEvent];
      final catalog = PredefinedCatalogRegistry.findById('wedding-ceremony')!;

      final placedCatalogIds = events.map((e) => e.catalogId).toSet();
      final hardViolations = catalog.hardRules
          .where((rule) => !placedCatalogIds.contains(rule.predecessorCatalogId))
          .toList();

      expect(hardViolations, isEmpty);
    });

    test('checkAllConstraints はConstraintResultリストを返し、hard違反がないこと（C-01/C-02のみ）', () {
      // wedding-ceremony に関連するハード違反はcheckAllConstraints では検知されない
      // (C-01/C-02はjob-change/childbirthの制約)
      const weddingEvent = LifeEvent(
        id: 'wedding-1',
        catalogId: 'wedding-ceremony',
        date: '2027-06',
        title: '結婚式',
        description: '',
      );

      final results = checkAllConstraints([weddingEvent]);
      // wedding-ceremony単独でC-01/C-02は発生しないこと
      expect(results.where((r) => r.ruleId == 'C-01' || r.ruleId == 'C-02'), isEmpty);
    });
  });

  group('シナリオC: 合計予算計算', () {
    late MockEventRepository mockRepository;

    setUp(() {
      mockRepository = MockEventRepository();
    });

    ProviderContainer createContainer(List<LifeEvent> events) {
      when(() => mockRepository.fetchEvents()).thenAnswer((_) async => events);
      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('wedding-ceremony(¥300万)とhoneymoon(¥50万)を追加するとtotalBudgetProviderが3,500,000を返すこと',
        () async {
      final events = [
        const LifeEvent(
          id: 'wedding-1',
          catalogId: 'wedding-ceremony',
          date: '2027-06',
          title: '結婚式',
          description: '',
          budgetYen: 3000000,
        ),
        const LifeEvent(
          id: 'honeymoon-1',
          catalogId: 'honeymoon',
          date: '2027-09',
          title: '新婚旅行',
          description: '',
          budgetYen: 500000,
        ),
      ];

      final container = createContainer(events);
      await container.read(timelineEventsProvider.future);

      final total = container.read(budgetSummaryProvider);
      expect(total, equals(3500000));
    });

    test('budgetYenがnullのとき catalog.defaultBudgetYen が使われ合計が正しいこと', () async {
      // wedding-ceremony: defaultBudgetYen=3000000, honeymoon: defaultBudgetYen=500000
      final events = [
        const LifeEvent(
          id: 'wedding-1',
          catalogId: 'wedding-ceremony',
          date: '2027-06',
          title: '結婚式',
          description: '',
          // budgetYen is null → catalog default 3000000 が使われる
        ),
        const LifeEvent(
          id: 'honeymoon-1',
          catalogId: 'honeymoon',
          date: '2027-09',
          title: '新婚旅行',
          description: '',
          // budgetYen is null → catalog default 500000 が使われる
        ),
      ];

      final container = createContainer(events);
      await container.read(timelineEventsProvider.future);

      final total = container.read(budgetSummaryProvider);
      expect(total, equals(3500000));
    });

    test('イベントが0件のとき合計が0であること', () async {
      final container = createContainer([]);
      await container.read(timelineEventsProvider.future);

      final total = container.read(budgetSummaryProvider);
      expect(total, equals(0));
    });
  });
}
