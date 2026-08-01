import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/catalog/domain/predefined_life_event.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/presentation/timeline_keys.dart';
import 'package:my_career_app/features/timeline/presentation/timeline_screen.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/timeline_view.dart';

import '../../../../support/builders.dart';
import '../../../../support/mocks.dart';
import '../../../../support/pump.dart';

/// D&D の配線テスト。
///
/// 見るのは「ジェスチャが DragTarget に届き、その結果がリポジトリまで流れるか」だけ。
/// 座標から日付への変換・スナップ・境界値の網羅はここでは扱わない
/// （純粋関数として切り出したうえでユニットテストで担保する方針）。
///
/// ドラッグの起点にはイベントのタイトル文字を使う。マーカーの矩形中心は
/// 三角形とタイトルの間の余白にあたり、hit test が素通りしてしまうため。
void main() {
  setUpAll(registerCommonFallbackValues);

  /// 現在月から [monthsFromNow] ヶ月後の 'yyyy-MM'
  String monthFromNow(int monthsFromNow) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month + monthsFromNow);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  /// [finder] を長押ししてから [dx] だけ水平にドラッグして離す
  Future<void> dragHorizontally(
    WidgetTester tester,
    Finder finder,
    double dx,
  ) async {
    final gesture = await tester.startGesture(tester.getCenter(finder));
    // LongPressDraggable の delay は 400ms
    await tester.pump(const Duration(milliseconds: 600));
    // DragTarget の onMove を確実に発火させるため複数回に分けて動かす
    await gesture.moveBy(Offset(dx / 2, 0));
    await tester.pump();
    await gesture.moveBy(Offset(dx / 2, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('既存イベントのドラッグ移動', () {
    testWidgets('右にドラッグして離すと、移動後の日付でリポジトリが更新されること', (tester) async {
      final event = buildLifeEvent(id: 'e1', date: monthFromNow(0));
      final eventRepo = stubEventRepository(events: [event]);

      await pumpApp(
        tester,
        Scaffold(
          body: TimelineView(
            mode: TimelineViewMode.yearMonth,
            events: [event],
          ),
        ),
        overrides: [
          eventRepositoryProvider.overrideWithValue(eventRepo),
          dependencyRepositoryProvider
              .overrideWithValue(stubDependencyRepository()),
          signedInAuth(),
        ],
      );

      await dragHorizontally(tester, find.text(event.title), 200);

      final captured = verify(() => eventRepo.updateEvent(captureAny()))
          .captured
          .cast<LifeEvent>();
      expect(captured, hasLength(1), reason: 'ドロップで1件だけ更新されること');
      expect(captured.single.id, 'e1');
      expect(
        captured.single.yearMonth.isAfter(event.yearMonth),
        isTrue,
        reason: '右方向へのドラッグなので日付は後ろにずれること',
      );
    });

    testWidgets('年ビューでも同様にドラッグ移動でリポジトリが更新されること', (tester) async {
      // TimelineScale 切り出し（#35）・2実装統合（#34, #36）で年ビューにも
      // 座標変換・D&D の配線が共有されたことを確認する（#44）。
      final event = buildLifeEvent(id: 'e1', date: monthFromNow(0));
      final eventRepo = stubEventRepository(events: [event]);

      await pumpApp(
        tester,
        Scaffold(
          body: TimelineView(mode: TimelineViewMode.year, events: [event]),
        ),
        overrides: [
          eventRepositoryProvider.overrideWithValue(eventRepo),
          dependencyRepositoryProvider
              .overrideWithValue(stubDependencyRepository()),
          signedInAuth(),
        ],
      );

      await dragHorizontally(tester, find.text(event.title), 200);

      final captured = verify(() => eventRepo.updateEvent(captureAny()))
          .captured
          .cast<LifeEvent>();
      expect(captured, hasLength(1));
      expect(captured.single.id, 'e1');
    });
  });

  group('依存関係のあるイベントの連動移動', () {
    testWidgets('依存先を持つイベントを動かすと、連動して両方が更新されること', (tester) async {
      final source = buildLifeEvent(
        id: 'src',
        title: '転職',
        date: monthFromNow(0),
      );
      final target = buildLifeEvent(
        id: 'tgt',
        title: '出産',
        date: monthFromNow(6),
        // プライベートレーンに置いて仕事レーンのイベントと重ならないようにする
        catalogId: 'childbirth',
      );
      final events = [source, target];
      final eventRepo = stubEventRepository(events: events);

      await pumpApp(
        tester,
        Scaffold(
          body: TimelineView(mode: TimelineViewMode.yearMonth, events: events),
        ),
        overrides: [
          eventRepositoryProvider.overrideWithValue(eventRepo),
          dependencyRepositoryProvider.overrideWithValue(
            stubDependencyRepository(
              dependencies: [
                buildDependency(
                  sourceEventId: 'src',
                  targetEventId: 'tgt',
                  offsetMonths: 6,
                ),
              ],
            ),
          ),
          signedInAuth(),
        ],
      );

      await dragHorizontally(tester, find.text(source.title), 200);

      final captured = verify(() => eventRepo.updateEvent(captureAny()))
          .captured
          .cast<LifeEvent>();
      expect(
        captured.map((e) => e.id).toSet(),
        {'src', 'tgt'},
        reason: '依存グラフを辿って依存先も連動移動すること',
      );
    });
  });

  group('カタログからのドロップ', () {
    /// カタログパネルが横に並ぶデスクトップ幅で画面ごと表示する
    Future<MockEventRepository> pumpScreen(
      WidgetTester tester, {
      required bool signedIn,
    }) async {
      final eventRepo = stubEventRepository();
      await pumpApp(
        tester,
        const TimelineScreen(),
        overrides: [
          eventRepositoryProvider.overrideWithValue(eventRepo),
          dependencyRepositoryProvider
              .overrideWithValue(stubDependencyRepository()),
          if (signedIn) signedInAuth() else guestAuth(),
        ],
        size: const Size(1400, 900),
      );
      return eventRepo;
    }

    /// カタログの「結婚式」を仕事レーン上へドラッグして離す
    ///
    /// ドロップ先の縦位置はレーンラベルの矩形から導出する。タイムライン
    /// ウィジェットの矩形中心はレーン領域の下にあたり、ドロップが成立しない。
    Future<void> dragCatalogItemToTimeline(WidgetTester tester) async {
      final catalogItem = find
          .ancestor(
            of: find.text('結婚式'),
            matching: find.byType(LongPressDraggable<PredefinedLifeEvent>),
          )
          .first;
      final timelineRect =
          tester.getRect(find.byKey(TimelineKeys.timelineYearMonth));
      final laneRect = tester.getRect(find.byKey(TimelineKeys.workLane));
      final dropTarget = Offset(timelineRect.center.dx, laneRect.center.dy);

      final gesture = await tester.startGesture(tester.getCenter(catalogItem));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(dropTarget);
      await tester.pump();
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('認証済みならドロップしたカタログのイベントが保存されること', (tester) async {
      final eventRepo = await pumpScreen(tester, signedIn: true);

      await dragCatalogItemToTimeline(tester);

      final captured = verify(() => eventRepo.saveEvent(captureAny()))
          .captured
          .cast<LifeEvent>();
      expect(captured, hasLength(1));
      expect(captured.single.catalogId, 'wedding-ceremony');
    });

    testWidgets('未認証ならサインインを促し、保存しないこと', (tester) async {
      final eventRepo = await pumpScreen(tester, signedIn: false);

      await dragCatalogItemToTimeline(tester);

      verifyNever(() => eventRepo.saveEvent(any()));
      expect(find.text('サインインが必要です'), findsOneWidget);
    });
  });
}
