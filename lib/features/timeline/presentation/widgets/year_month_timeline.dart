import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../user_profile/user_profile.dart';
import '../../domain/constraint_result.dart';
import '../../domain/life_event.dart';
import '../../logic/cascade_move_provider.dart';
import '../../logic/dependency_provider.dart';
import '../../logic/timeline_events_provider.dart';
import '../add_event_dialog.dart';
import 'dependency_connector.dart';
import 'event_card.dart';
import 'event_style.dart';

/// 年月ビューのタイムラインウィジェット
///
/// 月単位でイベントを配置し、依存関係線とドラッグ&ドロップに対応する。
class YearMonthTimeline extends ConsumerStatefulWidget {
  final List<LifeEvent> events;
  final List<ConstraintResult> constraints;

  const YearMonthTimeline({
    super.key,
    required this.events,
    this.constraints = const [],
  });

  @override
  ConsumerState<YearMonthTimeline> createState() => _YearMonthTimelineState();
}

class _YearMonthTimelineState extends ConsumerState<YearMonthTimeline> {
  /// 現在ドラッグ中のイベントID
  String? _draggingEventId;

  /// ドロップターゲットの座標変換用キー
  final _dropTargetKey = GlobalKey();

  static const double monthWidth = 60.0;
  static const double axisHeight = 60.0;
  static const double rowHeight = 160.0;
  static const double sidebarWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    final events = widget.events;

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
    final dependenciesAsync = ref.watch(dependencyProvider);

    final sortedEvents = List<LifeEvent>.from(events)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstDate = sortedEvents.first.dateTime;
    DateTime lastDate = sortedEvents.last.dateTime;
    for (var e in events) {
      if (e.hasDuration && e.endDateTime!.isAfter(lastDate)) {
        lastDate = e.endDateTime!;
      }
    }

    final startDate = DateTime(firstDate.year, firstDate.month - 3);
    final endDate = DateTime(lastDate.year, lastDate.month + 6);
    final totalMonths =
        ((endDate.year - startDate.year) * 12) +
        (endDate.month - startDate.month);

    final now = DateTime.now();
    final nowOffset =
        ((now.year - startDate.year) * 12) + (now.month - startDate.month);
    final nowXPos = 20.0 + (nowOffset * monthWidth);

    // イベント位置マップ（依存コネクタ用）
    final eventPositions = <String, double>{};
    final eventLanes = <String, bool>{};
    for (final event in events) {
      final monthOffset =
          ((event.dateTime.year - startDate.year) * 12) +
          (event.dateTime.month - startDate.month);
      eventPositions[event.id] = 20.0 + (monthOffset * monthWidth);
      eventLanes[event.id] = event.isWork;
    }

