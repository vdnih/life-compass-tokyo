import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../auth/presentation/sign_in_dialog.dart';
import '../../../catalog/data/predefined_catalog_registry.dart';
import '../../../catalog/domain/predefined_life_event.dart';
import '../../../user_profile/user_profile.dart';
import '../../domain/constraint_result.dart';
import '../../domain/event_dependency.dart';
import '../../domain/life_event.dart';
import '../../logic/cascade_move_provider.dart';
import '../../logic/dependency_provider.dart';
import '../../logic/timeline_events_provider.dart';
import '../add_event_dialog.dart';
import '../edit_event_dialog.dart';
import 'dependency_connector.dart';
import 'event_card.dart';
import 'event_style.dart';
import 'milestone_chip.dart';

const _uuid = Uuid();

/// 年ビューのタイムラインウィジェット
class YearTimeline extends ConsumerStatefulWidget {
  final List<LifeEvent> events;
  final List<ConstraintResult> constraints;

  const YearTimeline({
    super.key,
    required this.events,
    this.constraints = const [],
  });

  @override
  ConsumerState<YearTimeline> createState() => _YearTimelineState();
}

class _YearTimelineState extends ConsumerState<YearTimeline> {
  String? _draggingEventId;
  String? _linkingEventId;
  List<EventDateChange> _cascadePreviewChanges = [];

  /// カタログD&Dホバー中のプレビュー用
  String? _previewCatalogId;
  String? _previewDate;

  final _dropTargetKey = GlobalKey();

  static const double yearWidth = 80.0;
  static const double axisHeight = 60.0;
  static const double sidebarWidth = 40.0;
  static const double _cardHeight = 84.0;
  static const double _topPadding = 24.0;
  static const double _minRowHeight = 160.0;

  double _rowHeight = _minRowHeight;

  // ---- stacking helpers ----

  Map<String, int> _computeStackIndices(
      List<LifeEvent> events, int startYear) {
    final groups = <String, List<String>>{};
    for (final e in events) {
      final offset = e.dateTime.year - startYear;
      final key = '${offset}_${e.isWork}';
      groups.putIfAbsent(key, () => []).add(e.id);
    }
    final indices = <String, int>{};
    for (final group in groups.values) {
      for (int i = 0; i < group.length; i++) {
        indices[group[i]] = i;
      }
    }
    return indices;
  }

