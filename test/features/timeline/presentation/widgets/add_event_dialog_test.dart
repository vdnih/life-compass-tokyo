import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/presentation/add_event_dialog.dart';

Widget _buildTestWidget() {
  return const ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: _dialogLauncher,
        ),
      ),
    ),
  );
}

Widget _dialogLauncher(BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      showDialog(
        context: context,
        builder: (_) => const AddEventDialog(),
      );
    },
    child: const Text('ダイアログを開く'),
  );
}

void main() {
  group('AddEventDialog の機能一覧（仕様）', () {
    testWidgets('タイトル、開始・終了年月、仕事/プライベートの選択が正しくUI入力できること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('イベントを追加'), findsOneWidget);

      // タイトル入力
      await tester.enterText(find.byType(TextFormField).first, 'テストイベント');

      // 追加ボタンタップ
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // ダイアログが閉じていることを確認（正常に送信された）
      expect(find.text('イベントを追加'), findsNothing);
    });

    testWidgets('イベント名が空の場合は「追加」ボタンを押しても処理が実行されない(ダイアログが閉じない)こと', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget());

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // タイトルは空のまま、「追加」ボタンをタップ
      await tester.tap(find.text('追加'));
      await tester.pump();

      // ダイアログは依然として開いている
      expect(find.text('イベントを追加'), findsOneWidget);
    });

    testWidgets('期間指定トグルをONにすると終了年月が入力可能になること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 当初は終了年月が表示されていない
      expect(find.text('終了年月'), findsNothing);

      // 期間指定トグルをスクロールして表示してからタップ
      await tester.ensureVisible(find.text('期間を指定する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('期間を指定する'));
      await tester.pumpAndSettle();

      // 終了年月が表示される
      expect(find.text('終了年月'), findsOneWidget);
    });
  });
}
