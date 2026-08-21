import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/timeline_scale.dart';
import 'package:my_career_app/features/timeline/domain/year_month.dart';
import 'package:my_career_app/features/timeline/presentation/widgets/point_event_marker.dart';

void main() {
  group('月ビュー相当のスケール（monthsPerSlot: 1）', () {
    const scale = TimelineScale(
      origin: YearMonth(2025, 1),
      pixelsPerSlot: 60.0,
      monthsPerSlot: 1,
      slotCount: 24,
    );

    test('origin の位置は左余白のみであること', () {
      expect(scale.xOfBlock(const YearMonth(2025, 1)), 20.0);
    });

    test('1ヶ月先は1スロット分右にずれること', () {
      expect(scale.xOfBlock(const YearMonth(2025, 2)), 20.0 + 60.0);
    });

    test('slotIndexAt と xOfSlot が往復すること', () {
      for (final i in [0, 1, 5, 23]) {
        expect(scale.slotIndexAt(scale.xOfSlot(i)), i);
      }
    });

    test('dateAtSlot が1ヶ月刻みで進むこと', () {
      expect(scale.dateAtSlot(0), const YearMonth(2025, 1));
      expect(scale.dateAtSlot(13), const YearMonth(2026, 2));
    });

    test('containsSlot が範囲の内外を正しく判定すること', () {
      expect(scale.containsSlot(0), isTrue);
      expect(scale.containsSlot(23), isTrue);
      expect(scale.containsSlot(24), isFalse);
      expect(scale.containsSlot(-1), isFalse);
    });

    test('widthOfMonths が1ヶ月あたり pixelsPerSlot になること', () {
      expect(scale.widthOfMonths(3), 180.0);
    });

    test('xCenterOf が該当ブロックの中央になること', () {
      // 2025-03 は slot 2（0始まり） → 20 + 2*60 + 30
      expect(scale.xCenterOf(const YearMonth(2025, 3)), 20.0 + 2 * 60.0 + 30.0);
    });

    test('inclusiveWidth が両端を含んだブロック数分の幅になること', () {
      // 2025-03 〜 2025-06 は 3,4,5,6月 の4ブロック分
      expect(
        scale.inclusiveWidth(const YearMonth(2025, 3), const YearMonth(2025, 6)),
        4 * 60.0,
      );
      // 同月同士は1ブロック分
      expect(
        scale.inclusiveWidth(const YearMonth(2025, 3), const YearMonth(2025, 3)),
        60.0,
      );
    });
  });

  group('年ビュー相当のスケール（monthsPerSlot: 12）', () {
    const scale = TimelineScale(
      origin: YearMonth(2020, 1),
      pixelsPerSlot: 80.0,
      monthsPerSlot: 12,
      slotCount: 20,
    );

    test('offsetSlots は年の途中の月では小数位置になること', () {
      // 2021-07 は origin から 1年 + 6/12 年（面モデルの xCenterOf / xOfBlock は
      // これを 1 スロット目に丸める。下の「年内のどの月でも…」テスト参照）
      expect(scale.offsetSlots(const YearMonth(2021, 7)), 1.5);
    });

    test('dateAtSlot が常に1月を返すこと（年ビューは1月にスナップ）', () {
      for (final i in [0, 1, 5, 19]) {
        expect(scale.dateAtSlot(i).month, 1);
      }
      expect(scale.dateAtSlot(3), const YearMonth(2023, 1));
    });

    test('widthOfMonths が12ヶ月で pixelsPerSlot 分になること', () {
      expect(scale.widthOfMonths(12), 80.0);
      expect(scale.widthOfMonths(6), 40.0);
    });

    test('年内のどの月でも同じブロック（=年）の中央を返すこと', () {
      // 面モデルでは年ビューは年内の小数位置を持たず、年単位のブロックに丸まる。
      expect(
        scale.xCenterOf(const YearMonth(2021, 1)),
        scale.xCenterOf(const YearMonth(2021, 7)),
      );
      expect(scale.xCenterOf(const YearMonth(2021, 1)), 20.0 + 80.0 + 40.0);
    });
  });

  group('境界・負のオフセット', () {
    const scale = TimelineScale(
      origin: YearMonth(2025, 6),
      pixelsPerSlot: 60.0,
      monthsPerSlot: 1,
      slotCount: 10,
    );

    test('origin より前の年月は負のオフセットになること', () {
      expect(scale.offsetSlots(const YearMonth(2025, 3)), -3);
    });

    test('contains が範囲外の年月を除外すること', () {
      expect(scale.contains(const YearMonth(2025, 6)), isTrue);
      expect(scale.contains(const YearMonth(2025, 3)), isFalse);
      expect(scale.contains(const YearMonth(2026, 4)), isFalse); // slot 10 は範囲外
      expect(scale.contains(const YearMonth(2026, 3)), isTrue); // slot 9 は範囲内
    });

    test('totalWidth が slotCount * pixelsPerSlot + 100 であること', () {
      expect(scale.totalWidth, 10 * 60.0 + 100);
    });
  });

  group('ドラッグ着地月の往復不変条件（timeline_view.dart の _dragAnchorInset と対）', () {
    // 「月 M に描画されたイベントを掴んで動かさずに離したら、着地月も M であること」。
    // #75 の元バグは、この往復が点イベントだけ1スロット手前にズレていたことが原因
    // （PointEventMarker はブロックの左端から anchorInset 分だけ左にオフセットして
    // 描画される）。面モデル化（ADR-025）後も基準がブロック左端に変わっただけで、
    // 往復不変条件そのものは維持する。
    //
    // 描画時の left も timeline_view.dart の _dragAnchorInset も、ここで呼んでいる
    // PointEventMarker.anchorInset を単一の情報源として参照している（値の重複定義なし）。
    // イベント移動は child 基準の details.offset を使うため、ドラッグ開始位置の
    // ローカル dx は「描画時の left」そのものになる。
    int roundTripSlot(
      TimelineScale scale,
      YearMonth month, {
      required bool hasDuration,
    }) {
      final anchorInset = PointEventMarker.anchorInset(
        hasDuration: hasDuration,
        pixelsPerSlot: scale.pixelsPerSlot,
      );
      final renderLeft = scale.xOfBlock(month) - anchorInset;
      return scale.slotIndexAt(renderLeft + anchorInset);
    }

    const monthScale = TimelineScale(
      origin: YearMonth(2025, 1),
      pixelsPerSlot: 80.0,
      monthsPerSlot: 1,
      slotCount: 60,
    );
    const yearScale = TimelineScale(
      origin: YearMonth(2020, 1),
      pixelsPerSlot: 80.0,
      monthsPerSlot: 12,
      slotCount: 20,
    );

    const months = [
      YearMonth(2025, 1),
      YearMonth(2025, 6),
      YearMonth(2026, 12),
      YearMonth(2029, 3),
    ];

    for (final month in months) {
      test('$month（点イベント・月ビュー）: 動かさずに離すと同じ月に着地すること', () {
        final slot = roundTripSlot(monthScale, month, hasDuration: false);
        expect(monthScale.dateAtSlot(slot), month);
      });

      test('$month（期間イベント・月ビュー）: 動かさずに離すと同じ月に着地すること', () {
        final slot = roundTripSlot(monthScale, month, hasDuration: true);
        expect(monthScale.dateAtSlot(slot), month);
      });
    }

    test('年ビュー（点イベント）: 動かさずに離すと同じ年の1月に着地すること', () {
      const month = YearMonth(2023, 1);
      final slot = roundTripSlot(yearScale, month, hasDuration: false);
      expect(yearScale.dateAtSlot(slot), month);
    });
  });
}
