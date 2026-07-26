import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/event_dependency.dart';

/// 依存関係コネクタ線をタイムライン上に描画するウィジェット
///
/// イベント間の依存関係を [CustomPainter] で可視化する透明オーバーレイ。
/// タイムラインウィジェットの [Stack] の最上層に配置して使用する。
class DependencyConnector extends StatelessWidget {
  /// 描画対象の依存関係一覧
  final List<EventDependency> dependencies;

  /// イベントIDをキーとした、タイムライン上のx位置（月オフセット → x座標）
  ///
  /// 値はイベントカード中心のx座標。
  final Map<String, double> eventPositions;

  /// イベントIDをキーとした、仕事レーン（true）かプライベートレーン（false）かのマップ
  final Map<String, bool> eventLanes;

  /// タイムライン全体の高さ
  final double totalHeight;

  /// タイムライン全体の幅
  final double totalWidth;

  /// 軸エリアの高さ
  final double axisHeight;

  /// 各レーンの高さ
  final double rowHeight;

  const DependencyConnector({
    super.key,
    required this.dependencies,
    required this.eventPositions,
    required this.eventLanes,
    required this.totalHeight,
    required this.totalWidth,
    required this.axisHeight,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: CustomPaint(
        painter: DependencyLinePainter(
          dependencies: dependencies,
          eventPositions: eventPositions,
          eventLanes: eventLanes,
          axisHeight: axisHeight,
          rowHeight: rowHeight,
        ),
        size: Size(totalWidth, totalHeight),
      ),
    );
  }
}

/// 依存関係の線を描画する [CustomPainter]
///
/// 関連イベント間を実線＋矢印で描画する。
class DependencyLinePainter extends CustomPainter {
  /// 描画対象の依存関係一覧
  final List<EventDependency> dependencies;

  /// イベントIDをキーとした x 座標マップ
  final Map<String, double> eventPositions;

  /// イベントIDをキーとしたレーン判別マップ（true = 仕事）
  final Map<String, bool> eventLanes;

  /// 軸エリアの高さ
  final double axisHeight;

  /// 各レーンの高さ
  final double rowHeight;

  const DependencyLinePainter({
    required this.dependencies,
    required this.eventPositions,
    required this.eventLanes,
    required this.axisHeight,
    required this.rowHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final dep in dependencies) {
      final sourceX = eventPositions[dep.sourceEventId];
      final targetX = eventPositions[dep.targetEventId];
      final isSourceWork = eventLanes[dep.sourceEventId];
      final isTargetWork = eventLanes[dep.targetEventId];

      // 位置情報が不完全な依存関係はスキップ
      if (sourceX == null ||
          targetX == null ||
          isSourceWork == null ||
          isTargetWork == null) {
        continue;
      }

      final sourceY = _laneY(isSourceWork);
      final targetY = _laneY(isTargetWork);

      final start = Offset(sourceX, sourceY);
      final end = Offset(targetX, targetY);

      _drawLine(canvas, start, end);
    }
  }

  /// レーンのY中心座標を返す（イベントカードの縦中心）
  double _laneY(bool isWork) {
    final rowTop = isWork ? axisHeight : axisHeight + rowHeight;
    // イベントカードはrowTopから24px下にあり、高さ50pxなので中心は +49px
    return rowTop + 24.0 + 25.0;
  }

  void _drawLine(Canvas canvas, Offset start, Offset end) {
    final color = Colors.grey.shade400;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
    _drawArrow(canvas, start, end, color);
  }

  /// 矢印の先端を描画する
  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    const arrowSize = 8.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance < 1) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    // 矢印の左右の羽
    const angle = math.pi / 6; // 30度
    final cos = math.cos(angle);
    final sin = math.sin(angle);

    final leftX = end.dx - arrowSize * (unitX * cos + unitY * sin);
    final leftY = end.dy - arrowSize * (-unitX * sin + unitY * cos);
    final rightX = end.dx - arrowSize * (unitX * cos - unitY * sin);
    final rightY = end.dy - arrowSize * (unitX * sin + unitY * cos);

    canvas.drawLine(end, Offset(leftX, leftY), paint);
    canvas.drawLine(end, Offset(rightX, rightY), paint);
  }

  @override
  bool shouldRepaint(DependencyLinePainter oldDelegate) {
    return oldDelegate.dependencies != dependencies ||
        oldDelegate.eventPositions != eventPositions ||
        oldDelegate.eventLanes != eventLanes;
  }
}
