import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/constraint_result.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/constraint_checker_provider.dart';

/// テスト用ヘルパー: LifeEventを簡潔に生成する
LifeEvent _event({
  required String date,
  required String title,
  required String catalogId,
  String? endDate,
}) {
  return LifeEvent(
    id: 'test-${date.replaceAll('-', '')}-$catalogId',
    date: date,
    endDate: endDate,
    title: title,
    description: '',
    catalogId: catalogId,
  );
}

void main() {
  group('C-01: 転職から1年未満に出産/産休イベントがある場合の警告', () {
    test('TS-L-010: 転職(2025-01) + 出産(2025-07) で C-01 warning が出ること', () {
      final events = [
        _event(date: '2025-01', title: '転職', catalogId: 'job-change'),
        _event(date: '2025-07', title: '出産', catalogId: 'childbirth'),
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
        _event(date: '2025-01', title: '転職', catalogId: 'job-change'),
        _event(date: '2025-12', title: '産休', catalogId: 'maternity-leave'),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01' && r.severity == ConstraintSeverity.warning),
        isTrue,
      );
    });

    test('TS-L-012: 転職(2025-01) + 出産(2026-02) で警告なしであること', () {
      final events = [
        _event(date: '2025-01', title: '転職', catalogId: 'job-change'),
        _event(date: '2026-02', title: '出産', catalogId: 'childbirth'),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01'),
        isFalse,
      );
    });

    test('TS-L-013: 転職(2025-01) + 出産(2026-01) で警告なしであること（ちょうど12ヶ月はOK）', () {
      final events = [
        _event(date: '2025-01', title: '転職', catalogId: 'job-change'),
        _event(date: '2026-01', title: '出産', catalogId: 'childbirth'),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01'),
        isFalse,
      );
    });

    test('TS-L-015: 出産(2024-06) + 転職(2025-01) で出産が先なので警告なしであること', () {
      final events = [
        _event(date: '2024-06', title: '出産', catalogId: 'childbirth'),
        _event(date: '2025-01', title: '転職', catalogId: 'job-change'),
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
        _event(date: '2026-06', title: '出産', catalogId: 'childbirth'),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-02' && r.severity == ConstraintSeverity.info),
        isTrue,
      );
    });

    test('TS-L-021: 転職(2026-01) + 出産(2026-06) で C-02 info が出ること（1年未満の転職のみ）', () {
      final events = [
        _event(date: '2026-01', title: '転職', catalogId: 'job-change'),
        _event(date: '2026-06', title: '出産', catalogId: 'childbirth'),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-02' && r.severity == ConstraintSeverity.info),
        isTrue,
      );
    });

    test('TS-L-022: 転職(2025-01) + 出産(2026-06) で情報なしであること', () {
      final events = [
        _event(date: '2025-01', title: '転職', catalogId: 'job-change'),
        _event(date: '2026-06', title: '出産', catalogId: 'childbirth'),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-02'),
        isFalse,
      );
    });

    test('TS-L-023: 転職(2025-06) + 出産(2026-06) で情報なしであること（ちょうど12ヶ月はOK）', () {
      final events = [
        _event(date: '2025-06', title: '転職', catalogId: 'job-change'),
        _event(date: '2026-06', title: '出産', catalogId: 'childbirth'),
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
        _event(date: '2025-06', title: '結婚', catalogId: 'marriage-registration'),
        _event(date: '2025-08', title: '昇進', catalogId: 'promotion'),
      ];

      final results = checkAllConstraints(events);

      expect(results, isEmpty);
    });

    test('TS-L-032: 転職(2026-01) + 出産(2026-06) で C-01 warning と C-02 info の両方が出ること', () {
      final events = [
        _event(date: '2026-01', title: '転職', catalogId: 'job-change'),
        _event(date: '2026-06', title: '出産', catalogId: 'childbirth'),
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
        _event(date: '2025-01', title: '転職', catalogId: 'job-change'),
        _event(date: '2025-08', title: '産休', catalogId: 'maternity-leave'),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-01' && r.severity == ConstraintSeverity.warning),
        isTrue,
      );
    });
  });

  group('C-03: 依存関係のオフセット期間が確保されていない場合の警告', () {
    test('C-03: オフセット違反がある場合に警告が出ること', () {
      // _event() generates id as 'test-${date.replaceAll('-', '')}-$catalogId'
      // For date='2025-01', catalogId='job-change' → 'test-202501-job-change'
      final events = [
        _event(date: '2025-01', title: '転職タイミングの目安', catalogId: 'job-change'),
        _event(date: '2025-06', title: '出産', catalogId: 'childbirth'),
      ];
      const sourceId = 'test-202501-job-change';
      const targetId = 'test-202506-childbirth';
      final dependencies = [
        const EventDependency(
          id: 'dep-1',
          sourceEventId: sourceId,
          targetEventId: targetId,
          offsetMonths: 3,
        ),
      ];

      // source(2025-01) + 3ヶ月 = 2025-04 ≠ target(2025-06) → 違反
      final results = checkAllConstraints(events, dependencies);

      expect(
        results.any((r) => r.ruleId == 'C-03' && r.severity == ConstraintSeverity.warning),
        isTrue,
      );
    });

    test('C-03: オフセットが正確に守られている場合は警告が出ないこと', () {
      final events = [
        _event(date: '2025-01', title: '転職タイミングの目安', catalogId: 'job-change'),
        _event(date: '2025-04', title: '出産', catalogId: 'childbirth'),
      ];
      const sourceId = 'test-202501-job-change';
      const targetId = 'test-202504-childbirth';
      final dependencies = [
        const EventDependency(
          id: 'dep-1',
          sourceEventId: sourceId,
          targetEventId: targetId,
          offsetMonths: 3,
        ),
      ];

      // source(2025-01) + 3ヶ月 = 2025-04 == target(2025-04) → 問題なし
      final results = checkAllConstraints(events, dependencies);

      expect(
        results.any((r) => r.ruleId == 'C-03'),
        isFalse,
      );
    });

    test('C-03: 依存関係が空の場合は C-03 警告が出ないこと', () {
      final events = [
        _event(date: '2025-01', title: 'イベントA', catalogId: 'job-change'),
        _event(date: '2025-06', title: 'イベントB', catalogId: 'childbirth'),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any((r) => r.ruleId == 'C-03'),
        isFalse,
      );
    });

    test('C-03: 年境界をまたぐオフセットが正確に守られている場合は警告が出ないこと', () {
      final events = [
        _event(date: '2025-11', title: 'イベントA', catalogId: 'job-change'),
        _event(date: '2026-01', title: 'イベントB', catalogId: 'childbirth'),
      ];
      const sourceId = 'test-202511-job-change';
      const targetId = 'test-202601-childbirth';
      final dependencies = [
        const EventDependency(
          id: 'dep-1',
          sourceEventId: sourceId,
          targetEventId: targetId,
          offsetMonths: 2,
        ),
      ];

      // source(2025-11) + 2ヶ月 = 2026-01 == target(2026-01) → 問題なし
      final results = checkAllConstraints(events, dependencies);

      expect(
        results.any((r) => r.ruleId == 'C-03'),
        isFalse,
      );
    });

    test('C-03: 警告メッセージにソースイベント名とターゲットイベント名が含まれること', () {
      final events = [
        _event(date: '2025-01', title: '転職タイミングの目安', catalogId: 'job-change'),
        _event(date: '2025-06', title: '出産予定', catalogId: 'childbirth'),
      ];
      const sourceId = 'test-202501-job-change';
      const targetId = 'test-202506-childbirth';
      final dependencies = [
        const EventDependency(
          id: 'dep-1',
          sourceEventId: sourceId,
          targetEventId: targetId,
          offsetMonths: 3,
        ),
      ];

      final results = checkAllConstraints(events, dependencies);
      final c03Result = results.firstWhere((r) => r.ruleId == 'C-03');

      expect(c03Result.message, contains('転職タイミングの目安'));
      expect(c03Result.message, contains('出産予定'));
      expect(c03Result.message, contains('3'));
    });
  });

  group('open_data feature の制度上限（B1, PDR-008）との合流', () {
    test('育休(12ヶ月, 既定値)を含むイベント列で制度上限の info が返ること', () {
      final events = [
        _event(
          date: '2026-01',
          endDate: '2027-01',
          title: '育休',
          catalogId: 'childcare-leave',
        ),
      ];

      final results = checkAllConstraints(events);

      expect(
        results.any(
          (r) =>
              r.ruleId == 'IL-childcare-leave' &&
              r.severity == ConstraintSeverity.info,
        ),
        isTrue,
      );
    });
  });
}
