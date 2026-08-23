import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../catalog/data/predefined_catalog_registry.dart';
import '../../domain/constraint_result.dart';
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

/// イベントカード/マーカー/バーの右上に出す制約バッジの見た目。
///
/// [EventCard] / [PointEventMarker] / [DurationEventBar] の3箇所が同じ
/// severity 優先度（warning > info、両方無ければバッジ無し）で分岐していた
/// ため、判定と配色をここに集約する（PDR-008: info を警告バッジで
/// 表示しない）。
@immutable
class ConstraintBadgeStyle {
  final Color color;
  final IconData icon;

  const ConstraintBadgeStyle._(this.color, this.icon);

  static const _warning = ConstraintBadgeStyle._(
    Color(0xFFFF8C42),
    Icons.warning_rounded,
  );
  static const _info = ConstraintBadgeStyle._(
    AppTheme.primary,
    Icons.info_outline,
  );

  /// [constraints] が空、またはこのバッジを表示すべきでない場合は null
  static ConstraintBadgeStyle? resolve(List<ConstraintResult> constraints) {
    if (constraints.isEmpty) return null;
    final hasWarning = constraints.any(
      (c) => c.severity == ConstraintSeverity.warning,
    );
    return hasWarning ? _warning : _info;
  }
}

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
