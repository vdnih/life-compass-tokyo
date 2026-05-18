import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/constraint_result.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/point_event_marker.dart';

void main() {
  const testEvent = LifeEvent(
    id: 'test-point-event',
    catalogId: 'childbirth',
    kind: EventKind.event,
    date: '2026-03',
    title: '出産',
    description: '',
    status: EventStatus.planned,
  );

  group('PointEventMarker', () {
    testWidgets('エラーなくレンダリングされること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PointEventMarker(event: testEvent),
            ),
          ),
        ),
      );

      expect(find.byType(PointEventMarker), findsOneWidget);
    });

    testWidgets('イベントタイトルが表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PointEventMarker(event: testEvent),
            ),
          ),
        ),
      );

      expect(find.text('出産'), findsOneWidget);
    });

    testWidgets('警告がない場合、警告バッジが表示されないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PointEventMarker(
                event: testEvent,
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
        targetEventTitle: '出産',
        severity: ConstraintSeverity.warning,
        message: 'テスト警告',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PointEventMarker(
                event: testEvent,
                eventConstraints: [constraint],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('isDimmed=true のとき Opacity ウィジェットが含まれること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PointEventMarker(
                event: testEvent,
                isDimmed: true,
              ),
            ),
          ),
        ),
      );

      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsOneWidget);
      final opacity = tester.widget<Opacity>(opacityFinder);
      expect(opacity.opacity, equals(0.3));
    });

    testWidgets('将来計画イベントの場合、ステータスラベルが表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PointEventMarker(event: testEvent),
            ),
          ),
        ),
      );

      // status が planned なので '予定' ラベルが表示されること
      expect(find.text('予定'), findsOneWidget);
    });
  });
}
