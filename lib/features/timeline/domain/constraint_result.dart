import 'package:flutter/foundation.dart';

/// 制約チェック結果の重要度
enum ConstraintSeverity {
  /// 警告: ユーザーに注意を促す（育休取得不可の可能性など）
  warning('警告'),

  /// 情報: 参考情報として表示（推奨時期の案内など）
  info('情報');

  const ConstraintSeverity(this.label);
  final String label;
}

/// 制約チェックの結果を表すモデル
@immutable
class ConstraintResult {
  /// 制約ルールID（"C-01", "C-02" など）
  final String ruleId;

  /// 制約対象のイベント（警告を表示するイベント）
  final String targetEventTitle;

  /// 関連するイベント名（制約の相手方）
  final String? relatedEventTitle;

  /// メッセージ種別
  final ConstraintSeverity severity;

  /// 表示メッセージ
  final String message;

  const ConstraintResult({
    required this.ruleId,
    required this.targetEventTitle,
    this.relatedEventTitle,
    required this.severity,
    required this.message,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConstraintResult &&
        other.ruleId == ruleId &&
        other.targetEventTitle == targetEventTitle &&
        other.relatedEventTitle == relatedEventTitle &&
        other.severity == severity &&
        other.message == message;
  }

  @override
  int get hashCode {
    return ruleId.hashCode ^
        targetEventTitle.hashCode ^
        relatedEventTitle.hashCode ^
        severity.hashCode ^
        message.hashCode;
  }
}
