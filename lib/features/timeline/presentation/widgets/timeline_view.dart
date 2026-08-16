import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../ai_coach/presentation/highlight_provider.dart';
import '../../../catalog/domain/predefined_life_event.dart';
import '../../../user_profile/user_profile.dart';
import '../../domain/constraint_result.dart';
import '../../domain/event_dependency.dart';
import '../../domain/event_stacking.dart';
import '../../domain/life_event.dart';
import '../../domain/timeline_scale.dart';
import '../../domain/year_month.dart';
import '../../logic/cascade_move_provider.dart';
import '../../logic/dependency_provider.dart';
import '../../logic/timeline_events_provider.dart';
import '../add_event_dialog.dart';
import 'catalog_drop_preview.dart';
import 'dependency_connector.dart';
import 'duration_event_bar.dart';
import 'event_card.dart';
import 'event_detail_dialog.dart';
import 'point_event_marker.dart';
import 'timeline_axis.dart';
import 'timeline_lane_labels.dart';

const _uuid = Uuid();

/// タイムラインの表示単位。
///
/// 年ビュー・月ビューは表示単位（1スロットが何ヶ月を表すか）が違うだけで、
/// 座標変換・D&D・制約チェックの実装は全て共通のため、フィールドの違いとして
/// 1つの [TimelineView] に統合した（#34, #36）。
/// 従来 `year_timeline.dart` / `year_month_timeline.dart` として別ファイルに
/// 存在していた（CLAUDE.md §4 が「リファクタリングの筆頭課題」と記載していた重複）。
enum TimelineViewMode {
  yearMonth(
    pixelsPerSlot: 60.0,
    monthsPerSlot: 1,
    defaultBackSlots: 60,
    defaultForwardSlots: 180,
    eventBackPadSlots: 3,
    eventForwardPadSlots: 6,
    heroTag: 'scrollToNowMonth',
    scrollTooltip: '今月に戻る',
  ),
  year(
    pixelsPerSlot: 80.0,
    monthsPerSlot: 12,
    defaultBackSlots: 5,
    defaultForwardSlots: 15,
    eventBackPadSlots: 2,
    eventForwardPadSlots: 3,
    heroTag: 'scrollToNowYear',
    scrollTooltip: '今年に戻る',
  );

  const TimelineViewMode({
    required this.pixelsPerSlot,
    required this.monthsPerSlot,
    required this.defaultBackSlots,
    required this.defaultForwardSlots,
    required this.eventBackPadSlots,
    required this.eventForwardPadSlots,
    required this.heroTag,
    required this.scrollTooltip,
  });

  /// 1スロットあたりのピクセル幅
  final double pixelsPerSlot;

  /// 1スロットが表す月数（月ビュー: 1、年ビュー: 12）
  final int monthsPerSlot;

  /// 現在からデフォルトで確保する過去側の表示範囲（スロット単位）
  final int defaultBackSlots;

  /// 現在からデフォルトで確保する未来側の表示範囲（スロット単位）
  final int defaultForwardSlots;

  /// 表示範囲外にイベントがある場合、最初のイベントからさらに広げる過去側の余白（スロット単位）
  final int eventBackPadSlots;

  /// 表示範囲外にイベントがある場合、最後のイベントからさらに広げる未来側の余白（スロット単位）
  final int eventForwardPadSlots;

  /// 「現在に戻る」FAB の [Hero] タグ（同一画面に両ビューの FAB が重ならないよう分ける）
  final String heroTag;

  /// 「現在に戻る」FAB のツールチップ文言
  final String scrollTooltip;

  /// [ym] をこのビューのスロット境界に正規化する（年ビューは常に1月に丸める）
  YearMonth anchorOf(YearMonth ym) =>
      monthsPerSlot == 12 ? YearMonth(ym.year, 1) : ym;
}

/// 年ビュー・月ビュー共通のタイムラインウィジェット。[mode] で表示単位を切り替える。
class TimelineView extends ConsumerStatefulWidget {
  final TimelineViewMode mode;
  final List<LifeEvent> events;
  final List<ConstraintResult> constraints;

  const TimelineView({
    super.key,
    required this.mode,
    required this.events,
    this.constraints = const [],
  });

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  String? _draggingEventId;
  String? _linkingEventId;
  List<EventDateChange> _cascadePreviewChanges = [];

  /// カタログD&Dホバー中のプレビュー用
  String? _previewCatalogId;
  String? _previewDate;

