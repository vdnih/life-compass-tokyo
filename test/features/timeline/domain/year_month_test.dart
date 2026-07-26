import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/year_month.dart';

void main() {
  group('parse / toString', () {
    test('yyyy-MM 文字列をパースして toString で同じ文字列に戻ること', () {
      expect(YearMonth.parse('2024-01').toString(), '2024-01');
    });

    test('月が2桁ゼロ埋めされること', () {
      expect(const YearMonth(2024, 3).toString(), '2024-03');
    });

    test('不正な形式は FormatException を投げること', () {
      const invalid = [
        '',
        '2024',
        '2024-1',
        '2024-13',
        '2024-00',
        'abcd-01',
        '2024-01-15',
        '2024/01',
      ];
      for (final value in invalid) {
        expect(
          () => YearMonth.parse(value),
          throwsFormatException,
          reason: '"$value" は FormatException を投げるべき',
        );
      }
    });
  });

  group('addMonths', () {
    test('12月を越えると年が繰り上がること', () {
      expect(const YearMonth(2025, 11).addMonths(3), const YearMonth(2026, 2));
    });

    test('1月を下回ると年が繰り下がること', () {
      expect(const YearMonth(2028, 1).addMonths(-2), const YearMonth(2027, 11));
    });

    test('12の倍数を加減しても月が変わらないこと', () {
      expect(const YearMonth(2025, 7).addMonths(24), const YearMonth(2027, 7));
      expect(const YearMonth(2025, 7).addMonths(-24), const YearMonth(2023, 7));
    });

    test('0ヶ月の加算で同値になること', () {
      expect(const YearMonth(2025, 7).addMonths(0), const YearMonth(2025, 7));
    });

    test('複数年をまたぐ負のオフセットで正しく繰り下がること', () {
      expect(const YearMonth(2025, 1).addMonths(-13), const YearMonth(2023, 12));
    });

    test('DateTime(y, m ± 12) の正規化と一致すること（C-01/C-02 の等価性）', () {
      // C-01: DateTime(jobDate.year, jobDate.month + 12)
      final plus12 = DateTime(2020, 4 + 12);
      expect(
        const YearMonth(2020, 4).addMonths(12),
        YearMonth(plus12.year, plus12.month),
      );

      // C-02: DateTime(birthDate.year, birthDate.month - 12)
      final minus12 = DateTime(2026, 6 - 12);
      expect(
        const YearMonth(2026, 6).addMonths(-12),
        YearMonth(minus12.year, minus12.month),
      );
    });
  });

  group('differenceInMonths', () {
    test('後の年月から前の年月を引くと正になること', () {
      expect(
        const YearMonth(2026, 2).differenceInMonths(const YearMonth(2025, 11)),
        3,
      );
    });

    test('逆向きだと負になること', () {
      expect(
        const YearMonth(2025, 11).differenceInMonths(const YearMonth(2026, 2)),
        -3,
      );
    });

    test('10年差が120になること', () {
      expect(
        const YearMonth(2035, 1).differenceInMonths(const YearMonth(2025, 1)),
        120,
      );
    });

    test('addMonths と differenceInMonths が年境界をまたいでも整合すること', () {
      const pairs = [
        (YearMonth(2025, 11), YearMonth(2026, 3)),
        (YearMonth(2020, 1), YearMonth(2019, 6)),
        (YearMonth(2024, 12), YearMonth(2025, 1)),
      ];
      for (final (a, b) in pairs) {
        final delta = a.differenceInMonths(b);
        expect(b.addMonths(delta), a, reason: '$b + $delta ヶ月 は $a と一致すべき');
      }
    });
  });

  group('順序', () {
    test('compareTo で年→月の順に並ぶこと', () {
      final list = [
        const YearMonth(2025, 3),
        const YearMonth(2024, 12),
        const YearMonth(2025, 1),
        const YearMonth(2024, 1),
      ]..sort();
      expect(list, [
        const YearMonth(2024, 1),
        const YearMonth(2024, 12),
        const YearMonth(2025, 1),
        const YearMonth(2025, 3),
      ]);
    });

    test('同一年月では isBefore も isAfter も false であること', () {
      const a = YearMonth(2025, 6);
      const b = YearMonth(2025, 6);
      expect(a.isBefore(b), isFalse);
      expect(a.isAfter(b), isFalse);
    });
  });

  group('fromDateTime / toDateTime', () {
    test('DateTime から日・時刻を切り捨てて年月を取り出すこと', () {
      final ym = YearMonth.fromDateTime(DateTime(2024, 3, 15, 10, 30));
      expect(ym, const YearMonth(2024, 3));
    });

    test('toDateTime がその月の1日0時になること', () {
      expect(const YearMonth(2024, 3).toDateTime(), DateTime(2024, 3));
    });
  });

  group('japaneseLabel', () {
    test('月がゼロ埋めされないこと', () {
      expect(const YearMonth(2025, 3).japaneseLabel, '2025年3月');
    });
  });
}
