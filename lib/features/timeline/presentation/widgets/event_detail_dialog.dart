import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../auth/presentation/sign_in_dialog.dart';
import '../../../catalog/data/predefined_catalog_registry.dart';
import '../../domain/constraint_result.dart';
import '../../domain/event_dependency.dart';
import '../../domain/life_event.dart';
import '../../logic/dependency_provider.dart';
import '../../logic/timeline_events_provider.dart';
import '../edit_event_dialog.dart';
import 'event_style.dart';

/// イベント詳細ダイアログを表示する。
///
/// `year_timeline.dart` と `year_month_timeline.dart` に byte 単位で重複していた
/// `_showEventDetails` / `_buildConstraintTile` / `_buildDependencyTile` /
/// `_confirmAndDelete` を統合したもの（#34, #36）。
///
/// 月ビューにのみ存在した連動期間（`offsetMonths`）編集ダイアログは、年ビューに
/// 揃えて削除した。UI として必要かは未決課題として Issue に積む（→ #50）。
///
/// [onRequestLink] は「関連を追加」ボタン押下時に呼ばれる。呼び出し元の State が
/// 持つ関連づけモード（`_linkingEventId`）の開始を委譲するためのコールバック。
void showEventDetailDialog({
  required BuildContext context,
  required WidgetRef ref,
  required LifeEvent event,
  required List<ConstraintResult> eventConstraints,
  required List<LifeEvent> allEvents,
  required VoidCallback onRequestLink,
}) {
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
            child: Icon(catalogIcon(event.catalogId), color: color, size: 20),
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
      content: Consumer(
        builder: (ctx, ref, _) {
          final deps = ref.watch(dependencyProvider).valueOrNull ?? [];
          final relatedDeps = deps
              .where((d) =>
                  d.sourceEventId == event.id || d.targetEventId == event.id)
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
                      style: const TextStyle(
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
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
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
                  ...eventConstraints.map((c) => _buildConstraintTile(c)),
                ],
                if (relatedDeps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      '関連イベント',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  ...relatedDeps.map((dep) =>
                      _buildDependencyTile(ref, dep, event.id, allEvents)),
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
            onRequestLink();
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
              _confirmAndDelete(context, ref, event);
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

Widget _buildConstraintTile(ConstraintResult c) {
  final isWarning = c.severity == ConstraintSeverity.warning;
  final bgColor =
      isWarning ? const Color(0xFFFFF3E0) : const Color(0xFFEDE7F6);
  final borderColor = isWarning
      ? const Color(0xFFFFB74D)
      : AppTheme.primary.withValues(alpha: 0.4);
  final iconColor = isWarning ? const Color(0xFFE65100) : AppTheme.primary;

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    clipBehavior: Clip.antiAlias,
    decoration:
        BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
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
                isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          onPressed: () async {
            await ref.read(dependencyProvider.notifier).removeDependency(dep.id);
          },
          child: const Text('解除', style: TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}

void _confirmAndDelete(
  BuildContext context,
  WidgetRef ref,
  LifeEvent event,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('イベントを削除'),
      content:
          Text('"${event.title}" を削除しますか？\n関連する依存関係も削除されます。'),
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
            await ref.read(timelineEventsProvider.notifier).deleteEvent(event);
          },
          child: const Text('削除'),
        ),
      ],
    ),
  );
}
