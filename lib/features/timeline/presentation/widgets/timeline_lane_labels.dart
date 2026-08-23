import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../timeline_keys.dart';

/// タイムライン左サイドバーの「仕事」「プライベート」レーンラベル。
///
/// `year_timeline.dart` と `year_month_timeline.dart` に byte 単位で重複していた
/// `_buildLaneLabels` を統合したもの（#34, #36）。
Widget buildTimelineLaneLabels({
  required double axisHeight,
  required double rowHeight,
}) {
  return Column(
    children: [
      SizedBox(height: axisHeight),
      _laneLabel(
        laneKey: TimelineKeys.workLane,
        height: rowHeight,
        icon: Icons.work_outline,
        label: '仕事',
        color: AppTheme.primary,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      _laneLabel(
        laneKey: TimelineKeys.privateLane,
        height: rowHeight,
        icon: Icons.favorite_border,
        label: 'プライベート',
        color: AppTheme.secondary,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    ],
  );
}

/// 横書きのアイコン＋ラベルでレーンを示す。
///
/// 旧実装は `RotatedBox(quarterTurns: 3)` で縦回転した日本語を使っていたが、
/// 読みにくいため横書きに変更した（デザイン仕上げ）。
Widget _laneLabel({
  required Key laneKey,
  required double height,
  required IconData icon,
  required String label,
  required Color color,
  required Border border,
}) {
  return Container(
    key: laneKey,
    height: height,
    width: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.03),
      border: border,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}
