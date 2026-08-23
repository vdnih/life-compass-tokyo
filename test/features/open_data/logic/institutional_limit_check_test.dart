import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/open_data/logic/institutional_limit_check.dart';
import 'package:my_career_app/features/timeline/domain/constraint_result.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';

LifeEvent _event({
  required String catalogId,
  required String date,
  String? endDate,
  String title = 'テストイベント',
}) {
  return LifeEvent(
    id: 'test-$catalogId-$date',
    catalogId: catalogId,
    date: date,
    endDate: endDate,
    title: title,
    description: '',
  );
}

void main() {
  group('duration 種別（育休: 上限24ヶ月）', () {
    test('上限未満（12ヶ月）のとき info が発火すること', () {
      final events = [
        _event(catalogId: 'childcare-leave', date: '2026-01', endDate: '2027-01'),
      ];

      final results = checkInstitutionalLimits(events);

      expect(results.length, 1);
      expect(results.first.ruleId, 'IL-childcare-leave');
      expect(results.first.severity, ConstraintSeverity.info);
    });

    test('上限ちょうど（24ヶ月）のとき発火しないこと', () {
      final events = [
        _event(catalogId: 'childcare-leave', date: '2026-01', endDate: '2028-01'),
      ];

      final results = checkInstitutionalLimits(events);

      expect(results, isEmpty);
    });

    test('上限超過（30ヶ月）でも発火せず、ブロックもされないこと（結果は空リスト）', () {
      final events = [
        _event(catalogId: 'childcare-leave', date: '2026-01', endDate: '2028-07'),
      ];

      final results = checkInstitutionalLimits(events);

      expect(results, isEmpty);
    });

    test('endDate が無い（単発扱いの）育休では発火しないこと', () {
      final events = [
        _event(catalogId: 'childcare-leave', date: '2026-01'),
      ];

      final results = checkInstitutionalLimits(events);

      expect(results, isEmpty);
    });
  });

  group('window 種別（出産: 産後ケア事業は出産から12ヶ月以内）', () {
    test('出産イベントがあれば info が発火すること', () {
      final events = [
        _event(catalogId: 'childbirth', date: '2026-01'),
      ];

      final results = checkInstitutionalLimits(events);

      expect(results.length, 1);
      expect(results.first.ruleId, 'IL-postpartum-care');
      expect(results.first.severity, ConstraintSeverity.info);
    });
  });

  test('該当する制度上限が無い catalogId では何も出ないこと', () {
    final events = [
      _event(catalogId: 'job-change', date: '2026-01'),
    ];

    final results = checkInstitutionalLimits(events);

    expect(results, isEmpty);
  });

  test('出典情報（sourceLabel / sourceUrl）が結果に含まれること', () {
    final events = [
      _event(catalogId: 'childcare-leave', date: '2026-01', endDate: '2027-01'),
    ];

    final result = checkInstitutionalLimits(events).first;

    expect(result.sourceLabel, isNotNull);
    expect(result.sourceUrl, isNotNull);
  });
}
