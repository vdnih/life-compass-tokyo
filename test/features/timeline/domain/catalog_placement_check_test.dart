import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/catalog/domain/predefined_life_event.dart';
import 'package:my_career_app/features/timeline/domain/catalog_placement_check.dart';
import 'package:my_career_app/features/timeline/domain/year_month.dart';

import '../../../support/builders.dart';

void main() {
  const catalogWithHardRule = PredefinedLifeEvent(
    id: 'childbirth',
    label: '出産',
    group: LifeEventGroup.childbirth,
    icon: Icons.event,
    color: Colors.pink,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'marriage',
        minMonthsAfter: 6,
        message: '結婚から6ヶ月以上あけてください',
      ),
    ],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'job-change',
        recommendedMinMonthsAfter: 12,
        message: '転職から1年以上経過していると安心です',
      ),
    ],
  );

  group('checkCatalogPlacement', () {
    test('先行イベントが無ければ hard 違反になること', () {
      final violation = checkCatalogPlacement(
        catalog: catalogWithHardRule,
        at: const YearMonth(2025, 1),
        events: const [],
      );
      expect(violation?.severity, CatalogPlacementSeverity.hard);
    });

    test('先行イベントからの経過月数が足りなければ hard 違反になること', () {
      final events = [
        buildLifeEvent(id: 'm', catalogId: 'marriage', date: '2025-01'),
      ];
      final violation = checkCatalogPlacement(
        catalog: catalogWithHardRule,
        at: const YearMonth(2025, 4), // 3ヶ月後 < 6ヶ月
        events: events,
      );
      expect(violation?.severity, CatalogPlacementSeverity.hard);
    });

    test('hard ルールを満たし soft ルールを満たさなければ soft 違反になること', () {
      final events = [
        buildLifeEvent(id: 'm', catalogId: 'marriage', date: '2024-01'),
      ];
      final violation = checkCatalogPlacement(
        catalog: catalogWithHardRule,
        at: const YearMonth(2024, 8), // hard は満たすが job-change 先行が無い
        events: events,
      );
      expect(violation?.severity, CatalogPlacementSeverity.soft);
    });

    test('hard・soft を両方満たせば違反なし（null）になること', () {
      final events = [
        buildLifeEvent(id: 'm', catalogId: 'marriage', date: '2024-01'),
        buildLifeEvent(id: 'j', catalogId: 'job-change', date: '2023-01'),
      ];
      final violation = checkCatalogPlacement(
        catalog: catalogWithHardRule,
        at: const YearMonth(2024, 8),
        events: events,
      );
      expect(violation, isNull);
    });

    test('hard 違反がある場合は soft 違反より優先して報告されること', () {
      // marriage も job-change も先行しないので、hard・soft 両方が違反しうる
      final violation = checkCatalogPlacement(
        catalog: catalogWithHardRule,
        at: const YearMonth(2025, 1),
        events: const [],
      );
      expect(violation?.severity, CatalogPlacementSeverity.hard);
    });
  });
}
