import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/constraint_result.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/constraint_checker_provider.dart';

/// テスト用ヘルパー: LifeEventを簡潔に生成する
LifeEvent _event({
  required String date,
  required String title,
  required EventCategory category,
}) {
  return LifeEvent(
    id: 'test-${date.replaceAll('-', '')}-${category.name}',
    date: date,
    title: title,
    description: '',
    category: category,
  );
}

void main() {
  group('C-01: 転職から1年未満に出産/産休イベントがある場合の警告', () {
    test('TS-L-010: 転職(2025-01) + 出産(2025-07) で C-01 warning が出ること', () {
      final events = [
        _event(date: '2025-01', title: '転職', category: EventCategory.jobChange),
        _event(date: '2025-07', title: '出産', category: EventCategory.childbirth),
      ];

      final results = checkAllConstraints(events);

      expect(results.length, greaterThanOrEqualTo(1));
      expect(
        results.any((r) => r.ruleId == 'C-01' && r.severity == ConstraintSeverity.warning),
        isTrue,
      );
    });

    test('TS-L-011: 転職(2025-01) + 産休(2025-12) で C-01 warning が出ること', () {
      final events = [
        _event(date: '2025-01', title: '転職', category: EventCategory.jobChange),
        _event(date: '2025-12', title: '産休', category: EventCategory.maternityLeave),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01' && r.severity == ConstraintSeverity.warning),
        isTrue,
      );
    });

    test('TS-L-012: 転職(2025-01) + 出産(2026-02) で警告なしであること', () {
      final events = [
        _event(date: '2025-01', title: '転職', category: EventCategory.jobChange),
        _event(date: '2026-02', title: '出産', category: EventCategory.childbirth),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01'),
        isFalse,
      );
    });

    test('TS-L-013: 転職(2025-01) + 出産(2026-01) で警告なしであること（ちょうど12ヶ月はOK）', () {
      final events = [
        _event(date: '2025-01', title: '転職', category: EventCategory.jobChange),
        _event(date: '2026-01', title: '出産', category: EventCategory.childbirth),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01'),
        isFalse,
      );
    });

    test('TS-L-015: 出産(2024-06) + 転職(2025-01) で出産が先なので警告なしであること', () {
      final events = [
        _event(date: '2024-06', title: '出産', category: EventCategory.childbirth),
        _event(date: '2025-01', title: '転職', category: EventCategory.jobChange),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01'),
        isFalse,
      );
    });
  });

  group('C-02: 出産予定があるが1年以上前に転職なしの場合の情報', () {
    test('TS-L-020: 出産(2026-06) のみで C-02 info が出ること', () {
      final events = [
        _event(date: '2026-06', title: '出産', category: EventCategory.childbirth),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-02' && r.severity == ConstraintSeverity.info),
        isTrue,
      );
    });

    test('TS-L-021: 転職(2026-01) + 出産(2026-06) で C-02 info が出ること（1年未満の転職のみ）', () {
      final events = [
        _event(date: '2026-01', title: '転職', category: EventCategory.jobChange),
        _event(date: '2026-06', title: '出産', category: EventCategory.childbirth),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-02' && r.severity == ConstraintSeverity.info),
        isTrue,
      );
    });

    test('TS-L-022: 転職(2025-01) + 出産(2026-06) で情報なしであること', () {
      final events = [
        _event(date: '2025-01', title: '転職', category: EventCategory.jobChange),
        _event(date: '2026-06', title: '出産', category: EventCategory.childbirth),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-02'),
        isFalse,
      );
    });

    test('TS-L-023: 転職(2025-06) + 出産(2026-06) で情報なしであること（ちょうど12ヶ月はOK）', () {
      final events = [
        _event(date: '2025-06', title: '転職', category: EventCategory.jobChange),
        _event(date: '2026-06', title: '出産', category: EventCategory.childbirth),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-02'),
        isFalse,
      );
    });
  });

  group('複合テスト', () {
    test('TS-L-030: 空のイベントリストで空リストが返ること', () {
      final results = checkAllConstraints([]);

      expect(results, isEmpty);
    });

    test('TS-L-031: 結婚 + 昇進のみで空リストが返ること', () {
      final events = [
        _event(date: '2025-06', title: '結婚', category: EventCategory.marriage),
        _event(date: '2025-08', title: '昇進', category: EventCategory.promotion),
      ];

      final results = checkAllConstraints(events);

      expect(results, isEmpty);
    });

    test('TS-L-032: 転職(2026-01) + 出産(2026-06) で C-01 warning と C-02 info の両方が出ること', () {
      final events = [
        _event(date: '2026-01', title: '転職', category: EventCategory.jobChange),
        _event(date: '2026-06', title: '出産', category: EventCategory.childbirth),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01' && r.severity == ConstraintSeverity.warning),
        isTrue,
      );
      expect(
        results.any((r) => r.ruleId == 'C-02' && r.severity == ConstraintSeverity.info),
        isTrue,
      );
    });

    test('TS-L-037: 転職(2025-01) + 産休(2025-08) で C-01 warning が出ること', () {
      final events = [
        _event(date: '2025-01', title: '転職', category: EventCategory.jobChange),
        _event(date: '2025-08', title: '産休', category: EventCategory.maternityLeave),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01' && r.severity == ConstraintSeverity.warning),
        isTrue,
      );
    });
  });
}
