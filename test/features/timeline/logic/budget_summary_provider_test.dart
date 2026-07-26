import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/budget_summary_provider.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';

import '../../../support/mocks.dart';
import '../../../support/pump.dart';

void main() {
  setUpAll(registerCommonFallbackValues);

  group('budgetSummaryProvider', () {
    ProviderContainer createContainer(List<LifeEvent> events) {
      return createContainerWithRepositories(events: events);
    }

    test('budgetSummaryProvider が複数イベントの合計を正しく返すこと', () async {
      // wedding-ceremony: defaultBudgetYen=3000000
      // joining-company: defaultBudgetYen=null（0）
      final events = [
        const LifeEvent(
          id: 'e1',
          catalogId: 'wedding-ceremony',
          date: '2026-06',
          title: '結婚式',
          description: '',
          budgetYen: 3000000,
        ),
        const LifeEvent(
          id: 'e2',
          catalogId: 'joining-company',
          date: '2020-04',
          title: '入社',
          description: '',
          // budgetYen null: defaultBudgetYenもnull → 0
        ),
      ];
      final container = createContainer(events);
      await container.read(timelineEventsProvider.future);

      final total = container.read(budgetSummaryProvider);
      expect(total, equals(3000000));
    });

    test('budgetSummaryProvider: budgetYenがnullのときcatalogのdefaultBudgetYenが使われること',
        () async {
      // propose: defaultBudgetYen=400000
      final events = [
        const LifeEvent(
          id: 'e1',
          catalogId: 'propose',
          date: '2025-01',
          title: 'プロポーズ',
          description: '',
          // budgetYen は null → catalog の 400000 が使われる
        ),
      ];
      final container = createContainer(events);
      await container.read(timelineEventsProvider.future);

      final total = container.read(budgetSummaryProvider);
      expect(total, equals(400000));
    });

    test('budgetSummaryProvider: イベントが0件のとき0を返すこと', () async {
      final container = createContainer([]);
      await container.read(timelineEventsProvider.future);

      final total = container.read(budgetSummaryProvider);
      expect(total, equals(0));
    });
  });
}
