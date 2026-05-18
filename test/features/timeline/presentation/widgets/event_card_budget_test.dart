import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/event_card.dart';

void main() {
  group('EventCard 予算表示', () {
    testWidgets('budgetYen=3000000 を渡すと ¥300万 が表示されること', (tester) async {
      const event = LifeEvent(
        id: 'e1',
        catalogId: 'wedding-ceremony',
        date: '2026-06',
        title: '結婚式',
        description: '',
        budgetYen: 3000000,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EventCard(event: event),
            ),
          ),
        ),
      );

      expect(find.text('¥300万'), findsOneWidget);
    });

    testWidgets('budgetYen=50000 のとき（10万未満）¥50000円 が表示されること', (tester) async {
      const event = LifeEvent(
        id: 'e2',
        catalogId: 'propose',
        date: '2025-01',
        title: 'プロポーズ',
        description: '',
        budgetYen: 50000,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EventCard(event: event),
            ),
          ),
        ),
      );

      expect(find.text('¥50000円'), findsOneWidget);
    });

    testWidgets('budgetYen=null かつ catalog.defaultBudgetYen が存在するとき、グレーテキストで表示されること',
        (tester) async {
      // propose の defaultBudgetYen = 400000
      const event = LifeEvent(
        id: 'e3',
        catalogId: 'propose',
        date: '2025-01',
        title: 'プロポーズ',
        description: '',
        // budgetYen は null
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EventCard(event: event),
            ),
          ),
        ),
      );

      // デフォルト予算として ¥40万 が表示される
      expect(find.text('¥40万'), findsOneWidget);
    });

    testWidgets('budgetYen=null かつ catalog.defaultBudgetYen も null のとき予算は表示されないこと',
        (tester) async {
      // joining-company の defaultBudgetYen = null
      const event = LifeEvent(
        id: 'e4',
        catalogId: 'joining-company',
        date: '2020-04',
        title: '入社',
        description: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EventCard(event: event),
            ),
          ),
        ),
      );

      // 「万」が含まれるテキストは表示されないこと
      expect(find.textContaining('万'), findsNothing);
      expect(find.textContaining('円'), findsNothing);
    });
  });
}
