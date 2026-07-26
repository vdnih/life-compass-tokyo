import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/presentation/edit_event_dialog.dart';

import '../../../support/builders.dart';
import '../../../support/pump.dart';

LifeEvent _sampleEvent() => buildLifeEvent(
      id: 'test-event-id',
      date: '2025-04',
      description: 'テスト説明',
      status: EventStatus.planned,
    );

Future<void> _pumpDialogLauncher(WidgetTester tester, LifeEvent event) {
  return pumpInScaffold(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (_) => EditEventDialog(event: event),
          );
        },
        child: const Text('ダイアログを開く'),
      ),
    ),
  );
}

void main() {
  group('EditEventDialog', () {
    testWidgets('予算入力欄が表示されること（タイトルが「予算（円）」のTextFieldが存在すること）', (tester) async {
      await _pumpDialogLauncher(tester, _sampleEvent());

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('イベントを編集'), findsOneWidget);
      expect(find.text('予算（円）'), findsOneWidget);
    });

    testWidgets('既存のbudgetYenが入力欄に初期値として表示されること', (tester) async {
      final event = _sampleEvent().copyWith(budgetYen: 300000);
      await _pumpDialogLauncher(tester, event);

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 予算フィールドに初期値が表示されているか確認
      final budgetField = find.widgetWithText(TextFormField, '300000');
      expect(budgetField, findsOneWidget);
    });

    testWidgets('予算欄に数値を入力して保存できること', (tester) async {
      await _pumpDialogLauncher(tester, _sampleEvent());

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // タイトルフィールドに入力（バリデーションのため）
      final titleFields = find.byType(TextFormField);
      await tester.enterText(titleFields.first, 'テストイベント');

      // 予算フィールド（数字入力欄）にスクロールして入力
      final budgetHint = find.text('予算（円）');
      await tester.ensureVisible(budgetHint);
      await tester.pumpAndSettle();

      // 予算フィールドを特定（数字キーボード対応フィールド）
      // TextFormFieldを順番で特定: title, description, budget の順
      final allFields = find.byType(TextFormField);
      // index 2 が予算フィールド
      await tester.enterText(allFields.at(2), '500000');

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // ダイアログが閉じていることを確認
      expect(find.text('イベントを編集'), findsNothing);
    });
  });
}
