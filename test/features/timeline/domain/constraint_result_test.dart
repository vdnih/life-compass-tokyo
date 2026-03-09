import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/constraint_result.dart';

void main() {
  group('ConstraintSeverity の仕様', () {
    test('values が warning と info の2つであること', () {
      expect(ConstraintSeverity.values.length, 2);
      expect(
        ConstraintSeverity.values,
        contains(ConstraintSeverity.warning),
      );
      expect(
        ConstraintSeverity.values,
        contains(ConstraintSeverity.info),
      );
    });
  });

  group('ConstraintResult の仕様', () {
    test('warning の ConstraintResult が正しく生成されること', () {
      const result = ConstraintResult(
        ruleId: 'C-01',
        targetEventTitle: '出産',
        relatedEventTitle: '転職',
        severity: ConstraintSeverity.warning,
        message: 'テスト警告メッセージ',
      );

      expect(result.ruleId, 'C-01');
      expect(result.targetEventTitle, '出産');
      expect(result.relatedEventTitle, '転職');
      expect(result.severity, ConstraintSeverity.warning);
      expect(result.message, 'テスト警告メッセージ');
    });

    test('info の ConstraintResult が正しく生成されること', () {
      const result = ConstraintResult(
        ruleId: 'C-02',
        targetEventTitle: '出産予定',
        severity: ConstraintSeverity.info,
        message: 'テスト情報メッセージ',
      );

      expect(result.ruleId, 'C-02');
      expect(result.targetEventTitle, '出産予定');
      expect(result.relatedEventTitle, isNull);
      expect(result.severity, ConstraintSeverity.info);
      expect(result.message, 'テスト情報メッセージ');
    });

    test('同じパラメータの2つの ConstraintResult が等しいこと', () {
      const result1 = ConstraintResult(
        ruleId: 'C-01',
        targetEventTitle: '出産',
        relatedEventTitle: '転職',
        severity: ConstraintSeverity.warning,
        message: 'メッセージ',
      );
      const result2 = ConstraintResult(
        ruleId: 'C-01',
        targetEventTitle: '出産',
        relatedEventTitle: '転職',
        severity: ConstraintSeverity.warning,
        message: 'メッセージ',
      );

      expect(result1, equals(result2));
    });

    test('異なるパラメータの ConstraintResult は等しくないこと', () {
      const result1 = ConstraintResult(
        ruleId: 'C-01',
        targetEventTitle: '出産',
        severity: ConstraintSeverity.warning,
        message: 'メッセージA',
      );
      const result2 = ConstraintResult(
        ruleId: 'C-02',
        targetEventTitle: '出産',
        severity: ConstraintSeverity.info,
        message: 'メッセージB',
      );

      expect(result1, isNot(equals(result2)));
    });
  });
}
