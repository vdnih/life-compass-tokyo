import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/constraint_result.dart';
import '../domain/life_event.dart';
import 'timeline_events_provider.dart';

/// イベント一覧に対して全制約チェックを実行し、結果リストを返す純粋関数
List<ConstraintResult> checkAllConstraints(List<LifeEvent> events) {
  final results = <ConstraintResult>[];
  results.addAll(_checkC01(events));
  results.addAll(_checkC02(events));
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
        message: '出産予定の1年前までに転職を完了しておくと、育休取得がスムーズです',
      ));
    }
  }

  return results;
}

/// タイムラインイベントの制約チェック結果を提供するProvider
final constraintCheckerProvider = Provider<List<ConstraintResult>>((ref) {
  final eventsAsync = ref.watch(timelineEventsProvider);
  return eventsAsync.when(
    loading: () => [],
    error: (_, __) => [],
    data: (events) => checkAllConstraints(events),
  );
});
