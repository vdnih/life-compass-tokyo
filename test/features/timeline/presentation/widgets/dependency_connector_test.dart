import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/dependency_connector.dart';

void main() {
  group('DependencyConnector', () {
    testWidgets('依存関係がない場合でもエラーなく描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: DependencyConnector(
                dependencies: const [],
                eventPositions: const {},
                eventLanes: const {},
                totalHeight: 400,
                totalWidth: 800,
                axisHeight: 60,
                rowHeight: 160,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DependencyConnector), findsOneWidget);
    });

    testWidgets('依存関係がある場合にCustomPaintが描画されること', (tester) async {
      const dep = EventDependency(
        id: 'dep-1',
        sourceEventId: 'event-1',
        targetEventId: 'event-2',
        type: DependencyType.prerequisite,
        offsetMonths: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: DependencyConnector(
                dependencies: const [dep],
                eventPositions: const {
                  'event-1': Offset(100, 0),
                  'event-2': Offset(300, 0),
                },
                eventLanes: const {'event-1': true, 'event-2': true},
                totalHeight: 400,
                totalWidth: 800,
                axisHeight: 60,
                rowHeight: 160,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeast(1));
    });

    testWidgets('ウィジェットが正しいサイズで描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: DependencyConnector(
                dependencies: const [],
                eventPositions: const {},
                eventLanes: const {},
                totalHeight: 400,
                totalWidth: 800,
                axisHeight: 60,
                rowHeight: 160,
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(DependencyConnector));
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });
  });

  group('DependencyLinePainter', () {
    test('DependencyLinePainterがインスタンス化できること', () {
      const dep = EventDependency(
        id: 'dep-1',
        sourceEventId: 'event-1',
        targetEventId: 'event-2',
        type: DependencyType.prerequisite,
        offsetMonths: 3,
      );

      final painter = DependencyLinePainter(
        dependencies: const [dep],
        eventPositions: const {
          'event-1': Offset(100, 0),
          'event-2': Offset(300, 0),
        },
        eventLanes: const {'event-1': true, 'event-2': true},
        axisHeight: 60,
        rowHeight: 160,
      );

      expect(painter, isNotNull);
    });

    test('shouldRepaintが正しく動作すること', () {
      final painter1 = DependencyLinePainter(
        dependencies: const [],
        eventPositions: const {},
        eventLanes: const {},
        axisHeight: 60,
        rowHeight: 160,
      );
      final painter2 = DependencyLinePainter(
        dependencies: const [],
        eventPositions: const {},
        eventLanes: const {},
        axisHeight: 60,
        rowHeight: 160,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('依存関係が変わるとshouldRepaintがtrueを返すこと', () {
      final painter1 = DependencyLinePainter(
        dependencies: const [],
        eventPositions: const {},
        eventLanes: const {},
        axisHeight: 60,
        rowHeight: 160,
      );
      const dep = EventDependency(
        id: 'dep-1',
        sourceEventId: 'event-1',
        targetEventId: 'event-2',
        type: DependencyType.prerequisite,
        offsetMonths: 3,
      );
      final painter2 = DependencyLinePainter(
        dependencies: const [dep],
        eventPositions: const {},
        eventLanes: const {},
        axisHeight: 60,
        rowHeight: 160,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });
}