  /// ドラッグ中のスナップ先スロットインデックス（マグネティックUI用）
  int? _snapSlotIndex;

  final _dropTargetKey = GlobalKey();

  static const double axisHeight = 60.0;
  static const double sidebarWidth = 40.0;
  static const double _cardHeight = 84.0;
  static const double _topPadding = 24.0;
  static const double _minRowHeight = 160.0;

  double _rowHeight = _minRowHeight;

  // ---- scroll ----
  final ScrollController _horizontalScrollController = ScrollController();
  bool _hasScrolledToNow = false;

  /// build() の最後に更新される最新の [TimelineScale]。
  /// spike/ai-chat-ux: チャットからの自動スクロール（[_animateTo]）が
  /// build 外（[ref.listen] コールバック）から呼ばれるために保持する。
  TimelineScale? _lastScale;

  /// spike/ai-chat-ux: チャットが直前にハイライトしたイベントID
  Set<String> _highlightedEventIds = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// 表示範囲の起点となる「デフォルト5年前 / 5年後」等に相当するスロット0の
  /// [TimelineScale] を組み立てる（現在位置スクロール専用。表示範囲全体は [_buildScale]）
  TimelineScale _scaleForScrollToNow(YearMonth nowAnchor) {
    final origin = nowAnchor.addMonths(
      -widget.mode.defaultBackSlots * widget.mode.monthsPerSlot,
    );
    return TimelineScale(
      origin: origin,
      pixelsPerSlot: widget.mode.pixelsPerSlot,
      monthsPerSlot: widget.mode.monthsPerSlot,
      slotCount: 0,
    );
  }

  void _scrollToNow() {
    if (_hasScrolledToNow) return;
    if (!_horizontalScrollController.hasClients) return;
    final nowAnchor = widget.mode.anchorOf(
      YearMonth.fromDateTime(DateTime.now()),
    );
    final scale = _scaleForScrollToNow(nowAnchor);
    final nowXPos = scale.xOf(nowAnchor);
    final viewportWidth =
        _horizontalScrollController.position.viewportDimension;
    final targetOffset = (nowXPos - viewportWidth / 2).clamp(
      0.0,
      _horizontalScrollController.position.maxScrollExtent,
    );
    _horizontalScrollController.jumpTo(targetOffset);
    _hasScrolledToNow = true;
  }

  void _animateToNow() {
    final nowAnchor = widget.mode.anchorOf(
      YearMonth.fromDateTime(DateTime.now()),
    );
    _animateTo(nowAnchor, scale: _scaleForScrollToNow(nowAnchor));
  }

