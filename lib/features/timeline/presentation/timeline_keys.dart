import 'package:flutter/widgets.dart';

/// ウィジェットテストが安定して参照するための [Key] 定義。
///
/// テストが具象クラス名（`YearTimeline` など）や画面座標の実測値に依存すると、
/// 実装の差し替えやレイアウト変更のたびにテスト側が壊れ、リファクタリングの
/// 安全網として機能しなくなる。「何を指しているか」を表すキーをここに集約し、
/// テストは常にキー経由で対象を特定する。
abstract final class TimelineKeys {
  /// 年月ビューのタイムライン本体
  static const Key timelineYearMonth = Key('timeline-year-month');

  /// 年ビューのタイムライン本体
  static const Key timelineYear = Key('timeline-year');

  /// 仕事レーンのラベル。レーンの縦位置を示す基準として使う
  static const Key workLane = Key('timeline-lane-work');

  /// プライベートレーンのラベル。レーンの縦位置を示す基準として使う
  static const Key privateLane = Key('timeline-lane-private');
}
