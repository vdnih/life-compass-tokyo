import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/constraint_result.dart';
import '../domain/event_dependency.dart';
import '../domain/life_event.dart';
import 'dependency_provider.dart';
import 'timeline_events_provider.dart';

/// イベント一覧と依存関係に対して全制約チェックを実行し、結果リストを返す純粋関数
List<ConstraintResult> checkAllConstraints(
  List<LifeEvent> events, [
  List<EventDependency> dependencies = const [],
]) {
  final results = <ConstraintResult>[];
  results.addAll(_checkC01(events));
  results.addAll(_checkC02(events));
  results.addAll(_checkC03(events, dependencies));
  return results;
}

/// C-01: 転職/入社から1年未満に出産/産休イベントがある場合 → Warning
List<ConstraintResult> _checkC01(List<LifeEvent> events) {
  final results = <ConstraintResult>[];

  final jobEvents = events
      .where((e) =>
          e.category == EventCategory.joining ||
          e.category == EventCategory.jobChange)
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  final birthOrLeaveEvents = events.where((e) =>
      e.category == EventCategory.childbirth ||
      e.category == EventCategory.maternityLeave);

  for (final birthEvent in birthOrLeaveEvents) {
    final birthDate = birthEvent.dateTime;

    // 出産日より前の転職イベントのうち、最も直近のものを探す
    LifeEvent? closestJob;
    for (final job in jobEvents) {
      if (job.dateTime.isBefore(birthDate)) {
        closestJob = job;
      }
    }

    if (closestJob == null) continue;

    final jobDate = closestJob.dateTime;
    final twelveMonthsLater =
        DateTime(jobDate.year, jobDate.month + 12);

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

  final jobEvents = events.where((e) =>
      e.category == EventCategory.joining ||
      e.category == EventCategory.jobChange);

  final childbirthEvents =
      events.where((e) => e.category == EventCategory.childbirth);

  for (final birth in childbirthEvents) {
    final birthDate = birth.dateTime;
    final twelveMonthsBefore =
        DateTime(birthDate.year, birthDate.month - 12);

    // 出産日の12ヶ月以上前に転職/入社があるか
    // 「12ヶ月以上前」= 転職日が出産日-12ヶ月以前（ちょうど12ヶ月はOK）
    final hasEarlyEnoughJob = jobEvents.any((job) {
      final jobDate = job.dateTime;
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
///
/// すべての依存関係について、source イベントの日付 + offsetMonths が
/// target イベントの日付と一致しない場合に警告する。
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
    final sourceParts = source.date.split('-');
    int year = int.parse(sourceParts[0]);
    int month = int.parse(sourceParts[1]) + dep.offsetMonths;
    while (month > 12) {
      year++;
      month -= 12;
    }
    while (month < 1) {
      year--;
      month += 12;
    }
    final expectedDate = '$year-${month.toString().padLeft(2, '0')}';

    if (expectedDate != target.date) {
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
    error: (_, __) => [],
    data: (events) => depsAsync.when(
      loading: () => checkAllConstraints(events),
      error: (_, __) => checkAllConstraints(events),
      data: (deps) => checkAllConstraints(events, deps),
    ),
  );
});
