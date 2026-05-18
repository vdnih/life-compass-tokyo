import 'package:flutter/material.dart';
import '../../../catalog/data/predefined_catalog_registry.dart';
import '../../domain/constraint_result.dart';
import '../../domain/life_event.dart';
import 'event_style.dart';

/// 予算（円）を表示用テキストに変換する
///
/// 10万以上 → 「¥XXX万」、10万未満 → 「¥XXX円」
String _formatBudget(int yen) {
  if (yen >= 100000) {
    final man = (yen / 10000).round();
    return '¥${man}万';
  }
  return '¥${yen}円';
}

/// タイムライン上に表示するイベントカード
///
/// ドラッグフィードバックやオーバーレイ表示にも再利用される。
class EventCard extends StatelessWidget {
  /// 表示するイベント
  final LifeEvent event;

  /// このイベントに関連する制約違反
  final List<ConstraintResult> eventConstraints;

  /// ドラッグ中の半透明表示フラグ
  final bool isDimmed;

  const EventCard({
    super.key,
    required this.event,
    this.eventConstraints = const [],
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = eventColor(event);
    final opacity = isDimmed ? 0.3 : eventOpacity(event);
    final hasWarning = eventConstraints.isNotEmpty;

    // 予算テキストの解決
    final userBudget = event.budgetYen;
    final catalogDefault =
        PredefinedCatalogRegistry.findById(event.catalogId)?.defaultBudgetYen;
    final budgetText = userBudget != null
        ? _formatBudget(userBudget)
        : (catalogDefault != null ? _formatBudget(catalogDefault) : null);
    final isDefaultBudget = userBudget == null && catalogDefault != null;

    return Opacity(
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
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
                            if (budgetText != null) ...[
                              const SizedBox(height: 2),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
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
              catalogIcon(event.catalogId),
              color: color.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
