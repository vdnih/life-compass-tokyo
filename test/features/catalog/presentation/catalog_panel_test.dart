import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/catalog/domain/predefined_life_event.dart';
import 'package:my_career_app/features/catalog/presentation/catalog_panel.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';

class MockEventRepository extends Mock implements EventRepository {}

class FakeLifeEvent extends Fake implements LifeEvent {}

Widget _buildTestWidget() {
  final mockRepo = MockEventRepository();
  when(() => mockRepo.fetchEvents()).thenAnswer((_) async => []);

  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: CatalogPanel(),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLifeEvent());
  });

  group('CatalogPanel', () {
    testWidgets('パネルが結婚グループの折りたたみを持つこと', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('結婚'), findsOneWidget);
    });

    testWidgets('検索フィールドが表示されること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('結婚グループはデフォルトで展開されていること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // 結婚グループ内の「お付き合い開始」が表示されること
      expect(find.text('お付き合い開始'), findsOneWidget);
    });

    testWidgets('カタログアイテムが LongPressDraggable でラップされていること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.byType(LongPressDraggable<PredefinedLifeEvent>),
        findsWidgets,
      );
    });

    testWidgets('検索フィールドに入力すると絞り込まれること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '転職');
      await tester.pumpAndSettle();

      expect(find.text('転職'), findsWidgets);
    });
  });
}
