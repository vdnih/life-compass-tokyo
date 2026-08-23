import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../catalog/data/predefined_catalog_registry.dart';
import '../../domain/life_event.dart';

/// catalogId からアイコンを返す
///
/// PredefinedCatalogRegistry に存在しない catalogId の場合は
/// フォールバックアイコン（`Icons.event`）を返す。
IconData catalogIcon(String catalogId) {
  return PredefinedCatalogRegistry.findById(catalogId)?.icon ?? Icons.event;
}

/// catalogId からカラーを返す（Indigo & Rose パレット）
///
/// PredefinedCatalogRegistry に存在しない catalogId の場合は
/// フォールバックカラー（グレー）を返す。
Color catalogColor(String catalogId) {
  return PredefinedCatalogRegistry.findById(catalogId)?.color ??
      const Color(0xFF9E9E9E);
}

/// イベントのカラーを返す
Color eventColor(LifeEvent event) => catalogColor(event.catalogId);

/// 将来計画イベントかどうかで透明度を調整
double eventOpacity(LifeEvent event) => event.isFuturePlan ? 0.6 : 1.0;

/// spike/ai-chat-ux: チャットが直前に追加/展開したイベントであることを示す
/// ハイライトリング。[PointEventMarker] と [DurationEventBar] の両方が使う
/// （リング表示ロジックの重複を避けるための単一の情報源）。
Widget buildHighlightRing({
  required bool isHighlighted,
  required Widget child,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: isHighlighted
          ? Border.all(color: AppTheme.primary, width: 2)
          : null,
      color: isHighlighted ? AppTheme.primary.withValues(alpha: 0.08) : null,
    ),
    child: child,
  );
}
