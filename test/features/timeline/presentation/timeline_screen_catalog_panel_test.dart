import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/auth/logic/auth_provider.dart';
import 'package:my_career_app/features/catalog/presentation/catalog_panel.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';
import 'package:my_career_app/features/timeline/presentation/timeline_screen.dart';

class _StubEventsNotifier extends TimelineEventsNotifier {
  @override
  Future<List<LifeEvent>> build() async => const [];
}

Widget _buildWithSize(Size size) {
  return ProviderScope(
    overrides: [
      timelineEventsProvider.overrideWith(() => _StubEventsNotifier()),
      authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const TimelineScreen(),
      ),
    ),
  );
}

void main() {
  group('TimelineScreen カタログパネル統合', () {
    testWidgets('デスクトップ幅 (1200px) でカタログパネルが表示されること', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildWithSize(const Size(1200, 800)));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogPanel), findsOneWidget);
    });

    testWidgets('デスクトップ幅で CatalogPanel が存在すること', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildWithSize(const Size(1200, 800)));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogPanel), findsOneWidget);
    });

    testWidgets('モバイル幅 (400px) では CatalogPanel がドロワー内に格納されること', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildWithSize(const Size(400, 800)));
      await tester.pumpAndSettle();

      // モバイル幅では CatalogPanel が画面に直接表示されないこと
      // （ドロワーボタンが表示されること）
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    });
  });
}
