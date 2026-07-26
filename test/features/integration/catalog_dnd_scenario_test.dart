import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/catalog/data/predefined_catalog_registry.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/budget_summary_provider.dart';
import 'package:my_career_app/features/timeline/logic/constraint_checker_provider.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';

import '../../support/mocks.dart';
import '../../support/pump.dart' as support;

void main() {
  setUpAll(registerCommonFallbackValues);

  group('シナリオA: 結婚式を配置するとカタログから単一イベントが生成される', () {
    late MockEventRepository mockRepository;

    setUp(() {
      mockRepository = stubEventRepository();
    });

    ProviderContainer createContainer() {
      return support.createContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    }

    test('addEventFromCatalog(weddingCeremony) で1件のイベントが生成されること', () async {
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

      // マイルストーン機能廃止後はカタログから1件のみ生成される
      expect(savedEvents.length, equals(1));
      expect(savedEvents.single.catalogId, equals('wedding-ceremony'));
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
      );
      const weddingEvent = LifeEvent(
        id: 'wedding-1',
        catalogId: 'wedding-ceremony',
        date: '2027-06',
        title: '結婚式',
        description: '',
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
    ProviderContainer createContainer(List<LifeEvent> events) {
      return support.createContainerWithRepositories(events: events);
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
