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

  const DurationEventBar({
    super.key,
    required this.event,
    required this.barWidth,
    this.eventConstraints = const [],
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = eventColor(event);
    final opacity = isDimmed ? 0.3 : eventOpacity(event);
    final hasWarning = eventConstraints.isNotEmpty;

    final userBudget = event.budgetYen;
    final catalogDefault =
        PredefinedCatalogRegistry.findById(event.catalogId)?.defaultBudgetYen;
    final budgetText = userBudget != null
        ? _formatBudget(userBudget)
        : (catalogDefault != null ? _formatBudget(catalogDefault) : null);
    final isDefaultBudget = userBudget == null && catalogDefault != null;

    final effectiveWidth = barWidth.clamp(30.0, double.infinity);

    return Opacity(
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
    );
  }
}