    final totalWidth = totalMonths * monthWidth + 100;
    final totalHeight = axisHeight + rowHeight * 2;

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左側の固定レーンラベル
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: SizedBox(
              width: sidebarWidth,
              height: totalHeight,
              child: _buildLaneLabels(),
            ),
          ),
          // 横スクロール可能なタイムライン本体
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.only(top: 40, bottom: 40, right: 40),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) => _handleTap(
                  details,
                  startDate,
                  totalMonths,
                  context,
                ),
                child: SizedBox(
                  width: totalWidth,
                  height: totalHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 境界線・グリッド
                      _buildGridLines(totalHeight),
                      // 現在位置マーカー
                      _buildNowMarker(nowXPos, totalHeight),
                      // 月目盛り
                      ..._buildMonthTicks(
                        totalMonths,
                        startDate,
                        profile,
                        axisHeight,
                      ),
                      // 期間イベントの矢印
                      ..._buildDurationArrows(events, startDate),
                      // 依存関係コネクタオーバーレイ
                      dependenciesAsync.when(
                        data: (deps) => DependencyConnector(
                          dependencies: deps,
                          eventPositions: eventPositions,
                          eventLanes: eventLanes,
                          totalHeight: totalHeight,
                          totalWidth: totalWidth,
                          axisHeight: axisHeight,
                          rowHeight: rowHeight,
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      // ドロップターゲット
                      _buildDropTarget(
                        totalWidth,
                        totalHeight,
                        startDate,
                        totalMonths,
                        events,
                      ),
                      // イベントカード（長押しドラッグ対応）
                      ..._buildEventCards(events, startDate, context),
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

  Widget _buildLaneLabels() {
    return Column(
      children: [
        const SizedBox(height: axisHeight),
        Container(
          height: rowHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
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
    );
  }

  Widget _buildGridLines(double totalHeight) {
    return Stack(
      children: [
        Positioned(
          top: axisHeight + rowHeight,
          left: 0,
          right: 0,
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
        Positioned(
          top: axisHeight,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: AppTheme.primary.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _buildNowMarker(double nowXPos, double totalHeight) {
    return Stack(
      children: [
        Positioned(
          left: nowXPos - 0.75,
          top: 0,
          child: Container(
            width: 1.5,
            height: totalHeight,
            color: AppTheme.nowMarker.withValues(alpha: 0.5),
          ),
        ),
        Positioned(
          left: nowXPos - 18,
          top: totalHeight - 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
      ],
    );
  }

  List<Widget> _buildMonthTicks(
    int totalMonths,
    DateTime startDate,
    dynamic profile,
    double axisH,
  ) {
    return List.generate(totalMonths + 1, (index) {
      final currentDate =
          DateTime(startDate.year, startDate.month + index);
      final xPos = 20.0 + (index * monthWidth);
      final isJan = currentDate.month == 1;
      final ageAtDate = profile.calculateAgeAt(currentDate);

      return Positioned(
        left: xPos - 20,
        top: axisH - (isJan ? 55 : 25),
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
                    color: AppTheme.primary.withValues(alpha: 0.45),
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
    });
  }

  List<Widget> _buildDurationArrows(
    List<LifeEvent> events,
    DateTime startDate,
  ) {
    return events.where((e) => e.hasDuration).map((event) {
      final startOffset =
          ((event.dateTime.year - startDate.year) * 12) +
          (event.dateTime.month - startDate.month);
      final endOffset =
          ((event.endDateTime!.year - startDate.year) * 12) +
          (event.endDateTime!.month - startDate.month);

      final startXPos = 20.0 + (startOffset * monthWidth);
      final endXPos = 20.0 + (endOffset * monthWidth);
      final rowTop =
          event.isWork ? axisHeight : axisHeight + rowHeight;
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
    }).toList();
  }

  /// ドロップターゲット全体（タイムライン領域をカバーする透明レイヤー）
  Widget _buildDropTarget(
    double totalWidth,
    double totalHeight,
    DateTime startDate,
    int totalMonths,
    List<LifeEvent> events,
  ) {
    return Positioned(
      top: axisHeight,
      left: 0,
      width: totalWidth,
      height: rowHeight * 2,
      child: DragTarget<String>(
        key: _dropTargetKey,
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) {
          final eventId = details.data;
          final renderBox =
              _dropTargetKey.currentContext!.findRenderObject()
                  as RenderBox;
          final localOffset = renderBox.globalToLocal(details.offset);
          final dropX = localOffset.dx;
          final monthIndex = ((dropX - 20.0) / monthWidth).floor();
          if (monthIndex < 0 || monthIndex >= totalMonths) return;

          final newDate = DateTime(
            startDate.year,
            startDate.month + monthIndex,
          );
          final newDateStr =
              '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}';

          _applyCascadeMove(eventId, newDateStr, events);
        },
        builder: (context, candidateData, rejectedData) {
          // ドラッグ受け入れ中は薄いハイライト表示
          if (candidateData.isNotEmpty) {
            return Container(
              color: AppTheme.primary.withValues(alpha: 0.05),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// カスケード移動を計算・適用する
  Future<void> _applyCascadeMove(
    String eventId,
    String newDateStr,
    List<LifeEvent> events,
  ) async {
    final depsAsync = ref.read(dependencyProvider);
    final deps = depsAsync.valueOrNull ?? [];

    final changes = computeCascadeUpdates(
      movedEventId: eventId,
      newDate: newDateStr,
      allEvents: events,
      allDependencies: deps,
    );

    if (changes.isEmpty) return;

    for (final change in changes) {
      await ref
          .read(timelineEventsProvider.notifier)
          .moveEvent(change.eventId, change.newDate, newEndDate: change.newEndDate);
    }

    if (mounted) {
      final movedCount = changes.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            movedCount > 1
                ? '$movedCount件のイベントを連動して移動しました'
                : 'イベントを移動しました',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() => _draggingEventId = null);
  }

  List<Widget> _buildEventCards(
    List<LifeEvent> events,
    DateTime startDate,
    BuildContext context,
  ) {
    return events.map((event) {
      final monthOffset =
          ((event.dateTime.year - startDate.year) * 12) +
          (event.dateTime.month - startDate.month);
      final xPos = 20.0 + (monthOffset * monthWidth);
      final rowTop =
          event.isWork ? axisHeight : axisHeight + rowHeight;
      const topPadding = 24.0;

      final eventConstraints = widget.constraints
          .where((c) => c.targetEventTitle == event.title)
          .toList();

      final isDragging = _draggingEventId == event.id;

      return Positioned(
        left: xPos - 60,
        top: rowTop + topPadding,
        child: LongPressDraggable<String>(
          data: event.id,
          delay: const Duration(milliseconds: 400),
          onDragStarted: () {
            setState(() => _draggingEventId = event.id);
          },
          onDraggableCanceled: (_, __) {
            setState(() => _draggingEventId = null);
          },
          onDragEnd: (_) {
            setState(() => _draggingEventId = null);
          },
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.05,
              child: EventCard(
                event: event,
                eventConstraints: eventConstraints,
              ),
            ),
          ),
          childWhenDragging: EventCard(
            event: event,
            eventConstraints: eventConstraints,
            isDimmed: true,
          ),
          child: GestureDetector(
            onTap: () =>
                _showEventDetails(context, event, eventConstraints),
            child: EventCard(
              event: event,
              eventConstraints: eventConstraints,
              isDimmed: isDragging,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _handleTap(
    TapUpDetails details,
    DateTime startDate,
    int totalMonths,
    BuildContext context,
  ) {
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    if (tapY < axisHeight || tapY >= axisHeight + rowHeight * 2) return;

    final monthIndex = ((tapX - 20.0) / monthWidth).floor();
    if (monthIndex < 0 || monthIndex >= totalMonths) return;

    final tappedDate =
        DateTime(startDate.year, startDate.month + monthIndex);
    final isWork = tapY < axisHeight + rowHeight;

    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        initialDate: tappedDate,
        initialIsWork: isWork,
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
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: _EventDetailContent(
          event: event,
          eventConstraints: eventConstraints,
          color: color,
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

/// イベント詳細ダイアログのコンテンツ部分
class _EventDetailContent extends StatelessWidget {
  final LifeEvent event;
  final List<ConstraintResult> eventConstraints;
  final Color color;

  const _EventDetailContent({
    required this.event,
    required this.eventConstraints,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                              ),
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
    );
  }
}
