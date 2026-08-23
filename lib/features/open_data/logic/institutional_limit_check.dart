import '../../timeline/domain/constraint_result.dart';
import '../../timeline/domain/life_event.dart';
import '../data/institutional_limits.dart';
import '../domain/institutional_limit.dart';

/// タイムライン上のイベントに対して、制度上限（B1）の情報を判定する純粋関数。
///
/// PDR-008: 制度上限は出典付きで積極的に見せる。判定結果は
/// `ConstraintSeverity.info` としてのみ返し、配置をブロックしない（Value 4）。
///
/// - `InstitutionalLimitKind.duration`: 対象イベント自身の期間
///   （`endDate - date`）が上限**未満**のときだけ発火する。ちょうど・超過や
///   期間指定の無いイベントでは発火しない。
/// - `InstitutionalLimitKind.window`: 対象イベントが存在すれば無条件で発火する
///   （「起点からこの期間内は利用できる」という事実の提示のため）。
List<ConstraintResult> checkInstitutionalLimits(List<LifeEvent> events) {
  final results = <ConstraintResult>[];

  for (final event in events) {
    for (final limit in institutionalLimits) {
      if (event.catalogId != limit.catalogId) continue;

      final fires = switch (limit.kind) {
        InstitutionalLimitKind.duration => _durationBelowLimit(event, limit),
        InstitutionalLimitKind.window => true,
      };
      if (!fires) continue;

      results.add(ConstraintResult(
        ruleId: limit.id,
        targetEventTitle: event.title,
        severity: ConstraintSeverity.info,
        message: limit.message,
        sourceLabel: limit.source.label,
        sourceUrl: limit.source.url,
        scopeLabel: limit.scope.label,
      ));
    }
  }

  return results;
}

bool _durationBelowLimit(LifeEvent event, InstitutionalLimit limit) {
  final endYearMonth = event.endYearMonth;
  if (endYearMonth == null) return false;
  final durationMonths = endYearMonth.differenceInMonths(event.yearMonth);
  return durationMonths < limit.limitMonths;
}
