import 'package:flutter/material.dart';
import '../../domain/life_event.dart';

/// カテゴリごとのアイコンを返す
IconData categoryIcon(EventCategory category) => switch (category) {
  EventCategory.joining => Icons.business,
  EventCategory.jobChange => Icons.swap_horiz,
  EventCategory.promotion => Icons.trending_up,
  EventCategory.retirement => Icons.exit_to_app,
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

/// 仕事系のベースカラー
const Color workColor = Colors.blue;

/// プライベート系のベースカラー
const Color privateColor = Colors.orange;

/// イベントのカラーを返す
Color eventColor(LifeEvent event) =>
    event.isWork ? workColor : privateColor;

/// 将来計画イベントかどうかで透明度を調整
double eventOpacity(LifeEvent event) =>
    event.isFuturePlan ? 0.55 : 1.0;
