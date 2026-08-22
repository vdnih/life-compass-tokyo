import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/catalog/presentation/catalog_panel.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';
import 'package:my_career_app/features/timeline/presentation/timeline_screen.dart';

import '../../../support/pump.dart';

class _StubEventsNotifier extends TimelineEventsNotifier {
  @override
  Future<List<LifeEvent>> build() async => const [];
}

Future<void> _pumpWithSize(WidgetTester tester, Size size) {
  return pumpApp(
    tester,
    const TimelineScreen(),
    overrides: [
      timelineEventsProvider.overrideWith(_StubEventsNotifier.new),
      guestAuth(),
    ],
    size: size,
  );
}

void main() {
  group('TimelineScreen カタログパネル統合', () {
    testWidgets('デスクトップ幅 (1200px) では drawer を持たないこと', (tester) async {
      await _pumpWithSize(tester, const Size(1200, 800));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNull);
    });

    testWidgets('モバイル幅 (400px) でも drawer を持たないこと', (tester) async {
      await _pumpWithSize(tester, const Size(400, 800));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNull);
    });

    testWidgets('デスクトップ幅 (1200px) でカタログパネルが1つだけ表示されること', (tester) async {
      await _pumpWithSize(tester, const Size(1200, 800));

      expect(find.byType(CatalogPanel), findsOneWidget);
    });

    testWidgets('モバイル幅 (400px) でもボトムシートのタブ経由でカタログパネルに到達できること', (tester) async {
      // #72 spike v2: モバイルはチャットのみでカタログへ到達できなかったため、
      // ボトムシートを「チャット/カタログ/テンプレート」タブ化した。CatalogPanel は
      // 非選択時も検索文字列・展開状態を保つため常時マウントされている
      // （CoachChatSheet の buildPanelTabContent、IndexedStack を使わない理由と同じ）。
      await _pumpWithSize(tester, const Size(400, 800));

      expect(find.byType(CatalogPanel), findsOneWidget);
    });

    testWidgets('デスクトップ幅・モバイル幅どちらでもイベント追加ボタンが表示されること', (tester) async {
      await _pumpWithSize(tester, const Size(1200, 800));
      expect(find.byIcon(Icons.add), findsOneWidget);

      await _pumpWithSize(tester, const Size(400, 800));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('カタログを開くためのメニューボタンは存在しないこと', (tester) async {
      await _pumpWithSize(tester, const Size(400, 800));

      expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
    });
  });
}
