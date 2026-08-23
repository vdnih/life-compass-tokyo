import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/constraint_result.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/constraint_warning.dart';

void main() {
  group('ConstraintWarningList の仕様', () {
    testWidgets('TS-P-020: Warning種別の制約結果が正しく表示されること', (
      tester,
    ) async {
      const constraint = ConstraintResult(
        ruleId: 'C-01',
        targetEventTitle: '出産',
        relatedEventTitle: '転職',
        severity: ConstraintSeverity.warning,
        message: '転職から1年未満のため、育休が取得できない可能性があります',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstraintWarningList(constraints: [constraint]),
          ),
        ),
      );

      expect(
        find.text('転職から1年未満のため、育休が取得できない可能性があります'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('TS-P-021: Info種別の制約結果が正しく表示されること', (
      tester,
    ) async {
      const constraint = ConstraintResult(
        ruleId: 'C-02',
        targetEventTitle: '出産',
        severity: ConstraintSeverity.info,
        message: '転職から1年以上経過していると、育休取得の条件を満たしやすくなります',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstraintWarningList(constraints: [constraint]),
          ),
        ),
      );

      expect(
        find.text('転職から1年以上経過していると、育休取得の条件を満たしやすくなります'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('TS-P-022: 空リストの場合、何も表示されないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstraintWarningList(constraints: []),
          ),
        ),
      );

      expect(find.byType(ConstraintWarningList), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('TS-P-023: 複数の制約結果がある場合、すべて表示されること', (
      tester,
    ) async {
      const constraints = [
        ConstraintResult(
          ruleId: 'C-01',
          targetEventTitle: '出産',
          severity: ConstraintSeverity.warning,
          message: '警告メッセージ',
        ),
        ConstraintResult(
          ruleId: 'C-02',
          targetEventTitle: '出産',
          severity: ConstraintSeverity.info,
          message: '情報メッセージ',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstraintWarningList(constraints: constraints),
          ),
        ),
      );

      expect(find.text('警告メッセージ'), findsOneWidget);
      expect(find.text('情報メッセージ'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('TS-P-024: sourceLabel を持つ制約結果で出典行が表示されること（PDR-008）', (
      tester,
    ) async {
      const constraint = ConstraintResult(
        ruleId: 'IL-childcare-leave',
        targetEventTitle: '育休',
        severity: ConstraintSeverity.info,
        message: '育児休業は、お子さんが2歳になるまで延長できます。',
        sourceLabel: '出典: 育児・介護休業法（厚生労働省）',
        sourceUrl: 'https://example.com',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstraintWarningList(constraints: [constraint]),
          ),
        ),
      );

      expect(find.text('出典: 育児・介護休業法（厚生労働省）'), findsOneWidget);
    });

    testWidgets('TS-P-025: sourceLabel が無い制約結果では出典行が表示されないこと', (
      tester,
    ) async {
      const constraint = ConstraintResult(
        ruleId: 'C-02',
        targetEventTitle: '出産',
        severity: ConstraintSeverity.info,
        message: '情報メッセージ',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstraintWarningList(constraints: [constraint]),
          ),
        ),
      );

      expect(find.textContaining('出典:'), findsNothing);
    });
  });
}
