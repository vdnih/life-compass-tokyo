import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';
import 'package:my_career_app/features/timeline/presentation/timeline_screen.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/year_month_timeline.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/year_timeline.dart';

class _StubEventsNotifier extends TimelineEventsNotifier {
  @override
  Future<List<LifeEvent>> build() async => const [
    LifeEvent(
      date: '2020-01',
      title: 'テストイベント',
      description: '',
      category: EventCategory.joining,
    ),
  ];
}

Widget _buildTestWidget() {
  return ProviderScope(
    overrides: [
      timelineEventsProvider.overrideWith(() => _StubEventsNotifier()),
    ],
    child: const MaterialApp(home: TimelineScreen()),
  );
}

void main() {
  group('TimelineScreen の機能一覧（仕様）', () {
    testWidgets('デフォルトは年月表示であること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(YearMonthTimeline), findsOneWidget);
      expect(find.byType(YearTimeline), findsNothing);
    });

    testWidgets('「年」ボタンをタップすると年表示に切り替わること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      expect(find.byType(YearTimeline), findsOneWidget);
      expect(find.byType(YearMonthTimeline), findsNothing);
    });

    testWidgets('「年月」ボタンをタップすると年月表示に戻ること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('年月'));
      await tester.pumpAndSettle();

      expect(find.byType(YearMonthTimeline), findsOneWidget);
      expect(find.byType(YearTimeline), findsNothing);
    });
  });
}
