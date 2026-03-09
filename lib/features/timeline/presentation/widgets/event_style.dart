import 'package:flutter/material.dart';
import '../../domain/life_event.dart';

/// カテゴリごとのアイコンを返す
IconData categoryIcon(EventCategory category) => switch (category) {
  EventCategory.joining => Icons.business,
  EventCategory.jobChange => Icons.swap_horiz,
  EventCategory.promotion => Icons.trending_up,
  EventCategory.retirement => Icons.exit_to_app,
  EventCategory.maternityLeave => Icons.pregnant_woman,
  EventCategory.startup => Icons.rocket_launch,
  EventCategory.certification => Icons.school,
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

/// カテゴリ別の詳細カラーを返す（産休・育休関連はピンク系）
Color categoryColor(EventCategory category) => switch (category) {
  EventCategory.maternityLeave => Colors.pink.shade300,
  EventCategory.childcareLeave => Colors.pink.shade200,
  EventCategory.childbirth => Colors.pink.shade400,
  _ when category.isWork => Colors.blue,
  _ => Colors.orange,
};

/// イベントのカラーを返す
Color eventColor(LifeEvent event) => categoryColor(event.category);

/// 将来計画イベントかどうかで透明度を調整
double eventOpacity(LifeEvent event) =>
    event.isFuturePlan ? 0.55 : 1.0;
