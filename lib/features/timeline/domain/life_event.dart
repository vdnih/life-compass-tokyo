import 'package:flutter/foundation.dart';

/// イベントカテゴリ
/// 仕事系とプライベート系に分類される
enum EventCategory {
  // 仕事系
  joining('入社', true),
  jobChange('転職', true),
  promotion('昇進', true),
  retirement('退職', true),
  maternityLeave('産休', true),
  startup('起業', true),
  certification('資格取得', true),
  sideJob('副業開始', true),

  // プライベート系
  marriage('結婚', false),
  childbirth('出産', false),
  childcareLeave('育休', false),
  returnToWork('復職', false),
  moving('引越し', false),
  travel('旅行', false),
  education('学び直し', false),
  caregiving('介護', false);

  const EventCategory(this.label, this.isWork);
  final String label;
  final bool isWork;
}

/// イベントステータス
/// 過去の記録か、将来の計画かを区別する
enum EventStatus {
  recorded('記録'),
  planned('予定'),
  goal('目標'),
  considering('検討中');

  const EventStatus(this.label);
  final String label;

  bool get isFuturePlan => this != EventStatus.recorded;
}

@immutable
class LifeEvent {
  final String date; // yyyy-MM
  final String? endDate; // yyyy-MM
  final String title;
  final String description;
  final EventCategory category;
  final EventStatus status;

  const LifeEvent({
    required this.date,
    this.endDate,
    required this.title,
    required this.description,
    required this.category,
    this.status = EventStatus.recorded,
  });

  DateTime get dateTime {
    final parts = date.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  DateTime? get endDateTime {
    if (endDate == null) return null;
    final parts = endDate!.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  bool get hasDuration => endDate != null;

  bool get isWork => category.isWork;

  bool get isFuturePlan => status.isFuturePlan;

  LifeEvent copyWith({
    String? date,
    String? endDate,
    String? title,
    String? description,
    EventCategory? category,
    EventStatus? status,
  }) {
    return LifeEvent(
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifeEvent &&
        other.date == date &&
        other.endDate == endDate &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.status == status;
  }

  @override
  int get hashCode {
    return date.hashCode ^
        endDate.hashCode ^
        title.hashCode ^
        description.hashCode ^
        category.hashCode ^
        status.hashCode;
  }
}
