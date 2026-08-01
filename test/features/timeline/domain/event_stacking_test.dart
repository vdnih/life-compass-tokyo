import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/event_stacking.dart';
import 'package:my_career_app/features/timeline/domain/timeline_scale.dart';
import 'package:my_career_app/features/timeline/domain/year_month.dart';

import '../../../support/builders.dart';

void main() {
  const monthScale = TimelineScale(
    origin: YearMonth(2025, 1),
    pixelsPerSlot: 60.0,
    monthsPerSlot: 1,
    slotCount: 24,
  );

  group('computeStackIndices', () {
    test('重ならないイベントは同じ段（0）になること', () {
      final events = [
        buildLifeEvent(id: 'a', date: '2025-01'),
        buildLifeEvent(id: 'b', date: '2025-06'),
      ];
      final indices = computeStackIndices(events, monthScale);
      expect(indices['a'], 0);
      expect(indices['b'], 0);
    });

    test('同月に重なるイベントは段が積まれること', () {
      final events = [
        buildLifeEvent(id: 'a', date: '2025-01'),
        buildLifeEvent(id: 'b', date: '2025-01'),
      ];
      final indices = computeStackIndices(events, monthScale);
      expect({indices['a'], indices['b']}, {0, 1});
    });

    test('仕事レーンとプライベートレーンは独立に段積みされること', () {
      final events = [
        buildLifeEvent(id: 'a', date: '2025-01', catalogId: 'joining-company'),
        buildLifeEvent(id: 'b', date: '2025-01', catalogId: 'childbirth'),
      ];
      final indices = computeStackIndices(events, monthScale);
      expect(indices['a'], 0, reason: '仕事レーンのイベントは私生活レーンと重ならない');
      expect(indices['b'], 0);
    });

    test('期間イベントは終了月まで占有し、その間の新規イベントは次の段に積まれること', () {
      final events = [
        buildLifeEvent(id: 'a', date: '2025-01', endDate: '2025-06'),
        buildLifeEvent(id: 'b', date: '2025-03'),
      ];
      final indices = computeStackIndices(events, monthScale);
      expect(indices['a'], 0);
      expect(indices['b'], 1, reason: '期間イベント終了前に開始するので同じ段に置けない');
    });

    test('期間イベントの終了直後に開始するイベントは同じ段に戻れること', () {
      final events = [
        buildLifeEvent(id: 'a', date: '2025-01', endDate: '2025-03'),
        buildLifeEvent(id: 'b', date: '2025-04'),
      ];
      final indices = computeStackIndices(events, monthScale);
      expect(indices['b'], 0);
    });

    test('年ビュー相当のスケール（monthsPerSlot: 12）でも同じ規則で積まれること', () {
      const yearScale = TimelineScale(
        origin: YearMonth(2020, 1),
        pixelsPerSlot: 80.0,
        monthsPerSlot: 12,
        slotCount: 20,
      );
      // 6ヶ月の期間イベントは1スロット（1年）未満なので、
      // 同年内の別イベントは次の段に積まれる（+1.0 はスロット単位であって月数ではない）
      final events = [
        buildLifeEvent(id: 'a', date: '2021-01', endDate: '2021-06'),
        buildLifeEvent(id: 'b', date: '2021-09'),
      ];
      final indices = computeStackIndices(events, yearScale);
      expect(indices['b'], 1);
    });
  });

  group('computeStackedRowHeight', () {
    test('イベントが無ければ minRowHeight になること', () {
      final height = computeStackedRowHeight(
        stackIndices: const {},
        events: const [],
        minRowHeight: 160.0,
        topPadding: 24.0,
        cardHeight: 84.0,
      );
      expect(height, 160.0);
    });

    test('最大段数に応じて高さが伸びること', () {
      final events = [
        buildLifeEvent(id: 'a'),
        buildLifeEvent(id: 'b'),
        buildLifeEvent(id: 'c'),
      ];
      final stackIndices = {'a': 0, 'b': 1, 'c': 2};
      final height = computeStackedRowHeight(
        stackIndices: stackIndices,
        events: events,
        minRowHeight: 160.0,
        topPadding: 24.0,
        cardHeight: 84.0,
      );
      expect(height, 24.0 + 3 * 84.0);
    });

    test('仕事レーンとプライベートレーンのうち、より深い方に合わせること', () {
      final events = [
        buildLifeEvent(id: 'a', catalogId: 'joining-company'),
        buildLifeEvent(id: 'b', catalogId: 'childbirth'),
        buildLifeEvent(id: 'c', catalogId: 'childbirth'),
      ];
      final stackIndices = {'a': 0, 'b': 0, 'c': 1};
      final height = computeStackedRowHeight(
        stackIndices: stackIndices,
        events: events,
        minRowHeight: 160.0,
        topPadding: 24.0,
        cardHeight: 84.0,
      );
      expect(height, 24.0 + 2 * 84.0, reason: 'プライベートレーン側の2段が仕事レーンの1段を上回る');
    });
  });
}
