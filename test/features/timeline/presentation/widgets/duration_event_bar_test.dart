import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/constraint_result.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/duration_event_bar.dart';

void main() {
  const testEvent = LifeEvent(
    id: 'test-duration-event',
    catalogId: 'childcare-leave',
    date: '2026-03',
    endDate: '2027-03',
    title: '育休',
    description: '',
    status: EventStatus.planned,
  );

  group('DurationEventBar', () {
    testWidgets('エラーなくレンダリングされること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DurationEventBar(
                event: testEvent,
                barWidth: 120,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DurationEventBar), findsOneWidget);
    });

    testWidgets('イベントタイトルが表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DurationEventBar(
                event: testEvent,
                barWidth: 120,
              ),
            ),
          ),
        ),
      );

      expect(find.text('育休'), findsOneWidget);
    });

    testWidgets('barWidth が Container の幅に適用されること', (tester) async {
      const barWidth = 200.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DurationEventBar(
                event: testEvent,
                barWidth: barWidth,
              ),
            ),
          ),
        ),
      );

      // barWidth が clamp(30, infinity) = 200 のまま渡ること
      final containerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == barWidth,
      );
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('barWidth が 30 未満の場合は 30 にクランプされること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DurationEventBar(
                event: testEvent,
                barWidth: 10,
              ),
            ),
          ),
        ),
      );

      // クランプ後に 30.0 が適用されること
      final containerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 30.0,
      );
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('警告がない場合、警告バッジが表示されないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DurationEventBar(
                event: testEvent,
                barWidth: 120,
                eventConstraints: [],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_rounded), findsNothing);
    });

    testWidgets('警告がある場合、警告バッジが表示されること', (tester) async {
      const constraint = ConstraintResult(
        ruleId: 'C-01',
        targetEventTitle: '育休',
        severity: ConstraintSeverity.warning,
        message: 'テスト警告',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DurationEventBar(
                event: testEvent,
                barWidth: 120,
                eventConstraints: [constraint],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('将来計画イベントの場合、ステータスラベルが表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DurationEventBar(
                event: testEvent,
                barWidth: 120,
              ),
            ),
          ),
        ),
      );

      // status が planned なので '予定' ラベルが表示されること
      expect(find.text('予定'), findsOneWidget);
    });
  });
}
