import 'package:flutter/material.dart';
import '../../../catalog/data/predefined_catalog_registry.dart';
import '../../domain/constraint_result.dart';
import '../../domain/life_event.dart';
import 'event_style.dart';

String _formatBudget(int yen) {
  if (yen >= 100000) return '¥${(yen / 10000).round()}万';
  return '¥$yen円';
}

/// 期間イベントのバー表示（開始〜終了まで伸びた横長ボックス）
class DurationEventBar extends StatelessWidget {
  final LifeEvent event;
  final double barWidth;
  final List<ConstraintResult> eventConstraints;
  final bool isDimmed;

  /// spike/ai-chat-ux: チャットが直前に追加/展開したイベントであることを示すリング表示
  final bool isHighlighted;

  const DurationEventBar({
    super.key,
    required this.event,
    required this.barWidth,
    this.eventConstraints = const [],
    this.isDimmed = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = eventColor(event);
    final opacity = isDimmed ? 0.3 : eventOpacity(event);
    final badgeStyle = ConstraintBadgeStyle.resolve(eventConstraints);

    final userBudget = event.budgetYen;
    final catalogDefault = PredefinedCatalogRegistry.findById(
      event.catalogId,
    )?.defaultBudgetYen;
    final budgetText = userBudget != null
        ? _formatBudget(userBudget)
        : (catalogDefault != null ? _formatBudget(catalogDefault) : null);
    final isDefaultBudget = userBudget == null && catalogDefault != null;

    final effectiveWidth = barWidth.clamp(30.0, double.infinity);

    return buildHighlightRing(
      isHighlighted: isHighlighted,
      child: Opacity(
        opacity: opacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: effectiveWidth,
                    minWidth: effectiveWidth,
                  ),
                  height: 50,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withValues(alpha: 0.30),
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            if (budgetText != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                budgetText,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  color: isDefaultBudget
                                      ? Colors.grey.shade400
                                      : color.withValues(alpha: 0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeStyle != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: badgeStyle.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        badgeStyle.icon,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (event.isFuturePlan) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
            ],
          ],
        ),
      ),
    );
  }
}
