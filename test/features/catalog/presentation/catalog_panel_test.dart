import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/catalog/domain/predefined_life_event.dart';
import 'package:my_career_app/features/catalog/presentation/catalog_panel.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';

import '../../../support/mocks.dart';
import '../../../support/pump.dart';

void main() {
  setUpAll(registerCommonFallbackValues);

  Future<void> pumpPanel(WidgetTester tester) {
    return pumpInScaffold(
      tester,
      const SizedBox(width: 200, child: CatalogPanel()),
      overrides: [
        eventRepositoryProvider.overrideWithValue(stubEventRepository()),
      ],
    );
  }

  group('CatalogPanel', () {
    testWidgets('パネルが結婚グループの折りたたみを持つこと', (tester) async {
      await pumpPanel(tester);

      expect(find.text('結婚'), findsOneWidget);
    });

    testWidgets('検索フィールドが表示されること', (tester) async {
      await pumpPanel(tester);

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('結婚グループはデフォルトで展開されていること', (tester) async {
      await pumpPanel(tester);

      // 結婚グループ内の「お付き合い開始」が表示されること
      expect(find.text('お付き合い開始'), findsOneWidget);
    });

    testWidgets('カタログアイテムが LongPressDraggable でラップされていること', (tester) async {
      await pumpPanel(tester);

      expect(
        find.byType(LongPressDraggable<PredefinedLifeEvent>),
        findsWidgets,
      );
    });

    testWidgets('検索フィールドに入力すると絞り込まれること', (tester) async {
      await pumpPanel(tester);

      await tester.enterText(find.byType(TextField), '転職');
      await tester.pumpAndSettle();

      expect(find.text('転職'), findsWidgets);
    });
  });
}
