import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../open_data/logic/institutional_limit_check.dart';
import '../domain/constraint_result.dart';
import '../domain/event_dependency.dart';
import '../domain/life_event.dart';
import '../domain/year_month.dart';
import 'dependency_provider.dart';
import 'timeline_events_provider.dart';

/// イベント一覧と依存関係に対して全制約チェックを実行し、結果リストを返す純粋関数
///
/// v6.0: EventCategory の代わりに catalogId でチェック。
/// 旧 C-01 / C-02 は §4.3 のカタログ静的ルールに統合されたため、
/// ここでは catalogId ベースの比較で判定する。
///
/// `open_data/logic/institutional_limit_check.dart` の制度上限（B1、PDR-008）
/// もここに合流させる。timeline feature が open_data feature に依存する形に
/// なるが、catalog feature を timeline と並列に置いているのと同じ理由
/// （共有データを持つ feature を下位に置く）で、方向としては問題ない。
List<ConstraintResult> checkAllConstraints(
  List<LifeEvent> events, [
  List<EventDependency> dependencies = const [],
]) {
  final results = <ConstraintResult>[];
  results.addAll(_checkC01(events));
  results.addAll(_checkC02(events));
  results.addAll(_checkC03(events, dependencies));
  results.addAll(checkInstitutionalLimits(events));
  return results;
}

/// C-01: 転職/入社から1年未満に出産/産休イベントがある場合 → Warning
///
/// catalogId ベース: 'joining-company' or 'job-change' が先行、
/// 'childbirth' or 'maternity-leave' が1年未満後に来る場合
List<ConstraintResult> _checkC01(List<LifeEvent> events) {
  final results = <ConstraintResult>[];

  const jobCatalogIds = {'joining-company', 'job-change'};
  const birthCatalogIds = {'childbirth', 'maternity-leave'};

  final jobEvents = events
      .where((e) => jobCatalogIds.contains(e.catalogId))
      .toList()
    ..sort((a, b) => a.yearMonth.compareTo(b.yearMonth));

  final birthOrLeaveEvents =
      events.where((e) => birthCatalogIds.contains(e.catalogId));

  for (final birthEvent in birthOrLeaveEvents) {
    final birthDate = birthEvent.yearMonth;

    // 出産日より前の転職イベントのうち、最も直近のものを探す
    LifeEvent? closestJob;
    for (final job in jobEvents) {
      if (job.yearMonth.isBefore(birthDate)) {
        closestJob = job;
      }
    }

    if (closestJob == null) continue;

    final jobDate = closestJob.yearMonth;
    final twelveMonthsLater = jobDate.addMonths(12);

    // 出産日が転職日+12ヶ月より前（ちょうど12ヶ月はOK）
    if (birthDate.isBefore(twelveMonthsLater)) {
      results.add(ConstraintResult(
        ruleId: 'C-01',
        targetEventTitle: birthEvent.title,
        relatedEventTitle: closestJob.title,
        severity: ConstraintSeverity.warning,
        message:
            '${closestJob.title}から1年未満のため、育休が取得できない可能性があります',
      ));
    }
  }

  return results;
}

/// C-02: 出産予定があるが1年以上前に転職/入社なし → Info
List<ConstraintResult> _checkC02(List<LifeEvent> events) {
  final results = <ConstraintResult>[];

  const jobCatalogIds = {'joining-company', 'job-change'};
  const childbirthCatalogId = 'childbirth';

  final jobEvents =
      events.where((e) => jobCatalogIds.contains(e.catalogId));

  final childbirthEvents =
      events.where((e) => e.catalogId == childbirthCatalogId);

  for (final birth in childbirthEvents) {
    final birthDate = birth.yearMonth;
    final twelveMonthsBefore = birthDate.addMonths(-12);

    // 出産日の12ヶ月以上前に転職/入社があるか
    final hasEarlyEnoughJob = jobEvents.any((job) {
      final jobDate = job.yearMonth;
      return !jobDate.isAfter(twelveMonthsBefore);
    });

    if (!hasEarlyEnoughJob) {
      results.add(ConstraintResult(
        ruleId: 'C-02',
        targetEventTitle: birth.title,
        severity: ConstraintSeverity.info,
        message: '転職から1年以上経過していると、育休取得の条件を満たしやすくなります',
      ));
    }
  }

  return results;
}

/// C-03: 依存関係のオフセット期間が確保されていない場合 → Warning
List<ConstraintResult> _checkC03(
  List<LifeEvent> events,
  List<EventDependency> dependencies,
) {
  final results = <ConstraintResult>[];

  // イベントIDをキーとするマップ
  final eventMap = {for (final e in events) e.id: e};

  for (final dep in dependencies) {
    final source = eventMap[dep.sourceEventId];
    final target = eventMap[dep.targetEventId];

    if (source == null || target == null) continue;

    // source の日付に offsetMonths を加算した期待日付
    final expected =
        YearMonth.parse(source.date).addMonths(dep.offsetMonths);

    if (expected != YearMonth.parse(target.date)) {
      results.add(ConstraintResult(
        ruleId: 'C-03',
        targetEventTitle: target.title,
        relatedEventTitle: source.title,
        severity: ConstraintSeverity.warning,
        message:
            '${source.title}と${target.title}の間に必要な期間（${dep.offsetMonths}ヶ月）が確保されていません',
      ));
    }
  }

  return results;
}

/// タイムラインイベントの制約チェック結果を提供するProvider
final constraintCheckerProvider = Provider<List<ConstraintResult>>((ref) {
  final eventsAsync = ref.watch(timelineEventsProvider);
  final depsAsync = ref.watch(dependencyProvider);
  return eventsAsync.when(
    loading: () => [],
    error: (_, _) => [],
    data: (events) => depsAsync.when(
      loading: () => checkAllConstraints(events),
      error: (_, _) => checkAllConstraints(events),
      data: (deps) => checkAllConstraints(events, deps),
    ),
  );
});
