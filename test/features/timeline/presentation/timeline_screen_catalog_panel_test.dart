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
    testWidgets('デスクトップ幅 (1200px) でカタログパネルが表示されること', (tester) async {
      await _pumpWithSize(tester, const Size(1200, 800));

      expect(find.byType(CatalogPanel), findsOneWidget);
    });

    testWidgets('モバイル幅 (400px) では CatalogPanel がドロワー内に格納されること', (tester) async {
      await _pumpWithSize(tester, const Size(400, 800));

      // モバイル幅では CatalogPanel が画面に直接表示されず、
      // ドロワーを開くボタンが表示されること
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    });
  });
}
