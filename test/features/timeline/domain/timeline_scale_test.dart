import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/timeline_scale.dart';
import 'package:my_career_app/features/timeline/domain/year_month.dart';

void main() {
  group('月ビュー相当のスケール（monthsPerSlot: 1）', () {
    const scale = TimelineScale(
      origin: YearMonth(2025, 1),
      pixelsPerSlot: 60.0,
      monthsPerSlot: 1,
      slotCount: 24,
    );

    test('origin の位置は左余白のみであること', () {
      expect(scale.xOf(const YearMonth(2025, 1)), 20.0);
    });

    test('1ヶ月先は1スロット分右にずれること', () {
      expect(scale.xOf(const YearMonth(2025, 2)), 20.0 + 60.0);
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
  });

  group('年ビュー相当のスケール（monthsPerSlot: 12）', () {
    const scale = TimelineScale(
      origin: YearMonth(2020, 1),
      pixelsPerSlot: 80.0,
      monthsPerSlot: 12,
      slotCount: 20,
    );

    test('年の途中の月は小数位置になること', () {
      // 2021-07 は origin から 1年 + 6/12 年
      expect(scale.xOf(const YearMonth(2021, 7)), 20.0 + 1.5 * 80.0);
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
}
