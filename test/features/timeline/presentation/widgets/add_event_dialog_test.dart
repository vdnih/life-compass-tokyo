import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/presentation/add_event_dialog.dart';

import '../../../../support/pump.dart';

Future<void> _pumpDialogLauncher(WidgetTester tester) {
  return pumpInScaffold(tester, const Builder(builder: _dialogLauncher));
}

Widget _dialogLauncher(BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      showDialog<void>(
        context: context,
        builder: (_) => const AddEventDialog(),
      );
    },
    child: const Text('ダイアログを開く'),
  );
}

void main() {
  group('AddEventDialog の機能一覧（仕様）', () {
    testWidgets('タイトルと詳細を入力して追加できること', (tester) async {
      await _pumpDialogLauncher(tester);

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('イベントを追加'), findsOneWidget);

      // タイトル入力
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'テストイベント');

      // 詳細入力
      await tester.ensureVisible(find.byType(TextFormField).last);
      await tester.enterText(find.byType(TextFormField).last, 'テスト詳細');

      // 追加ボタンタップ
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // ダイアログが閉じていることを確認
      expect(find.text('イベントを追加'), findsNothing);
    });

    testWidgets('仕事/プライベートをプライベートに切り替えてから追加できること', (tester) async {
      await _pumpDialogLauncher(tester);

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // プライベートを選択
      await tester.ensureVisible(find.text('プライベート'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('プライベート'));
      await tester.pumpAndSettle();

      // タイトルを入力して追加
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'プライベートイベント');
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      expect(find.text('イベントを追加'), findsNothing);
    });

    testWidgets('開始年月の選択UIが表示されること', (tester) async {
      await _pumpDialogLauncher(tester);

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('開始年月'));
      expect(find.text('開始年月'), findsOneWidget);
    });

    testWidgets('イベント名が空の場合は「追加」ボタンを押しても処理が実行されない(ダイアログが閉じない)こと', (
      tester,
    ) async {
      await _pumpDialogLauncher(tester);

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // タイトルは空のまま、「追加」ボタンをタップ
      await tester.tap(find.text('追加'));
      await tester.pump();

      // ダイアログは依然として開いている
      expect(find.text('イベントを追加'), findsOneWidget);
    });

    // NOTE: カタログ選択UIのテストは未整備。
    // 旧UI（カテゴリチップを直接表示）前提のテストがカタログ pivot 後も残っていたため削除した。
    // 現在は CatalogPickerField 経由で選択するため、テスト整備フェーズで書き直す。

    testWidgets('ステータス選択（記録/予定/目標/検討中）が表示されること', (tester) async {
      await _pumpDialogLauncher(tester);

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('記録'), findsOneWidget);
      expect(find.text('予定'), findsOneWidget);
    });

    testWidgets('期間指定トグルをONにすると終了年月が入力可能になること', (tester) async {
      await _pumpDialogLauncher(tester);

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 当初は終了年月が表示されていない
      expect(find.text('終了年月'), findsNothing);

      await tester.ensureVisible(find.text('期間を指定する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('期間を指定する'));
      await tester.pumpAndSettle();

      expect(find.text('終了年月'), findsOneWidget);
    });
  });
}
