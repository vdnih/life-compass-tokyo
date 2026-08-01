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
      Container(
        key: TimelineKeys.workLane,
        height: rowHeight,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Colors.grey.shade200)),
        ),
        child: const RotatedBox(
          quarterTurns: 3,
          child: Text(
            '仕事',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppTheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
      Container(
        key: TimelineKeys.privateLane,
        height: rowHeight,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
            right: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: const RotatedBox(
          quarterTurns: 3,
          child: Text(
            'プライベート',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppTheme.primary,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    ],
  );
}
