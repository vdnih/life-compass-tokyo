import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/constraint_result.dart';
import '../../domain/life_event.dart';
import 'event_style.dart';

/// 単月イベントのマーカー表示（▲ + タイトル）
class PointEventMarker extends StatelessWidget {
  final LifeEvent event;
  final List<ConstraintResult> eventConstraints;
  final bool isDimmed;

  /// spike/ai-chat-ux: チャットが直前に追加/展開したイベントであることを示すリング表示
  final bool isHighlighted;

  /// マーカーの横幅。基準月の X はこの中央（= markerWidth / 2）に来る
  static const double markerWidth = 80.0;

  /// 基準月が属するブロックの左端 X 位置から、マーカー（または対応するイベント）の
  /// 描画左端 / ドラッグ基準点までの左方向オフセット。
  ///
  /// タイムラインは「面（ブロック）」モデルで表示する（ADR-025）。点イベント
  /// （[hasDuration] = false）は三角アイコンをブロック中央に置くため
  /// `(markerWidth - pixelsPerSlot) / 2`。期間イベント（true）はバーの左端が
  /// ブロックの左端そのものなので 0。
  /// 描画時の `leftOffset` 計算とドラッグ&ドロップの着地スロット計算
  /// （`timeline_view.dart` の `_dragAnchorInset`）の双方から参照される、
  /// 単一の情報源。
  static double anchorInset({
    required bool hasDuration,
    required double pixelsPerSlot,
  }) => hasDuration ? 0 : (markerWidth - pixelsPerSlot) / 2;

  const PointEventMarker({
    super.key,
    required this.event,
    this.eventConstraints = const [],
    this.isDimmed = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = eventColor(event);
    final opacity = isDimmed ? 0.3 : eventOpacity(event);
    final hasWarning = eventConstraints.isNotEmpty;

    // spike/ai-chat-ux: 外側に対称 padding で足すため、[anchorInset] が前提とする
    // markerWidth 中心の位置は変わらない（ドラッグ着地計算には影響しない）。
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
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: markerWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  CustomPaint(
                    size: const Size(20, 18),
                    painter: _TrianglePainter(color: color),
                  ),
                  if (hasWarning)
                    Positioned(
                      top: -5,
                      right: 22,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8C42),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 9,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              if (event.isFuturePlan) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.status.label,
                    style: TextStyle(
                      fontSize: 8,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