  double _computeRowHeight(List<LifeEvent> events, int startYear) {
    if (events.isEmpty) return _minRowHeight;
    final counts = <String, int>{};
    for (final e in events) {
      final offset = e.dateTime.year - startYear;
      final key = '${offset}_${e.isWork}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final maxStack = counts.values.reduce(max);
    return max(_minRowHeight, _topPadding + maxStack * _cardHeight);
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final events = widget.events;

    Widget mainContent;
    if (events.isEmpty) {
      mainContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline,
                size: 64, color: AppTheme.primary.withValues(alpha: 0.25)),
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
    } else {
      final profile = ref.watch(userProfileNotifierProvider).valueOrNull;
      final dependenciesAsync = ref.watch(dependencyProvider);

      final sortedEvents = List<LifeEvent>.from(events)
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      final firstYear = sortedEvents.first.dateTime.year;
      int lastYear = sortedEvents.last.dateTime.year;
      for (var e in events) {
        if (e.hasDuration && e.endDateTime!.year > lastYear) {
          lastYear = e.endDateTime!.year;
        }
      }

      final startYear = firstYear - 2;
      final endYear = lastYear + 3;
      final totalYears = endYear - startYear;

      _rowHeight = _computeRowHeight(events, startYear);
      final stackIndices = _computeStackIndices(events, startYear);

      final now = DateTime.now();
      final nowOffset = now.year - startYear;
      final nowXPos = 20.0 + (nowOffset * yearWidth);

      final eventPositions = <String, double>{};
      final eventLanes = <String, bool>{};
      for (final event in events) {
        final yearOffset = event.dateTime.year - startYear;
        eventPositions[event.id] = 20.0 + (yearOffset * yearWidth);
        eventLanes[event.id] = event.isWork;
      }

      final totalWidth = totalYears * yearWidth + 100;
      final totalHeight = axisHeight + _rowHeight * 2;

      mainContent = SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: SizedBox(
                width: sidebarWidth,
                height: totalHeight,
                child: _buildLaneLabels(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.only(top: 40, bottom: 40, right: 40),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) => _handleTap(
                    details,
                    startYear,
                    totalYears,
                    context,
                  ),
                  child: SizedBox(
                    width: totalWidth,
                    height: totalHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildGridLines(totalHeight),
                        _buildNowMarker(nowXPos, totalHeight),
                        ..._buildYearTicks(
                            totalYears, startYear, profile, axisHeight),
                        ..._buildDurationArrows(
                            events, startYear, stackIndices),
                        dependenciesAsync.when(
                          data: (deps) => DependencyConnector(
                            dependencies: deps,
                            eventPositions: eventPositions,
                            eventLanes: eventLanes,
                            totalHeight: totalHeight,
                            totalWidth: totalWidth,
                            axisHeight: axisHeight,
                            rowHeight: _rowHeight,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        _buildDropTarget(
                          totalWidth,
                          totalHeight,
                          startYear,
                          totalYears,
                          events,
                        ),
                        if (_previewCatalogId != null && _previewDate != null)
                          _buildDropPreview(startYear, totalYears),
                        ..._buildEventCards(
                            events, startYear, stackIndices, context),
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

    return Column(
      children: [
        if (_linkingEventId != null) _buildLinkModeBanner(),
        Expanded(child: mainContent),
      ],
    );
  }

  // ---- link mode banner ----

  Widget _buildLinkModeBanner() {
    return Material(
      color: AppTheme.primary.withValues(alpha: 0.9),
      child: InkWell(
        onTap: () => setState(() => _linkingEventId = null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: const [
              Icon(Icons.link, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '別のイベントをタップして関連づけてください（タップでキャンセル）',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Icon(Icons.close, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ---- lane labels ----

  Widget _buildLaneLabels() {
    return Column(
      children: [
        const SizedBox(height: axisHeight),
        Container(
          height: _rowHeight,
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
          height: _rowHeight,
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
          top: axisHeight + _rowHeight,
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

  List<Widget> _buildYearTicks(
    int totalYears,
    int startYear,
    UserProfile? profile,
    double axisH,
  ) {
    return List.generate(totalYears + 1, (index) {
      final year = startYear + index;
      final xPos = 20.0 + (index * yearWidth);
      final ageAtDate = profile?.calculateAgeAt(DateTime(year, 1));

      return Positioned(
        left: xPos - 20,
        top: axisH - 55,
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
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              Text(
                '$year',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                width: 1.5,
                height: 12,
                color: AppTheme.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildDurationArrows(
    List<LifeEvent> events,
    int startYear,
    Map<String, int> stackIndices,
  ) {
    return events.where((e) => e.hasDuration).map((event) {
      final startOffset = event.dateTime.year - startYear;
      final endOffset = event.endDateTime!.year - startYear;
      final startXPos = 20.0 + (startOffset * yearWidth);
      final endXPos = 20.0 + (endOffset * yearWidth);
      final rowTop = event.isWork ? axisHeight : axisHeight + _rowHeight;
      final stackIdx = stackIndices[event.id] ?? 0;
      final baseTop =
          rowTop + _topPadding + stackIdx * _cardHeight + 50.0 + 4.0;
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
              Icon(Icons.arrow_right,
                  color: color.withValues(alpha: 0.6), size: 16),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// カタログドラッグ中のプレビューゴーストカードを構築する
  Widget _buildDropPreview(int startYear, int totalYears) {
    final catalog = PredefinedCatalogRegistry.findById(_previewCatalogId!);
    if (catalog == null) return const SizedBox.shrink();

    final parts = _previewDate!.split('-');
    final previewYear = int.parse(parts[0]);
    final yearOffset = previewYear - startYear;
    if (yearOffset < 0 || yearOffset >= totalYears) return const SizedBox.shrink();

    final xPos = 20.0 + (yearOffset * yearWidth);
    final rowTop = axisHeight + _rowHeight;

    // 違反チェック
    final events = widget.events;
    final previewDate = DateTime(previewYear, 1);
    Color borderColor = catalog.color.withValues(alpha: 0.6);
    String? violationMessage;

    for (final hardRule in catalog.hardRules) {
      final predecessor = events
          .cast<LifeEvent?>()
          .firstWhere((e) => e!.catalogId == hardRule.predecessorCatalogId,
              orElse: () => null);
      if (predecessor == null) {
        borderColor = Colors.red.shade400;
        violationMessage = hardRule.message;
        break;
      }
      if (hardRule.minMonthsAfter != null) {
        final predParts = predecessor.date.split('-');
        final predDate =
            DateTime(int.parse(predParts[0]), int.parse(predParts[1]));
        final diffMonths = ((previewDate.year - predDate.year) * 12) +
            (previewDate.month - predDate.month);
        if (diffMonths < hardRule.minMonthsAfter!) {
          borderColor = Colors.red.shade400;
          violationMessage = hardRule.message;
          break;
        }
      }
    }

    if (violationMessage == null) {
      for (final softRule in catalog.softRules) {
        final predecessor = events
            .cast<LifeEvent?>()
            .firstWhere((e) => e!.catalogId == softRule.predecessorCatalogId,
                orElse: () => null);
        if (predecessor == null) {
          borderColor = Colors.amber.shade400;
          violationMessage = softRule.message;
          break;
        }
        final predParts = predecessor.date.split('-');
        final predDate =
            DateTime(int.parse(predParts[0]), int.parse(predParts[1]));
        final diffMonths = ((previewDate.year - predDate.year) * 12) +
            (previewDate.month - predDate.month);
        if (diffMonths < softRule.recommendedMinMonthsAfter) {
          borderColor = Colors.amber.shade400;
          violationMessage = softRule.message;
          break;
        }
      }
    }

    return Positioned(
      left: xPos - 60,
      top: rowTop + _topPadding,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 50,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: borderColor, width: 3),
                    top: BorderSide(color: Colors.grey.shade200),
                    right: BorderSide(color: Colors.grey.shade200),
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      catalog.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: catalog.color,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
              if (violationMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    violationMessage,
                    style: TextStyle(
                      fontSize: 8,
                      color: borderColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropTarget(
    double totalWidth,
    double totalHeight,
    int startYear,
    int totalYears,
    List<LifeEvent> events,
  ) {
    return Positioned(
      top: axisHeight,
      left: 0,
      width: totalWidth,
      height: _rowHeight * 2,
      child: DragTarget<Object>(
        key: _dropTargetKey,
        onWillAcceptWithDetails: (_) => true,
        onMove: (details) {
          final renderBox =
              _dropTargetKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final localOffset = renderBox.globalToLocal(details.offset);
          final yearIndex =
              ((localOffset.dx - 20.0) / yearWidth).floor();
          if (yearIndex < 0 || yearIndex >= totalYears) return;

          final newYear = startYear + yearIndex;
          final newDateStr = '$newYear-01';

          final data = details.data;
          if (data is String) {
            if (_draggingEventId == null) return;
            final deps = ref.read(dependencyProvider).valueOrNull ?? [];
            final changes = computeCascadeUpdates(
              movedEventId: _draggingEventId!,
              newDate: newDateStr,
              allEvents: events,
              allDependencies: deps,
            );
            if (mounted) setState(() => _cascadePreviewChanges = changes);
          } else if (data is PredefinedLifeEvent) {
            if (mounted) {
              setState(() {
                _previewCatalogId = data.id;
                _previewDate = newDateStr;
              });
            }
          }
        },
        onLeave: (_) {
          if (mounted) {
            setState(() {
              _cascadePreviewChanges = [];
              _previewCatalogId = null;
              _previewDate = null;
            });
          }
        },
        onAcceptWithDetails: (details) {
          final renderBox =
              _dropTargetKey.currentContext!.findRenderObject() as RenderBox;
          final localOffset = renderBox.globalToLocal(details.offset);
          final yearIndex =
              ((localOffset.dx - 20.0) / yearWidth).floor();
          if (yearIndex < 0 || yearIndex >= totalYears) return;

          final newYear = startYear + yearIndex;
          final newDateStr = '$newYear-01';

          final data = details.data;
          if (data is String) {
            _applyCascadeMove(data, newDateStr, events);
          } else if (data is PredefinedLifeEvent) {
            _applyAddFromCatalog(data, newDateStr);
          }
        },
        builder: (context, candidateData, _) {
          if (candidateData.isNotEmpty) {
            return Container(
                color: AppTheme.primary.withValues(alpha: 0.05));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _applyAddFromCatalog(
    PredefinedLifeEvent catalog,
    String date,
  ) async {
    setState(() {
      _previewCatalogId = null;
      _previewDate = null;
    });
    await ref
        .read(timelineEventsProvider.notifier)
        .addEventFromCatalog(catalog, date);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${catalog.label}」を追加しました'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _applyCascadeMove(
    String eventId,
    String newDateStr,
    List<LifeEvent> events,
  ) async {
    final deps = ref.read(dependencyProvider).valueOrNull ?? [];
    final changes = computeCascadeUpdates(
      movedEventId: eventId,
      newDate: newDateStr,
      allEvents: events,
      allDependencies: deps,
    );

    if (changes.isEmpty) {
      setState(() {
        _draggingEventId = null;
        _cascadePreviewChanges = [];
      });
      return;
    }

    for (final change in changes) {
      await ref
          .read(timelineEventsProvider.notifier)
          .moveEvent(change.eventId, change.newDate,
              newEndDate: change.newEndDate);
    }

    if (mounted) {
      final movedCount = changes.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(movedCount > 1
              ? '$movedCount件のイベントを連動して移動しました'
              : 'イベントを移動しました'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _draggingEventId = null;
        _cascadePreviewChanges = [];
      });
    }
  }

  List<Widget> _buildEventCards(
    List<LifeEvent> events,
    int startYear,
    Map<String, int> stackIndices,
    BuildContext context,
  ) {
    final result = <Widget>[];

    // Cascade preview ghost cards
    if (_draggingEventId != null) {
      for (final change in _cascadePreviewChanges) {
        if (change.eventId == _draggingEventId) continue;
        final event = events
            .cast<LifeEvent?>()
            .firstWhere((e) => e!.id == change.eventId, orElse: () => null);
        if (event == null) continue;

        final parts = change.newDate.split('-');
        final previewYear = int.parse(parts[0]);
        final previewOffset = previewYear - startYear;
        final previewX = 20.0 + (previewOffset * yearWidth);
        final rowTop = event.isWork ? axisHeight : axisHeight + _rowHeight;

        result.add(Positioned(
          left: previewX - 60,
          top: rowTop + _topPadding,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.55,
              child: EventCard(event: event, eventConstraints: const []),
            ),
          ),
        ));
      }
    }

    // Regular event cards (events のみ。milestones は親の下に配置)
    final mainEvents =
        events.where((e) => e.kind == EventKind.event).toList();
    final milestones =
        events.where((e) => e.kind == EventKind.milestone).toList();

    for (final event in mainEvents) {
      final yearOffset = event.dateTime.year - startYear;
      final xPos = 20.0 + (yearOffset * yearWidth);
      final rowTop = event.isWork ? axisHeight : axisHeight + _rowHeight;
      final stackIdx = stackIndices[event.id] ?? 0;
      final topPos = rowTop + _topPadding + stackIdx * _cardHeight;

      final eventConstraints = widget.constraints
          .where((c) => c.targetEventTitle == event.title)
          .toList();

      final isDragging = _draggingEventId == event.id;
      final isInCascade = _draggingEventId != null &&
          _cascadePreviewChanges.any((c) => c.eventId == event.id);

      // 子マイルストーンを収集
      final childMilestones =
          milestones.where((m) => m.parentEventId == event.id).toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      final color = eventColor(event);

      result.add(Positioned(
        left: xPos - 60,
        top: topPos,
        child: LongPressDraggable<String>(
          data: event.id,
          delay: const Duration(milliseconds: 400),
          onDragStarted: () {
            setState(() => _draggingEventId = event.id);
          },
          onDraggableCanceled: (_, __) {
            setState(() {
              _draggingEventId = null;
              _cascadePreviewChanges = [];
            });
          },
          onDragEnd: (_) {
            setState(() {
              _draggingEventId = null;
              _cascadePreviewChanges = [];
            });
          },
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.05,
              child: EventCard(
                  event: event, eventConstraints: eventConstraints),
            ),
          ),
          childWhenDragging: EventCard(
            event: event,
            eventConstraints: eventConstraints,
            isDimmed: true,
          ),
          child: GestureDetector(
            onTap: () {
              if (_linkingEventId != null) {
                _handleLinkTap(event, events);
              } else {
                _showEventDetails(context, event, eventConstraints, events);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                EventCard(
                  event: event,
                  eventConstraints: eventConstraints,
                  isDimmed: isDragging || (isInCascade && !isDragging),
                ),
                if (childMilestones.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: childMilestones
                          .map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: MilestoneChip(
                                  milestone: m,
                                  parentColor: color,
                                  onDelete: () =>
                                      _deleteEvent(context, m),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ));
    }

    return result;
  }

  Future<void> _deleteEvent(BuildContext context, LifeEvent event) async {
    await ref.read(timelineEventsProvider.notifier).deleteEvent(event);
  }

  void _handleTap(
    TapUpDetails details,
    int startYear,
    int totalYears,
    BuildContext context,
  ) {
    if (_linkingEventId != null) {
      setState(() => _linkingEventId = null);
      return;
    }

    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    if (tapY < axisHeight || tapY >= axisHeight + _rowHeight * 2) return;

    final yearIndex = ((tapX - 20.0) / yearWidth).floor();
    if (yearIndex < 0 || yearIndex >= totalYears) return;

    final tappedDate = DateTime(startYear + yearIndex, 1);
    final isWork = tapY < axisHeight + _rowHeight;

    if (ref.read(authStateProvider).valueOrNull == null) {
      showDialog<void>(context: context, builder: (_) => const SignInDialog());
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          AddEventDialog(initialDate: tappedDate, initialIsWork: isWork),
    );
  }

  // ---- link mode ----

  Future<void> _handleLinkTap(
      LifeEvent targetEvent, List<LifeEvent> allEvents) async {
    if (targetEvent.id == _linkingEventId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('同じイベントには関連づけできません'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final notifier = ref.read(dependencyProvider.notifier);
    if (notifier.wouldCreateCycle(_linkingEventId!, targetEvent.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('循環した関連は設定できません'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final sourceEvent = allEvents
        .cast<LifeEvent?>()
        .firstWhere((e) => e!.id == _linkingEventId, orElse: () => null);
    if (sourceEvent == null) return;

    final srcParts = sourceEvent.date.split('-');
    final tgtParts = targetEvent.date.split('-');
    final offsetMonths =
        (int.parse(tgtParts[0]) * 12 + int.parse(tgtParts[1])) -
            (int.parse(srcParts[0]) * 12 + int.parse(srcParts[1]));

    final dep = EventDependency(
      id: _uuid.v4(),
      sourceEventId: _linkingEventId!,
      targetEventId: targetEvent.id,
      offsetMonths: offsetMonths,
    );

    await ref.read(dependencyProvider.notifier).addDependency(dep);

    if (mounted) {
      setState(() => _linkingEventId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('関連を追加しました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---- event details dialog ----

  void _showEventDetails(
    BuildContext context,
    LifeEvent event,
    List<ConstraintResult> eventConstraints,
    List<LifeEvent> allEvents,
  ) {
    final color = eventColor(event);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(catalogIcon(event.catalogId), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Consumer(
          builder: (ctx, ref, _) {
            final deps = ref.watch(dependencyProvider).valueOrNull ?? [];
            final relatedDeps = deps
                .where((d) =>
                    d.sourceEventId == event.id ||
                    d.targetEventId == event.id)
                .toList();

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 14,
                          color: AppTheme.primary.withValues(alpha: 0.6)),
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
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.status.label,
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600),
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
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                          PredefinedCatalogRegistry.findById(event.catalogId)
                                  ?.label ??
                              event.catalogId,
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(event.description,
                        style: const TextStyle(fontSize: 13, height: 1.5)),
                  ],
                  if (eventConstraints.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...eventConstraints
                        .map((c) => _buildConstraintTile(c, color)),
                  ],
                  if (relatedDeps.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        '関連イベント',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    ...relatedDeps.map((dep) => _buildDependencyTile(
                        dialogCtx, ref, dep, event.id, allEvents)),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() => _linkingEventId = event.id);
            },
            child: const Text('関連を追加'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (ref.read(authStateProvider).valueOrNull == null) {
                showDialog<void>(
                  context: context,
                  builder: (_) => const SignInDialog(),
                );
              } else {
                _confirmAndDelete(context, event);
              }
            },
            child: const Text('削除'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (ref.read(authStateProvider).valueOrNull == null) {
                showDialog<void>(
                  context: context,
                  builder: (_) => const SignInDialog(),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (_) => EditEventDialog(event: event),
                );
              }
            },
            child: const Text('編集'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildConstraintTile(ConstraintResult c, Color color) {
    final isWarning = c.severity == ConstraintSeverity.warning;
    final bgColor =
        isWarning ? const Color(0xFFFFF3E0) : const Color(0xFFEDE7F6);
    final borderColor = isWarning
        ? const Color(0xFFFFB74D)
        : AppTheme.primary.withValues(alpha: 0.4);
    final iconColor =
        isWarning ? const Color(0xFFE65100) : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(color: borderColor)),
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
                  child: Text(c.message,
                      style: const TextStyle(fontSize: 12, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDependencyTile(
    BuildContext dialogCtx,
    WidgetRef ref,
    EventDependency dep,
    String currentEventId,
    List<LifeEvent> allEvents,
  ) {
    final otherEventId = dep.sourceEventId == currentEventId
        ? dep.targetEventId
        : dep.sourceEventId;
    final otherEvent = allEvents
        .cast<LifeEvent?>()
        .firstWhere((e) => e!.id == otherEventId, orElse: () => null);
    final otherTitle = otherEvent?.title ?? '(不明なイベント)';
    final isSource = dep.sourceEventId == currentEventId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isSource ? Icons.arrow_forward : Icons.arrow_back,
            size: 14,
            color: AppTheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherTitle,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Text('関連',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary.withValues(alpha: 0.6))),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onPressed: () async {
              await ref
                  .read(dependencyProvider.notifier)
                  .removeDependency(dep.id);
            },
            child: const Text('解除', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _confirmAndDelete(BuildContext context, LifeEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('イベントを削除'),
        content: Text(
            '"${event.title}" を削除しますか？\n関連する依存関係も削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(dependencyProvider.notifier)
                  .removeDependenciesForEvent(event.id);
              await ref
                  .read(timelineEventsProvider.notifier)
                  .deleteEvent(event);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
