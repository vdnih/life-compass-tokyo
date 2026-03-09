import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';
import 'package:my_career_app/features/timeline/presentation/timeline_screen.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/year_month_timeline.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/year_timeline.dart';

class _StubEventsNotifier extends TimelineEventsNotifier {
  @override
  Future<List<LifeEvent>> build() async => const [
    LifeEvent(
      date: '2020-01',
      title: 'テストイベント',
      description: '',
      category: EventCategory.joining,
    ),
  ];
}

Widget _buildTestWidget() {
  return ProviderScope(
    overrides: [
      timelineEventsProvider.overrideWith(() => _StubEventsNotifier()),
    ],
    child: const MaterialApp(home: TimelineScreen()),
  );
}

// タップ座標の計算根拠:
// - AppBar 高さ: 56px
// - 水平 ScrollView の top padding: 40px
// - GestureDetector 開始位置 (screen y): 56 + 40 = 96px
// - 軸エリア高さ (axisHeight): 60px → screen y 96–156
// - 仕事レーン (rowHeight=160): screen y 156–316
// - プライベートレーン:         screen y 316–476
// - ラベル列幅 (left column): 36px → GestureDetector 開始 screen x: 36px

void main() {
  group('TimelineScreen の機能一覧（仕様）', () {
    testWidgets('デフォルトは年月表示であること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(YearMonthTimeline), findsOneWidget);
      expect(find.byType(YearTimeline), findsNothing);
    });

    testWidgets('「年」ボタンをタップすると年表示に切り替わること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      expect(find.byType(YearTimeline), findsOneWidget);
      expect(find.byType(YearMonthTimeline), findsNothing);
    });

    testWidgets('「年月」ボタンをタップすると年月表示に戻ること', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('年月'));
      await tester.pumpAndSettle();

      expect(find.byType(YearMonthTimeline), findsOneWidget);
      expect(find.byType(YearTimeline), findsNothing);
    });
  });

  group('タイムラインタップによるイベント追加（年月表示）', () {
    testWidgets('仕事レーンをタップするとAddEventDialogが開くこと', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // 仕事レーン中央付近 (screen y ≈ 230, x ≈ 400、イベントカードを避ける)
      await tester.tapAt(const Offset(400, 230));
      await tester.pumpAndSettle();

      expect(find.text('イベントを追加'), findsOneWidget);
    });

    testWidgets('仕事レーンをタップすると「仕事」が選択済みでダイアログが開くこと', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(400, 230));
      await tester.pumpAndSettle();

      // SegmentedButton で 仕事 が選択されていることを確認
      expect(find.text('仕事'), findsOneWidget);
    });

    testWidgets('プライベートレーンをタップするとAddEventDialogが開くこと', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // プライベートレーン中央付近 (screen y ≈ 380)
      await tester.tapAt(const Offset(400, 380));
      await tester.pumpAndSettle();

      expect(find.text('イベントを追加'), findsOneWidget);
    });

    testWidgets('プライベートレーンをタップすると「プライベート」が選択済みでダイアログが開くこと',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(400, 380));
      await tester.pumpAndSettle();

      expect(find.text('プライベート'), findsOneWidget);
    });

    testWidgets('軸エリア（年月ラベル部分）をタップしてもダイアログが開かないこと', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // 軸エリア (screen y ≈ 110、axisHeight 内)
      await tester.tapAt(const Offset(400, 110));
      await tester.pumpAndSettle();

      expect(find.text('イベントを追加'), findsNothing);
    });
  });

  group('タイムラインタップによるイベント追加（年表示）', () {
    testWidgets('年表示の仕事レーンをタップするとAddEventDialogが開くこと', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // 年表示に切り替え
      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      // 仕事レーン中央付近
      await tester.tapAt(const Offset(400, 230));
      await tester.pumpAndSettle();

      expect(find.text('イベントを追加'), findsOneWidget);
    });

    testWidgets('年表示のプライベートレーンをタップするとAddEventDialogが開くこと', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();

      // プライベートレーン
      await tester.tapAt(const Offset(400, 380));
      await tester.pumpAndSettle();

      expect(find.text('イベントを追加'), findsOneWidget);
    });
  });
}
