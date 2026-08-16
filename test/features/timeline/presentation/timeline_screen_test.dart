import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';
import 'package:my_career_app/features/timeline/presentation/add_event_dialog.dart';
import 'package:my_career_app/features/timeline/presentation/timeline_keys.dart';
import 'package:my_career_app/features/timeline/presentation/timeline_screen.dart';

import '../../../support/builders.dart';
import '../../../support/pump.dart';

class _StubEventsNotifier extends TimelineEventsNotifier {
  @override
  Future<List<LifeEvent>> build() async => [
    buildLifeEvent(id: 'stub-event-1', date: '2020-01'),
  ];
}

/// ゲストモード（未認証）で [TimelineScreen] を表示する
Future<void> _pumpAsGuest(WidgetTester tester) {
  return pumpApp(
    tester,
    const TimelineScreen(),
    overrides: [
      timelineEventsProvider.overrideWith(_StubEventsNotifier.new),
      guestAuth(),
    ],
  );
}

/// 認証済みで [TimelineScreen] を表示する（書き込み操作のテスト用）
Future<void> _pumpAsSignedIn(WidgetTester tester) {
  return pumpApp(
    tester,
    const TimelineScreen(),
    overrides: [
      timelineEventsProvider.overrideWith(_StubEventsNotifier.new),
      signedInAuth(),
    ],
  );
}

/// レーンをタップする。
///
/// タップ位置は画面座標の実測値ではなく、レーンラベルの矩形から導出する。
/// AppBar の高さや padding、軸の高さが変わってもテストが壊れないようにするため。
/// x はイベントカードを避けるためタイムライン領域の右寄りを使う。
Future<void> _tapLane(WidgetTester tester, Key laneKey) async {
  final laneRect = tester.getRect(find.byKey(laneKey));
  final screenWidth =
      tester.view.physicalSize.width / tester.view.devicePixelRatio;
  await tester.tapAt(Offset(screenWidth - 80, laneRect.center.dy));
  await tester.pumpAndSettle();
}

/// 軸エリア（レーンより上の年月ラベル部分）をタップする
Future<void> _tapAxis(WidgetTester tester) async {
  final laneRect = tester.getRect(find.byKey(TimelineKeys.workLane));
  final screenWidth =
      tester.view.physicalSize.width / tester.view.devicePixelRatio;
  await tester.tapAt(Offset(screenWidth - 80, laneRect.top - 10));
  await tester.pumpAndSettle();
}

void main() {
  group('TimelineScreen の機能一覧（仕様）', () {
    testWidgets('デフォルトは年月表示であること', (tester) async {
      await _pumpAsGuest(tester);

      expect(find.byKey(TimelineKeys.timelineYearMonth), findsOneWidget);
      expect(find.byKey(TimelineKeys.timelineYear), findsNothing);
    });

    testWidgets('「年」ボタンをタップすると年表示に切り替わること', (tester) async {
      await _pumpAsGuest(tester);

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      expect(find.byKey(TimelineKeys.timelineYear), findsOneWidget);
      expect(find.byKey(TimelineKeys.timelineYearMonth), findsNothing);
    });

    testWidgets('「年月」ボタンをタップすると年月表示に戻ること', (tester) async {
      await _pumpAsGuest(tester);

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('年月'));
      await tester.pumpAndSettle();

      expect(find.byKey(TimelineKeys.timelineYearMonth), findsOneWidget);
      expect(find.byKey(TimelineKeys.timelineYear), findsNothing);
    });
  });

  group('タイムラインタップによるイベント追加（年月表示）', () {
    testWidgets('仕事レーンをタップするとAddEventDialogが開くこと', (tester) async {
      await _pumpAsSignedIn(tester);

      await _tapLane(tester, TimelineKeys.workLane);

      expect(find.text('イベントを追加'), findsOneWidget);
    });

    testWidgets('仕事レーンをタップすると「仕事」が選択済みでダイアログが開くこと', (tester) async {
      await _pumpAsSignedIn(tester);

      await _tapLane(tester, TimelineKeys.workLane);

      // SegmentedButton で 仕事 が選択されていることを確認
      expect(
        find.descendant(
          of: find.byType(AddEventDialog),
          matching: find.text('仕事'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('プライベートレーンをタップするとAddEventDialogが開くこと', (tester) async {
      await _pumpAsSignedIn(tester);

      await _tapLane(tester, TimelineKeys.privateLane);

      expect(find.text('イベントを追加'), findsOneWidget);
    });

    testWidgets('プライベートレーンをタップすると「プライベート」が選択済みでダイアログが開くこと', (tester) async {
      await _pumpAsSignedIn(tester);

      await _tapLane(tester, TimelineKeys.privateLane);

      expect(
        find.descendant(
          of: find.byType(AddEventDialog),
          matching: find.text('プライベート'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('軸エリア（年月ラベル部分）をタップしてもダイアログが開かないこと', (tester) async {
      await _pumpAsSignedIn(tester);

      await _tapAxis(tester);

      expect(find.text('イベントを追加'), findsNothing);
    });

    testWidgets('未認証でもレーンをタップするとAddEventDialogが開くこと', (tester) async {
      await _pumpAsGuest(tester);

      await _tapLane(tester, TimelineKeys.workLane);

      expect(find.text('イベントを追加'), findsOneWidget);
    });
  });

  group('タイムラインタップによるイベント追加（年表示）', () {
    testWidgets('年表示の仕事レーンをタップするとAddEventDialogが開くこと', (tester) async {
      await _pumpAsSignedIn(tester);

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      await _tapLane(tester, TimelineKeys.workLane);

      expect(find.text('イベントを追加'), findsOneWidget);
    });

    testWidgets('年表示のプライベートレーンをタップするとAddEventDialogが開くこと', (tester) async {
      await _pumpAsSignedIn(tester);

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      await _tapLane(tester, TimelineKeys.privateLane);

      expect(find.text('イベントを追加'), findsOneWidget);
    });
  });
}
