import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../auth/presentation/auth_required_modal.dart';
import '../../../user_profile/user_profile.dart';
import '../../domain/life_event.dart';
import '../../domain/constraint_result.dart';
import '../add_event_dialog.dart';
import 'event_style.dart';

class YearMonthTimeline extends ConsumerWidget {
  final List<LifeEvent> events;
  final List<ConstraintResult> constraints;

  const YearMonthTimeline({
    super.key,
    required this.events,
    this.constraints = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: AppTheme.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'まだイベントがありません',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '＋ボタンでイベントを追加しましょう',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primary.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      );
    }

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
    const double sidebarWidth = 40.0;

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
              width: sidebarWidth,
              height: axisHeight + rowHeight * 2,
              child: Column(
                children: [
                  const SizedBox(height: axisHeight),
                  // 仕事ラベル
                  Container(
                    height: rowHeight,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        '仕事',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // プライベートラベル
                  Container(
                    height: rowHeight,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                        right: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'プライベート',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.primary,
                          letterSpacing: 1.0,
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

                  final monthIndex = ((tapX - 20.0) / monthWidth).floor();
                  if (monthIndex < 0 || monthIndex >= totalMonths) return;

                  final tappedDate = DateTime(
                    startDate.year,
                    startDate.month + monthIndex,
                  );
                  final isWork = tapY < axisHeight + rowHeight;

                  final userId = ref.read(currentUserIdProvider);
                  if (userId == null) {
                    showAuthRequiredModal(context);
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (context) => AddEventDialog(
                      initialDate: tappedDate,
                      initialIsWork: isWork,
                    ),
                  );
                },
                child: SizedBox(
                width: totalMonths * monthWidth + 100,
                height: axisHeight + rowHeight * 2,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 仕事・プライベートの境界線
                    Positioned(
                      top: axisHeight + rowHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                    ),

                    // メインの横線 (タイムラインのベース)
                    Positioned(
                      top: axisHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: AppTheme.primary.withValues(alpha: 0.15),
                      ),
                    ),

                    // 現在時点マーカー（縦線）
                    Positioned(
                      left: nowXPos - 0.75,
                      top: 0,
                      child: Container(
                        width: 1.5,
                        height: axisHeight + rowHeight * 2,
                        color: AppTheme.nowMarker.withValues(alpha: 0.5),
                      ),
                    ),
                    // 現在時点ラベル（ピル型）
                    Positioned(
                      left: nowXPos - 18,
                      top: axisHeight + rowHeight * 2 - 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.nowMarker,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '現在',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                Text(
                                  '${currentDate.year}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                              ] else ...[
                                Text(
                                  '${currentDate.month}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                              ],
                              Container(
                                width: isJan ? 1.5 : 1,
                                height: isJan ? 12 : 6,
                                color: isJan
                                    ? AppTheme.primary.withValues(alpha: 0.6)
                                    : AppTheme.primary.withValues(alpha: 0.25),
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
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
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
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              bottom: 0,
                                              width: 3,
                                              child: Container(color: color),
                                            ),
                                            Center(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 6,
                                                ),
                                                child: Text(
                                                  event.title,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: color,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (hasWarning)
                                        Positioned(
                                          top: -6,
                                          right: -6,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF8C42),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.warning_rounded,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (event.isFuturePlan)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        event.status.label,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  Icon(
                                    categoryIcon(event.category),
                                    color: color.withValues(alpha: 0.7),
                                    size: 20,
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(categoryIcon(event.category), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 14,
                    color: AppTheme.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.hasDuration
                        ? '${event.date} 〜 ${event.endDate}'
                        : event.date,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      fontSize: 13,
                    ),
                  ),
                  if (event.isFuturePlan) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    event.category.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
              if (eventConstraints.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...eventConstraints.map((c) {
                  final isWarning =
                      c.severity == ConstraintSeverity.warning;
                  final bgColor = isWarning
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFEDE7F6);
                  final borderColor = isWarning
                      ? const Color(0xFFFFB74D)
                      : AppTheme.primary.withValues(alpha: 0.4);
                  final iconColor = isWarning
                      ? const Color(0xFFE65100)
                      : AppTheme.primary;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 3,
                          child: Container(color: borderColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Icon(
                                isWarning
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline,
                                color: iconColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.message,
                                  style: const TextStyle(fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
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
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
