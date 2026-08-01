import 'package:flutter/material.dart';
import '../../../catalog/data/predefined_catalog_registry.dart';
import '../../domain/catalog_placement_check.dart';
import '../../domain/life_event.dart';
import '../../domain/timeline_scale.dart';
import '../../domain/year_month.dart';

/// カタログドラッグ中のプレビューゴーストカードを構築する。
///
/// `year_timeline.dart` と `year_month_timeline.dart` に byte 単位で重複していた
/// `_buildDropPreview` / `_previewViolationChip` を統合したもの（#34, #36）。
/// [Positioned] を返すため呼び出し側の [Stack] の直下に置く必要がある
/// （Widget クラス化すると `Positioned` の制約上、そのまま `Stack` の子にできない）。
Widget buildCatalogDropPreview({
  required TimelineScale scale,
  required String catalogId,
  required String date,
  required List<LifeEvent> events,
  required double axisHeight,
  required double rowHeight,
  required double topPadding,
}) {
  final catalog = PredefinedCatalogRegistry.findById(catalogId);
  if (catalog == null) return const SizedBox.shrink();

  final previewYearMonth = YearMonth.parse(date);
  if (!scale.contains(previewYearMonth)) return const SizedBox.shrink();

  final xPos = scale.xOf(previewYearMonth);
  // カタログ項目はプライベートレーン（非work）に配置するプレビュー
  final rowTop = axisHeight + rowHeight;

  final violation = checkCatalogPlacement(
    catalog: catalog,
    at: previewYearMonth,
    events: events,
  );
  final borderColor = switch (violation?.severity) {
    CatalogPlacementSeverity.hard => Colors.red.shade400,
    CatalogPlacementSeverity.soft => Colors.amber.shade400,
    null => catalog.color.withValues(alpha: 0.6),
  };
  final violationMessage = violation?.message;

  final previewDurationMonths = catalog.defaultDurationMonths;
  final barPreviewWidth = previewDurationMonths != null
      ? scale.widthOfMonths(previewDurationMonths).clamp(30.0, double.infinity)
      : null;

  Widget previewBody;
  if (barPreviewWidth != null) {
    previewBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: barPreviewWidth,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: catalog.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0, top: 0, bottom: 0, width: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    catalog.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: catalog.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (violationMessage != null)
          _previewViolationChip(violationMessage, borderColor),
      ],
    );
  } else {
    previewBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 50,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
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
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (violationMessage != null)
          _previewViolationChip(violationMessage, borderColor),
      ],
    );
  }

  return Positioned(
    left: barPreviewWidth != null ? xPos : xPos - 60,
    top: rowTop + topPadding,
    child: IgnorePointer(
      child: Opacity(opacity: 0.6, child: previewBody),
    ),
  );
}

Widget _previewViolationChip(String message, Color color) {
  return Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      message,
      style: TextStyle(
        fontSize: 8,
        color: color,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
