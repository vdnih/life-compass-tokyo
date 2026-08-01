import '../../catalog/domain/predefined_life_event.dart';
import 'life_event.dart';
import 'year_month.dart';

/// カタログ項目をタイムラインへドロップしようとしている位置が、
/// カタログの hard/soft 先行ルールに違反していないかを表す。
enum CatalogPlacementSeverity {
  /// hard ルール違反（物理的・法的に成立しない順序）
  hard,

  /// soft ルール違反（慣習・準備期間として推奨される順序）
  soft,
}

/// [checkCatalogPlacement] の違反結果。
class CatalogPlacementViolation {
  final CatalogPlacementSeverity severity;
  final String message;

  const CatalogPlacementViolation({
    required this.severity,
    required this.message,
  });
}

/// [catalog] を [at] の年月に配置しようとした場合の先行ルール違反を判定する。
///
/// hard ルールを soft ルールより優先して判定し、最初に見つかった違反1件を返す
/// （`year_timeline.dart` / `year_month_timeline.dart` の `_buildDropPreview` に
/// byte 単位で重複していた判定ロジックを統合したもの。#34, #36）。
/// 違反がなければ null。ドロップ自体はブロックしない（CLAUDE.md §3）。
CatalogPlacementViolation? checkCatalogPlacement({
  required PredefinedLifeEvent catalog,
  required YearMonth at,
  required List<LifeEvent> events,
}) {
  for (final hardRule in catalog.hardRules) {
    final predecessor = events
        .cast<LifeEvent?>()
        .firstWhere((e) => e!.catalogId == hardRule.predecessorCatalogId,
            orElse: () => null);
    if (predecessor == null) {
      return CatalogPlacementViolation(
        severity: CatalogPlacementSeverity.hard,
        message: hardRule.message,
      );
    }
    if (hardRule.minMonthsAfter != null) {
      final diffMonths = at.differenceInMonths(predecessor.yearMonth);
      if (diffMonths < hardRule.minMonthsAfter!) {
        return CatalogPlacementViolation(
          severity: CatalogPlacementSeverity.hard,
          message: hardRule.message,
        );
      }
    }
  }

  for (final softRule in catalog.softRules) {
    final predecessor = events
        .cast<LifeEvent?>()
        .firstWhere((e) => e!.catalogId == softRule.predecessorCatalogId,
            orElse: () => null);
    if (predecessor == null) {
      return CatalogPlacementViolation(
        severity: CatalogPlacementSeverity.soft,
        message: softRule.message,
      );
    }
    final diffMonths = at.differenceInMonths(predecessor.yearMonth);
    if (diffMonths < softRule.recommendedMinMonthsAfter) {
      return CatalogPlacementViolation(
        severity: CatalogPlacementSeverity.soft,
        message: softRule.message,
      );
    }
  }

  return null;
}
