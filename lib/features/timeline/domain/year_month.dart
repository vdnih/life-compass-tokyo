import 'package:flutter/foundation.dart';

/// `yyyy-MM` 形式の年月を表す値オブジェクト。
///
/// `LifeEvent.date` / `endDate` の永続化フォーマットである `yyyy-MM` 文字列に対する
/// 月加算・月差分・比較を1箇所に集約するために導入した（ADR-020）。
///
/// **永続化フィールドはこの型に置き換えない。** `LifeEvent.date` / `endDate` は
/// 引き続き `String`（Firestore 保存形式）のままで、この型は計算・比較のためだけに
/// 使う。境界は `LifeEvent.yearMonth` / `endYearMonth` getter と `toJson` / `fromJson`
/// の2箇所だけに留める。
///
/// [toString] は Firestore 保存形式（`2025-03`）を返す。UI 表示には [japaneseLabel]
/// （`2025年3月`）を使うこと。`Text('$yearMonth')` のように書くと保存形式がそのまま
/// 画面に出てしまう。
///
/// 現状の消費者は `features/timeline/` のみ。2つ目の feature が参照するようになったら
/// `lib/core/` への移動を検討する。
@immutable
class YearMonth implements Comparable<YearMonth> {
  /// 年
  final int year;

  /// 月（1..12）
  final int month;

  const YearMonth(this.year, this.month)
      : assert(month >= 1 && month <= 12, 'month must be 1..12');

  /// `yyyy-MM` 形式の文字列をパースする。
  ///
  /// 月は2桁ゼロ埋め必須（`'2025-3'` は受け付けない）。既存の日付組み立てが
  /// すべて `padLeft(2, '0')` を通しており、非パディングを許すと固定幅を前提にした
  /// 文字列ソート（`goal_setup_dialog.dart` 等）が静かに壊れるため。
  ///
  /// 不正な形式または月が 1..12 の範囲外の場合は [FormatException] を投げる。
  factory YearMonth.parse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) {
      throw FormatException('Invalid yyyy-MM format', value);
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) {
      throw FormatException('month must be 1..12', value);
    }
    return YearMonth(year, month);
  }

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})$');

  /// [dateTime] の年月部分（日・時刻は切り捨て）を取り出す。
  factory YearMonth.fromDateTime(DateTime dateTime) =>
      YearMonth(dateTime.year, dateTime.month);

  /// 1月を起点とした通し月数（内部計算専用）。
  ///
  /// 公開しない: 現存する全ての月インデックス利用は「差分」か「加算」であり、
  /// 1-based の絶対値を外部に見せる必要がない。
  int get _index => year * 12 + (month - 1);

  /// この年月から [months] ヶ月加算（負の場合は減算）した年月を返す。
  ///
  /// 年境界をまたぐ場合は年が繰り上がる/繰り下がる
  /// （例: `2025-11` + 3 = `2026-02`、`2028-01` - 2 = `2027-11`）。
  YearMonth addMonths(int months) {
    final total = _index + months;
    final m = total % 12; // Dart の % は正の除数に対し常に非負
    return YearMonth((total - m) ~/ 12, m + 1);
  }

  /// この年月と [other] の月数差（this - other）を返す。
  ///
  /// this が other より後なら正、前なら負。
  int differenceInMonths(YearMonth other) => _index - other._index;

  /// この年月の1日 0時を表す [DateTime] を返す。
  DateTime toDateTime() => DateTime(year, month);

  /// この年月が [other] より前か。
  bool isBefore(YearMonth other) => _index < other._index;

  /// この年月が [other] より後か。
  bool isAfter(YearMonth other) => _index > other._index;

  @override
  int compareTo(YearMonth other) => _index.compareTo(other._index);

  /// Firestore 保存形式（`yyyy-MM`）。UI 表示には [japaneseLabel] を使うこと。
  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';

  /// UI 表示用の日本語表記（`2025年3月`）。月はゼロ埋めしない。
  String get japaneseLabel => '$year年$month月';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YearMonth && other.year == year && other.month == month);

  @override
  int get hashCode => Object.hash(year, month);
}
