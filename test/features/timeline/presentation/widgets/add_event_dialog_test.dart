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
    testWidgets('タイトルと詳細を入力して追加できること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

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

      // ダイアログが閉じていることを確認（正常に送信された）
      expect(find.text('イベントを追加'), findsNothing);
    });

    testWidgets('仕事/プライベートをプライベートに切り替えてから追加できること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

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

      // ダイアログが閉じていることを確認
      expect(find.text('イベントを追加'), findsNothing);
    });

    testWidgets('開始年月の選択UIが表示されること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('開始年月'));
      expect(find.text('開始年月'), findsOneWidget);
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

    testWidgets('仕事を選択した場合にアイコン選択(入社/キャリアアップ/目標)が表示されること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 仕事はデフォルト選択なのでアイコン選択が表示されているはず
      expect(find.text('入社'), findsOneWidget);
      expect(find.text('キャリアアップ'), findsOneWidget);
      expect(find.text('目標'), findsOneWidget);
    });

    testWidgets('プライベートを選択した場合にアイコン選択が非表示になること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('プライベート'));
      await tester.tap(find.text('プライベート'));
      await tester.pumpAndSettle();

      expect(find.text('入社'), findsNothing);
      expect(find.text('キャリアアップ'), findsNothing);
      expect(find.text('目標'), findsNothing);
    });

    testWidgets('アイコンを「目標」に変更して追加できること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('目標'));
      await tester.tap(find.text('目標'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, '目標イベント');
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      expect(find.text('イベントを追加'), findsNothing);
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
