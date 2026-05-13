import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/milestone_chip.dart';

void main() {
  const testMilestone = LifeEvent(
    id: 'milestone-1',
    catalogId: 'wedding-ceremony',
    parentEventId: 'parent-1',
    kind: EventKind.milestone,
    date: '2026-03',
    title: '衣装合わせ',
    description: '',
  );

  group('MilestoneChip', () {
    testWidgets('MilestoneChip がラベルを表示すること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneChip(
              milestone: testMilestone,
              parentColor: const Color(0xFFD4698F),
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('衣装合わせ'), findsOneWidget);
    });

    testWidgets('MilestoneChip の高さが EventCard より小さいこと', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneChip(
              milestone: testMilestone,
              parentColor: const Color(0xFFD4698F),
              onDelete: () {},
            ),
          ),
        ),
      );

      final chipFinder = find.byType(MilestoneChip);
      final renderBox =
          tester.renderObject(chipFinder) as RenderBox;
      // EventCard の高さは 84px (50px card + 4px gap + 20px icon + 10px status)
      // MilestoneChip は 24px 程度なのでそれより小さい
      expect(renderBox.size.height, lessThan(60.0));
    });

    testWidgets('MilestoneChip をタップすると削除確認ダイアログが表示されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneChip(
              milestone: testMilestone,
              parentColor: const Color(0xFFD4698F),
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MilestoneChip));
      await tester.pumpAndSettle();

      expect(find.text('マイルストーンを削除'), findsOneWidget);
    });
  });
}
