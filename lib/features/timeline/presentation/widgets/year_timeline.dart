import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../user_profile/user_profile.dart';
import '../../domain/life_event.dart';
import '../../domain/constraint_result.dart';
import '../add_event_dialog.dart';
import 'event_style.dart';

class YearTimeline extends ConsumerWidget {
  final List<LifeEvent> events;
  final List<ConstraintResult> constraints;

  const YearTimeline({
    super.key,
    required this.events,
    this.constraints = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) return const Center(child: Text('No events found'));

    final profile = ref.watch(userProfileNotifierProvider);

    final sortedEvents = List<LifeEvent>.from(events)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstYear = sortedEvents.first.dateTime.year;
    int lastYear = sortedEvents.last.dateTime.year;

    for (var event in events) {
      if (event.hasDuration && event.endDateTime!.year > lastYear) {
        lastYear = event.endDateTime!.year;
      }
    }

    final startYear = firstYear - 2;
    final endYear = lastYear + 3;
    final totalYears = endYear - startYear;

    const double yearWidth = 80.0;
    const double axisHeight = 60.0;
    const double rowHeight = 160.0;

    // 現在時点のオフセットを計算
    final now = DateTime.now();
    final nowOffset = now.year - startYear;
    final nowXPos = 20.0 + (nowOffset * yearWidth);

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左側の固定ラベル
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: SizedBox(
              width: 36,
              height: axisHeight + rowHeight * 2,
              child: Column(
                children: [
                  const SizedBox(height: axisHeight),
                  Container(
                    height: rowHeight,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        right: BorderSide(
                          color: Colors.blueGrey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: const RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        '仕事',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: rowHeight,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: Colors.blueGrey.withValues(alpha: 0.3),
                        ),
                        right: BorderSide(
                          color: Colors.blueGrey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: const RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'プライベート',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 右側のスクロール可能なタイムライン
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(top: 40, bottom: 40, right: 40),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) {
                  final tapX = details.localPosition.dx;
                  final tapY = details.localPosition.dy;

                  // 軸エリアと下余白は無視する
                  if (tapY < axisHeight || tapY >= axisHeight + rowHeight * 2) {
                    return;
                  }

                  final yearIndex = ((tapX - 20.0) / yearWidth).floor();
                  if (yearIndex < 0 || yearIndex >= totalYears) return;

                  final tappedDate = DateTime(startYear + yearIndex, 1);
                  final isWork = tapY < axisHeight + rowHeight;

                  showDialog(
                    context: context,
                    builder: (context) => AddEventDialog(
                      initialDate: tappedDate,
                      initialIsWork: isWork,
                    ),
                  );
                },
                child: SizedBox(
                width: totalYears * yearWidth + 100,
                height: axisHeight + rowHeight * 2,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 仕事とプライベートの境界線
                    Positioned(
                      top: axisHeight + rowHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: Colors.blueGrey.withValues(alpha: 0.3),
                      ),
                    ),

                    // メインの横線
                    Positioned(
                      top: axisHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        color: Colors.blueGrey.withValues(alpha: 0.3),
                      ),
                    ),

                    // 現在時点マーカー
                    Positioned(
                      left: nowXPos - 0.5,
                      top: 0,
                      child: Container(
                        width: 2,
                        height: axisHeight + rowHeight * 2,
                        color: Colors.red.withValues(alpha: 0.4),
                      ),
                    ),
                    Positioned(
                      left: nowXPos - 16,
                      top: axisHeight + rowHeight * 2 - 2,
                      child: Text(
                        '現在',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.withValues(alpha: 0.7),
                        ),
                      ),
                    ),

                    // 年ごとの目盛りとラベル
                    ...List.generate(totalYears + 1, (index) {
                      final year = startYear + index;
                      final xPos = 20.0 + (index * yearWidth);
                      final ageAtDate = profile.calculateAgeAt(
                        DateTime(year, 1),
                      );

                      return Positioned(
                        left: xPos - 20,
                        top: axisHeight - 55,
                        child: SizedBox(
                          width: 40,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ageAtDate != null)
                                Text(
                                  '$ageAtDate歳',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blueGrey.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              Text(
                                '$year',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 2,
                                height: 12,
                                color: Colors.blueGrey,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // 期間を持つイベントの矢印
                    ...events.where((e) => e.hasDuration).map((event) {
                      final startOffset = event.dateTime.year - startYear;
                      final endOffset = event.endDateTime!.year - startYear;

                      final startXPos = 20.0 + (startOffset * yearWidth);
                      final endXPos = 20.0 + (endOffset * yearWidth);

                      final rowTop = event.isWork
                          ? axisHeight
                          : axisHeight + rowHeight;
                      final baseTop = rowTop + 24.0 + 50.0 + 6.0 + 12.0;

                      final color = eventColor(event);
                      final opacity = eventOpacity(event);

                      return Positioned(
                        left: startXPos + 12,
                        top: baseTop - 1,
                        width: endXPos - startXPos - 12,
                        child: Opacity(
                          opacity: opacity,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: color.withValues(alpha: 0.6),
                                ),
                              ),
                              Icon(
                                Icons.arrow_right,
                                color: color.withValues(alpha: 0.6),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // イベントの配置
                    ...events.map((event) {
                      final yearOffset = event.dateTime.year - startYear;
                      final xPos = 20.0 + (yearOffset * yearWidth);

                      final rowTop = event.isWork
                          ? axisHeight
                          : axisHeight + rowHeight;
                      const topPadding = 24.0;

                      final color = eventColor(event);
                      final opacity = eventOpacity(event);
                      final eventConstraints = constraints
                          .where((c) => c.targetEventTitle == event.title)
                          .toList();
                      final hasWarning = eventConstraints.isNotEmpty;

                      return Positioned(
                        left: xPos - 60,
                        top: rowTop + topPadding,
                        child: GestureDetector(
                          onTap: () => _showEventDetails(
                            context,
                            event,
                            eventConstraints,
                          ),
                          child: Opacity(
                            opacity: opacity,
                            child: SizedBox(
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: event.isWork
                                              ? Colors.blue.shade50
                                              : Colors.orange.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: color,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          event.title,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: event.isWork
                                                ? Colors.blue.shade800
                                                : Colors.orange.shade800,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      if (hasWarning)
                                        Positioned(
                                          top: -6,
                                          right: -6,
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.amber.shade700,
                                            size: 18,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (event.isFuturePlan)
                                    Text(
                                      event.status.label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  Icon(
                                    categoryIcon(event.category),
                                    color: color,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(
    BuildContext context,
    LifeEvent event,
    List<ConstraintResult> eventConstraints,
  ) {
    final color = eventColor(event);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(categoryIcon(event.category), color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(event.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    event.hasDuration
                        ? '${event.date} 〜 ${event.endDate}'
                        : event.date,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (event.isFuturePlan) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        event.status.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.category.label,
                style: TextStyle(fontSize: 13, color: color),
              ),
              const SizedBox(height: 12),
              Text(event.description),
              if (eventConstraints.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...eventConstraints.map((c) {
                  final isWarning =
                      c.severity == ConstraintSeverity.warning;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isWarning
                          ? Colors.amber.shade50
                          : Colors.lightBlue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isWarning
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline,
                          color: isWarning
                              ? Colors.amber.shade700
                              : Colors.lightBlue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.message,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }
}
