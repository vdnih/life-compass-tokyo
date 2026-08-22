import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/ai_coach/presentation/coach_chat_sheet.dart';
import 'package:my_career_app/features/catalog/presentation/catalog_panel.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/template_set_panel.dart';

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

  /// [type] のパネルを直接の子孫として囲む [IgnorePointer] の `ignoring` を返す。
  ///
  /// `buildPanelTabContent` が非選択タブも常時マウントしたまま
  /// `IgnorePointer` で操作だけ無効化する方式のため、タブが実際に選択されて
  /// 操作可能になっているかは `find.byType` の有無ではなく `ignoring` で判定する。
  bool isTabInteractive(WidgetTester tester, Type type) {
    final ignorePointer = tester.widget<IgnorePointer>(
      find
          .ancestor(of: find.byType(type), matching: find.byType(IgnorePointer))
          .first,
    );
    return !ignorePointer.ignoring;
  }

  group('3タブ切り替え', () {
    testWidgets('初期表示はチャットタブが操作可能で、カタログ/テンプレートは無効化されていること', (tester) async {
      await pumpSheet(tester);

      expect(find.text('チャット'), findsOneWidget);
      expect(find.text('カタログ'), findsOneWidget);
      expect(find.text('テンプレート'), findsOneWidget);

      expect(isTabInteractive(tester, CatalogPanel), isFalse);
      expect(isTabInteractive(tester, TemplateSetPanel), isFalse);
    });

    testWidgets('「カタログ」タブをタップするとカタログが操作可能になること', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('カタログ'));
      await tester.pumpAndSettle();

      expect(isTabInteractive(tester, CatalogPanel), isTrue);
      expect(isTabInteractive(tester, TemplateSetPanel), isFalse);
    });

    testWidgets('「テンプレート」タブをタップするとテンプレート一覧が操作可能になること', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('テンプレート'));
      await tester.pumpAndSettle();

      expect(isTabInteractive(tester, TemplateSetPanel), isTrue);
      expect(isTabInteractive(tester, CatalogPanel), isFalse);
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
