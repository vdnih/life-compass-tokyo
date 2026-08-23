import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../user_profile/user_profile.dart';
import '../../domain/timeline_scale.dart';

/// タイムラインの縦グリッド線・現在マーカー・軸ラベルを構築する関数群。
///
/// `year_timeline.dart` と `year_month_timeline.dart` に重複していた実装を統合
/// したもの（#34, #36）。両ファイルの差は「1月だけ濃く/大きく表示する」判定
/// （旧 `isJan`）の有無だけだったが、年ビューの [TimelineScale] は
/// `monthsPerSlot: 12` かつ `origin` が常に1月始まりのため、
/// `scale.dateAtSlot(i).month == 1` は年ビューでは常に true になる。
/// そのため月ビュー側の実装をそのまま両ビュー共通に使っても、年ビューの
/// 見た目（全スロットが「1月扱い」＝一律の濃さ・年+年齢のみの表示）は変わらない。
Widget buildTimelineGridLines({
  required double totalHeight,
  required TimelineScale scale,
  required double axisHeight,
  required double rowHeight,
}) {
  final children = <Widget>[
    // 仕事/プライベートの2レーン構造を一目で分かるよう、薄いティントで塗り分ける
    Positioned(
      top: axisHeight,
      left: 0,
      right: 0,
      height: rowHeight,
      child: Container(color: AppTheme.primary.withValues(alpha: 0.025)),
    ),
    Positioned(
      top: axisHeight + rowHeight,
      left: 0,
      right: 0,
      height: rowHeight,
      child: Container(color: AppTheme.secondary.withValues(alpha: 0.025)),
    ),
  ];

  final gridHeight = totalHeight - axisHeight;
  for (int i = 0; i <= scale.slotCount; i++) {
    final xPos = scale.xOfSlot(i);
    final isMajor = scale.dateAtSlot(i).month == 1;
    children.add(
      Positioned(
        left: xPos - 0.5,
        top: axisHeight,
        height: gridHeight,
        child: Container(
          width: isMajor ? 1.0 : 0.5,
          color: isMajor
              ? AppTheme.primary.withValues(alpha: 0.10)
              : AppTheme.primary.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  // 仕事/プライベートの境界線（水平）
  children.add(
    Positioned(
      top: axisHeight + rowHeight,
      left: 0,
      right: 0,
      child: Container(height: 1, color: Colors.grey.shade200),
    ),
  );
  // 軸下の境界線
  children.add(
    Positioned(
      top: axisHeight,
      left: 0,
      right: 0,
      child: Container(
        height: 1,
        color: AppTheme.primary.withValues(alpha: 0.15),
      ),
    ),
  );

  return Stack(children: children);
}

Widget buildTimelineNowMarker({
  required double nowBlockLeft,
  required double slotWidth,
  required double totalHeight,
}) {
  final centerX = nowBlockLeft + slotWidth / 2;
  return Stack(
    children: [
      Positioned(
        left: nowBlockLeft,
        top: 0,
        width: slotWidth,
        height: totalHeight,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.nowMarker.withValues(alpha: 0.08),
            border: Border(
              left: BorderSide(
                color: AppTheme.nowMarker.withValues(alpha: 0.35),
                width: 1,
              ),
              right: BorderSide(
                color: AppTheme.nowMarker.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: centerX - 18,
        top: totalHeight - 18,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.nowMarker,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '現在',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
  );
}

List<Widget> buildTimelineAxisTicks({
  required TimelineScale scale,
  required UserProfile? profile,
  required double axisHeight,
}) {
  return List.generate(scale.slotCount, (index) {
    final currentYearMonth = scale.dateAtSlot(index);
    final currentDate = currentYearMonth.toDateTime();
    final xPos = scale.xCenterOfSlot(index);
    final isMajor = currentYearMonth.month == 1;
    final ageAtDate = profile?.calculateAgeAt(currentDate);

    return Positioned(
      left: xPos - 20,
      top: axisHeight - (isMajor ? 40 : 22),
      child: SizedBox(
        width: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMajor) ...[
              if (ageAtDate != null)
                Text(
                  '$ageAtDate歳',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              Text(
                '${currentDate.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ] else
              Text(
                '${currentDate.month}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.primary.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  });
}
