import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../user_profile/user_profile.dart';
import '../../domain/life_event.dart';
import 'event_style.dart';

class YearMonthTimeline extends ConsumerWidget {
  final List<LifeEvent> events;

  const YearMonthTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) return const Center(child: Text('No events found'));

    final profile = ref.watch(userProfileNotifierProvider);

    final sortedEvents = List<LifeEvent>.from(events)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstDate = sortedEvents.first.dateTime;
    DateTime lastDate = sortedEvents.last.dateTime;

    for (var event in events) {
      if (event.hasDuration && event.endDateTime!.isAfter(lastDate)) {
        lastDate = event.endDateTime!;
      }
    }

    final startDate = DateTime(firstDate.year, firstDate.month - 3);
    final endDate = DateTime(lastDate.year, lastDate.month + 6);

    final totalMonths =
        ((endDate.year - startDate.year) * 12) +
        (endDate.month - startDate.month);

    const double monthWidth = 60.0;
    const double axisHeight = 60.0;
    const double rowHeight = 160.0;

    // 現在時点のオフセットを計算
    final now = DateTime.now();
    final nowOffset =
        ((now.year - startDate.year) * 12) + (now.month - startDate.month);
    final nowXPos = 20.0 + (nowOffset * monthWidth);

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
              child: SizedBox(
                width: totalMonths * monthWidth + 100,
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

                    // メインの横線 (タイムラインのベース)
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

                    // 月ごとの目盛りとラベル
                    ...List.generate(totalMonths + 1, (index) {
                      final currentDate = DateTime(
                        startDate.year,
                        startDate.month + index,
                      );
                      final xPos = 20.0 + (index * monthWidth);
                      final isJan = currentDate.month == 1;
                      final ageAtDate = profile.calculateAgeAt(currentDate);

                      return Positioned(
                        left: xPos - 20,
                        top: axisHeight - (isJan ? 55 : 25),
                        child: SizedBox(
                          width: 40,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isJan) ...[
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
                                  '${currentDate.year}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                              ] else ...[
                                Text(
                                  '${currentDate.month}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blueGrey.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                              ],
                              Container(
                                width: 2,
                                height: isJan ? 12 : 6,
                                color: isJan
                                    ? Colors.blueGrey
                                    : Colors.blueGrey.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // 期間を持つイベントの矢印を描画
                    ...events.where((e) => e.hasDuration).map((event) {
                      final eventDate = event.dateTime;
                      final endEventDate = event.endDateTime!;
                      final startOffset =
                          ((eventDate.year - startDate.year) * 12) +
                          (eventDate.month - startDate.month);
                      final endOffset =
                          ((endEventDate.year - startDate.year) * 12) +
                          (endEventDate.month - startDate.month);

                      final startXPos = 20.0 + (startOffset * monthWidth);
                      final endXPos = 20.0 + (endOffset * monthWidth);

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
                      final eventDate = event.dateTime;
                      final monthOffset =
                          ((eventDate.year - startDate.year) * 12) +
                          (eventDate.month - startDate.month);
                      final xPos = 20.0 + (monthOffset * monthWidth);

                      final rowTop = event.isWork
                          ? axisHeight
                          : axisHeight + rowHeight;
                      const topPadding = 24.0;

                      final color = eventColor(event);
                      final opacity = eventOpacity(event);

                      return Positioned(
                        left: xPos - 60,
                        top: rowTop + topPadding,
                        child: GestureDetector(
                          onTap: () => _showEventDetails(context, event),
                          child: Opacity(
                            opacity: opacity,
                            child: SizedBox(
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: color,
                                        width: event.isFuturePlan ? 1 : 1,
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
        ],
      ),
    );
  }

  void _showEventDetails(BuildContext context, LifeEvent event) {
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
        content: Column(
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
              '${event.category.label}',
              style: TextStyle(fontSize: 13, color: color),
            ),
            const SizedBox(height: 12),
            Text(event.description),
          ],
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