  /// spike/ai-chat-ux: 任意の年月へアニメーション付きでスクロールする。
  /// [_animateToNow] の一般化。チャットがテンプレートを展開した直後、
  /// ゴール年月へスクロールして「書き換わった瞬間」を見せるために使う。
  ///
  /// [scale] を省略すると直近の build() で使われた [_lastScale] を使う
  /// （表示範囲全体をカバーするスケールなので、任意の年月に対応できる）。
  void _animateTo(YearMonth target, {TimelineScale? scale}) {
    if (!_horizontalScrollController.hasClients) return;
    final effectiveScale = scale ?? _lastScale;
    if (effectiveScale == null) return;
    final xPos = effectiveScale.xOf(target);
    final viewportWidth =
        _horizontalScrollController.position.viewportDimension;
    final targetOffset = (xPos - viewportWidth / 2).clamp(
      0.0,
      _horizontalScrollController.position.maxScrollExtent,
    );
    _horizontalScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  /// 表示範囲全体をカバーする [TimelineScale] を組み立てる。
  ///
  /// 常にデフォルト範囲（現在 -[TimelineViewMode.defaultBackSlots] 〜
  /// +[TimelineViewMode.defaultForwardSlots]）を確保し、範囲外にイベントがあれば
  /// [TimelineViewMode.eventBackPadSlots] / [eventForwardPadSlots] 分の余白を
  /// 追加してさらに広げる。
  TimelineScale _buildScale(List<LifeEvent> events, DateTime now) {
    final mode = widget.mode;
    final nowAnchor = mode.anchorOf(YearMonth.fromDateTime(now));
    var origin = nowAnchor.addMonths(
      -mode.defaultBackSlots * mode.monthsPerSlot,
    );
    var endBoundary = nowAnchor.addMonths(
      mode.defaultForwardSlots * mode.monthsPerSlot,
    );

    if (events.isNotEmpty) {
      final sorted = List<LifeEvent>.from(events)
        ..sort((a, b) => a.yearMonth.compareTo(b.yearMonth));
      final firstAnchor = mode.anchorOf(sorted.first.yearMonth);
      var lastAnchor = mode.anchorOf(sorted.last.yearMonth);
      for (final e in events) {
        if (e.hasDuration) {
          final endAnchor = mode.anchorOf(e.endYearMonth!);
          if (endAnchor.isAfter(lastAnchor)) lastAnchor = endAnchor;
        }
      }
      if (firstAnchor.isBefore(origin)) {
        origin = firstAnchor.addMonths(
          -mode.eventBackPadSlots * mode.monthsPerSlot,
        );
      }
      if (lastAnchor.isAfter(endBoundary)) {
        endBoundary = lastAnchor.addMonths(
          mode.eventForwardPadSlots * mode.monthsPerSlot,
        );
      }
    }

    final slotCount =
        endBoundary.differenceInMonths(origin) ~/ mode.monthsPerSlot;
    return TimelineScale(
      origin: origin,
      pixelsPerSlot: mode.pixelsPerSlot,
      monthsPerSlot: mode.monthsPerSlot,
      slotCount: slotCount,
    );
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final now = DateTime.now();
    final scale = _buildScale(events, now);
    _lastScale = scale;

    final profile = ref.watch(userProfileNotifierProvider).value;
    final dependenciesAsync = ref.watch(dependencyProvider);

    // spike/ai-chat-ux: チャットがテンプレートを展開したら、対象イベントをリング表示し
    // ゴール年月へ自動スクロールする。ハイライトのみの変化（Undo 後のクリア等）では
    // スクロールしない -- focusYearMonth が変わった時だけトリガーする。
    final highlight = ref.watch(chatHighlightProvider);
    _highlightedEventIds = highlight.eventIds;
    ref.listen<ChatHighlight>(chatHighlightProvider, (previous, next) {
      final target = next.focusYearMonth;
      if (target == null) return;
      if (previous?.focusYearMonth == target) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _animateTo(target));
    });

    final stackIndices = computeStackIndices(events, scale);
    _rowHeight = computeStackedRowHeight(
      stackIndices: stackIndices,
      events: events,
      minRowHeight: _minRowHeight,
      topPadding: _topPadding,
      cardHeight: _cardHeight,
    );

    final nowXPos = scale.xOf(
      widget.mode.anchorOf(YearMonth.fromDateTime(now)),
    );

    final eventPositions = <String, double>{};
    final eventLanes = <String, bool>{};
    for (final event in events) {
      eventPositions[event.id] = scale.xOf(event.yearMonth);
      eventLanes[event.id] = event.isWork;
    }

    final totalWidth = scale.totalWidth;
    final totalHeight = axisHeight + _rowHeight * 2;

    final timelineContent = SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: SizedBox(
              width: sidebarWidth,
              height: totalHeight,
              child: buildTimelineLaneLabels(
                axisHeight: axisHeight,
                rowHeight: _rowHeight,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(top: 40, bottom: 40, right: 40),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) => _handleTap(details, scale, context),
                child: SizedBox(
                  width: totalWidth,
                  height: totalHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      buildTimelineGridLines(
                        totalHeight: totalHeight,
                        scale: scale,
                        axisHeight: axisHeight,
                        rowHeight: _rowHeight,
                      ),
                      buildTimelineNowMarker(
                        nowXPos: nowXPos,
                        totalHeight: totalHeight,
                      ),
                      ...buildTimelineAxisTicks(
                        scale: scale,
                        profile: profile,
                        axisHeight: axisHeight,
                      ),
                      if (events.isNotEmpty) ...[
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
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                      _buildDropTarget(totalWidth, totalHeight, scale, events),
                      if (_previewCatalogId != null && _previewDate != null)
                        buildCatalogDropPreview(
                          scale: scale,
                          catalogId: _previewCatalogId!,
                          date: _previewDate!,
                          events: widget.events,
                          axisHeight: axisHeight,
                          rowHeight: _rowHeight,
                          topPadding: _topPadding,
                        ),
                      if (events.isNotEmpty)
                        ..._buildEventCards(
                          events,
                          scale,
                          stackIndices,
                          context,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final Widget mainContent = events.isEmpty
        ? Stack(
            children: [
              timelineContent,
              IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 48,
                          color: AppTheme.primary.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'まだイベントがありません',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '＋ボタンでイベントを追加しましょう',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        : timelineContent;

    return Column(
      children: [
        if (_linkingEventId != null) _buildLinkModeBanner(),
        Expanded(
          child: Stack(
            children: [
              mainContent,
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: widget.mode.heroTag,
                  tooltip: widget.mode.scrollTooltip,
                  onPressed: _animateToNow,
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.today, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
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
          child: const Row(
            children: [
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

  // ---- drop target ----

  Widget _buildDropTarget(
    double totalWidth,
    double totalHeight,
    TimelineScale scale,
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
          final slotIndex = scale.slotIndexAt(localOffset.dx);
          if (!scale.containsSlot(slotIndex)) return;

          final newDateStr = scale.dateAtSlot(slotIndex).toString();

          if (mounted && _snapSlotIndex != slotIndex) {
            setState(() => _snapSlotIndex = slotIndex);
          }

          final data = details.data;
          if (data is String) {
            if (_draggingEventId == null) return;
            final deps = ref.read(dependencyProvider).value ?? [];
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
              _snapSlotIndex = null;
            });
          }
        },
        onAcceptWithDetails: (details) {
          final renderBox =
              _dropTargetKey.currentContext!.findRenderObject() as RenderBox;
          final localOffset = renderBox.globalToLocal(details.offset);
          final slotIndex = scale.slotIndexAt(localOffset.dx);
          if (!scale.containsSlot(slotIndex)) return;

          final newDateStr = scale.dateAtSlot(slotIndex).toString();

          if (mounted) setState(() => _snapSlotIndex = null);

          final data = details.data;
          if (data is String) {
            _applyCascadeMove(data, newDateStr, events);
          } else if (data is PredefinedLifeEvent) {
            _applyAddFromCatalog(data, newDateStr);
          }
        },
        builder: (context, candidateData, _) {
          if (candidateData.isEmpty || _snapSlotIndex == null) {
            return const SizedBox.shrink();
          }
          final xPos = scale.xOfSlot(_snapSlotIndex!);
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: AppTheme.primary.withValues(alpha: 0.04),
                ),
              ),
              Positioned(
                left: xPos,
                top: 0,
                width: widget.mode.pixelsPerSlot,
                height: _rowHeight * 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.14),
                    border: Border(
                      left: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      right: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
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
    final deps = ref.read(dependencyProvider).value ?? [];
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
          .moveEvent(
            change.eventId,
            change.newDate,
            newEndDate: change.newEndDate,
          );
    }

    if (mounted) {
      final movedCount = changes.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            movedCount > 1 ? '$movedCount件のイベントを連動して移動しました' : 'イベントを移動しました',
          ),
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

  // ---- event cards ----

  List<Widget> _buildEventCards(
    List<LifeEvent> events,
    TimelineScale scale,
    Map<String, int> stackIndices,
    BuildContext context,
  ) {
    final result = <Widget>[];

    // Cascade preview ghost cards (below regular cards)
    //
    // ドロップ確定後の実カードと同じ xOf() で位置を出す（小数位置）。
    if (_draggingEventId != null) {
      for (final change in _cascadePreviewChanges) {
        if (change.eventId == _draggingEventId) continue;
        final event = events.cast<LifeEvent?>().firstWhere(
          (e) => e!.id == change.eventId,
          orElse: () => null,
        );
        if (event == null) continue;

        final previewX = scale.xOf(YearMonth.parse(change.newDate));
        final rowTop = event.isWork ? axisHeight : axisHeight + _rowHeight;

        result.add(
          Positioned(
            left: previewX - 60,
            top: rowTop + _topPadding,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.55,
                child: EventCard(event: event, eventConstraints: const []),
              ),
            ),
          ),
        );
      }
    }

    for (final event in events) {
      final xPos = scale.xOf(event.yearMonth);
      final rowTop = event.isWork ? axisHeight : axisHeight + _rowHeight;
      final stackIdx = stackIndices[event.id] ?? 0;
      final topPos = rowTop + _topPadding + stackIdx * _cardHeight;

      double barWidth = 0;
      if (event.hasDuration) {
        barWidth = (scale.xOf(event.endYearMonth!) - xPos).clamp(
          30.0,
          double.infinity,
        );
      }

      final leftOffset = event.hasDuration ? xPos : xPos - 40;

      final eventConstraints = widget.constraints
          .where((c) => c.targetEventTitle == event.title)
          .toList();

      final isDragging = _draggingEventId == event.id;
      final isInCascade =
          _draggingEventId != null &&
          _cascadePreviewChanges.any((c) => c.eventId == event.id);
      final isHighlighted = _highlightedEventIds.contains(event.id);

      result.add(
        Positioned(
          left: leftOffset,
          top: topPos,
          // Listener でトラックパッドの pan/zoom イベントを吸収し、
          // LongPressDraggable が trackpad wheel イベントで assertion エラーを起こすのを防ぐ。
          child: Listener(
            onPointerPanZoomStart: (_) {},
            child: LongPressDraggable<String>(
              data: event.id,
              delay: const Duration(milliseconds: 400),
              onDragStarted: () {
                setState(() => _draggingEventId = event.id);
              },
              onDraggableCanceled: (_, _) {
                setState(() {
                  _draggingEventId = null;
                  _cascadePreviewChanges = [];
                  _snapSlotIndex = null;
                });
              },
              onDragEnd: (_) {
                setState(() {
                  _draggingEventId = null;
                  _cascadePreviewChanges = [];
                  _snapSlotIndex = null;
                });
              },
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.05,
                  child: event.hasDuration
                      ? DurationEventBar(
                          event: event,
                          barWidth: barWidth.clamp(80.0, 200.0),
                          eventConstraints: eventConstraints,
                        )
                      : PointEventMarker(
                          event: event,
                          eventConstraints: eventConstraints,
                        ),
                ),
              ),
              childWhenDragging: event.hasDuration
                  ? DurationEventBar(
                      event: event,
                      barWidth: barWidth,
                      eventConstraints: eventConstraints,
                      isDimmed: true,
                    )
                  : PointEventMarker(
                      event: event,
                      eventConstraints: eventConstraints,
                      isDimmed: true,
                    ),
              child: GestureDetector(
                // マーカーの Column は三角アイコンとラベルの間に無地の余白があり、
                // デフォルトの HitTestBehavior.deferToChild だとその余白のタップが
                // 背景の GestureDetector（タップで新規追加 = _handleTap）に抜けて、
                // ゲストには常にサインインダイアログが出てしまっていた。
                // opaque にしてマーカー全体の矩形でタップを確定させる。
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_linkingEventId != null) {
                    _handleLinkTap(event, events);
                  } else {
                    showEventDetailDialog(
                      context: context,
                      ref: ref,
                      event: event,
                      eventConstraints: eventConstraints,
                      allEvents: events,
                      onRequestLink: () =>
                          setState(() => _linkingEventId = event.id),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (event.hasDuration)
                      DurationEventBar(
                        event: event,
                        barWidth: barWidth,
                        eventConstraints: eventConstraints,
                        isDimmed: isDragging || (isInCascade && !isDragging),
                        isHighlighted: isHighlighted,
                      )
                    else
                      PointEventMarker(
                        event: event,
                        eventConstraints: eventConstraints,
                        isDimmed: isDragging || (isInCascade && !isDragging),
                        isHighlighted: isHighlighted,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return result;
  }

  // ---- tap / link mode ----

  void _handleTap(
    TapUpDetails details,
    TimelineScale scale,
    BuildContext context,
  ) {
    if (_linkingEventId != null) {
      setState(() => _linkingEventId = null);
      return;
    }

    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    if (tapY < axisHeight || tapY >= axisHeight + _rowHeight * 2) return;

    final slotIndex = scale.slotIndexAt(tapX);
    if (!scale.containsSlot(slotIndex)) return;

    final tappedDate = scale.dateAtSlot(slotIndex).toDateTime();
    final isWork = tapY < axisHeight + _rowHeight;

    showDialog(
      context: context,
      builder: (context) =>
          AddEventDialog(initialDate: tappedDate, initialIsWork: isWork),
    );
  }

  Future<void> _handleLinkTap(
    LifeEvent targetEvent,
    List<LifeEvent> allEvents,
  ) async {
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

    final sourceEvent = allEvents.cast<LifeEvent?>().firstWhere(
      (e) => e!.id == _linkingEventId,
      orElse: () => null,
    );
    if (sourceEvent == null) return;

    final offsetMonths = targetEvent.yearMonth.differenceInMonths(
      sourceEvent.yearMonth,
    );

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
}
