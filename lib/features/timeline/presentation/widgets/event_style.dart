import 'package:flutter/material.dart';
import '../../domain/life_event.dart';

/// カテゴリごとのアイコンを返す
IconData categoryIcon(EventCategory category) => switch (category) {
  EventCategory.joining => Icons.business_center,
  EventCategory.jobChange => Icons.swap_horiz,
  EventCategory.promotion => Icons.trending_up,
  EventCategory.retirement => Icons.exit_to_app,
  EventCategory.maternityLeave => Icons.pregnant_woman,
  EventCategory.startup => Icons.rocket_launch,
  EventCategory.certification => Icons.workspace_premium,
  EventCategory.sideJob => Icons.work_outline,
  EventCategory.marriage => Icons.favorite,
  EventCategory.childbirth => Icons.child_care,
  EventCategory.childcareLeave => Icons.family_restroom,
  EventCategory.returnToWork => Icons.keyboard_return,
  EventCategory.moving => Icons.home,
  EventCategory.travel => Icons.flight,
  EventCategory.education => Icons.menu_book,
  EventCategory.caregiving => Icons.volunteer_activism,
};

/// カテゴリ別のカラーを返す（Indigo & Rose パレット）
Color categoryColor(EventCategory category) => switch (category) {
  // 仕事系 — インディゴ・ペリウィンクルファミリー
  EventCategory.joining => const Color(0xFF5B7FD4),        // periwinkle blue
  EventCategory.jobChange => const Color(0xFF7B9CE0),       // soft blue
  EventCategory.promotion => const Color(0xFF3D63C3),       // rich blue
  EventCategory.retirement => const Color(0xFF8BA5DE),      // muted blue
  EventCategory.maternityLeave => const Color(0xFFE87EA1),  // blush pink
  EventCategory.startup => const Color(0xFF6B4FA0),         // deep indigo
  EventCategory.certification => const Color(0xFF8B73B5),   // soft purple
  EventCategory.sideJob => const Color(0xFF9DB5E8),         // pale periwinkle
  // プライベート系 — ローズ・ティール・ゴールドファミリー
  EventCategory.marriage => const Color(0xFFD4698F),        // dusty rose
  EventCategory.childbirth => const Color(0xFFE87EA1),      // blush pink
  EventCategory.childcareLeave => const Color(0xFFEC9BB8),  // light blush
  EventCategory.returnToWork => const Color(0xFFD4698F),    // dusty rose
  EventCategory.moving => const Color(0xFF82B38A),          // sage green
  EventCategory.travel => const Color(0xFF7BBFB5),          // teal
  EventCategory.education => const Color(0xFFA08DC0),       // soft purple
  EventCategory.caregiving => const Color(0xFFCCA87A),      // warm gold
};

/// イベントのカラーを返す
Color eventColor(LifeEvent event) => categoryColor(event.category);

/// 将来計画イベントかどうかで透明度を調整
double eventOpacity(LifeEvent event) => event.isFuturePlan ? 0.6 : 1.0;
