import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/ai_coach/presentation/coach_chat_sheet.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';

import '../../../support/mocks.dart';
import '../../../support/pump.dart';

/// #72 spike v2: モバイルはチャットのみでカタログ/テンプレートに到達できなかった
/// フィードバックを受け、ボトムシートを「チャット/カタログ/テンプレート」タブ化した。
/// あわせて、ドラッグハンドルに実際のリサイズ操作が無かった不具合も直した。
void main() {
  setUpAll(registerCommonFallbackValues);

  Future<void> pumpSheet(WidgetTester tester) {
    return pumpInScaffold(
      tester,
      const CoachChatSheet(),
      size: const Size(390, 844),
      overrides: [
        eventRepositoryProvider.overrideWithValue(stubEventRepository()),
        dependencyRepositoryProvider.overrideWithValue(
          stubDependencyRepository(),
        ),
        guestAuth(),
      ],
    );
  }

  /// 現在選択中のタブインデックス（`IndexedStack.index`）を返す。
  int selectedTabIndex(WidgetTester tester) {
    return tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;
  }

  group('3タブ切り替え', () {
    testWidgets('初期表示はチャットタブが選択されていること', (tester) async {
      await pumpSheet(tester);

      expect(find.text('チャット'), findsOneWidget);
      expect(find.text('カタログ'), findsOneWidget);
      expect(find.text('テンプレート'), findsOneWidget);

      expect(selectedTabIndex(tester), 0);
    });

    testWidgets('「カタログ」タブをタップするとカタログが選択されること', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('カタログ'));
      await tester.pumpAndSettle();

      expect(selectedTabIndex(tester), 1);
    });

    testWidgets('「テンプレート」タブをタップするとテンプレートが選択されること', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('テンプレート'));
      await tester.pumpAndSettle();

      expect(selectedTabIndex(tester), 2);
    });
  });

  group('ハンドルドラッグによるリサイズ', () {
    testWidgets('ハンドルを上方向にドラッグすると、シートの可視領域が広がること', (tester) async {
      await pumpSheet(tester);

      final handleRectBefore = tester.getRect(
        find.byKey(CoachChatSheet.dragHandleKey),
      );

      // ハンドルを大きく上方向にドラッグする（折りたたみ→展開サイズへ）。
      await tester.drag(
        find.byKey(CoachChatSheet.dragHandleKey),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      final handleRectAfter = tester.getRect(
        find.byKey(CoachChatSheet.dragHandleKey),
      );

      expect(
        handleRectAfter.top,
        lessThan(handleRectBefore.top),
        reason: 'シートが広がり、ハンドルの位置が上（画面上方向）に移動すること',
      );
    });
  });
}
