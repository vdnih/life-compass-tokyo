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

/// ライフイベントを表すイミュータブルなデータモデル
@immutable
class LifeEvent {
  /// イベントの一意識別子（UUID）
  final String id;

  /// イベント開始日（yyyy-MM 形式）
  final String date; // yyyy-MM

  /// イベント終了日（yyyy-MM 形式、期間イベントの場合のみ）
  final String? endDate; // yyyy-MM

  /// イベントタイトル
  final String title;

  /// イベント詳細説明
  final String description;

  /// イベントカテゴリ
  final EventCategory category;

  /// イベントステータス
  final EventStatus status;

  /// このイベントが属するゴールのID（ゴールテンプレートから生成された場合）
  final String? goalId;

  /// このイベント自体がゴールであるか
  final bool isGoal;

  const LifeEvent({
    this.id = '',
    required this.date,
    this.endDate,
    required this.title,
    required this.description,
    required this.category,
    this.status = EventStatus.recorded,
    this.goalId,
    this.isGoal = false,
  });

  /// date フィールドを DateTime に変換する
  DateTime get dateTime {
    final parts = date.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// endDate フィールドを DateTime に変換する。endDate が null の場合は null を返す
  DateTime? get endDateTime {
    if (endDate == null) return null;
    final parts = endDate!.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// 期間が設定されているか
  bool get hasDuration => endDate != null;

  /// 仕事系イベントか
  bool get isWork => category.isWork;

  /// 将来計画イベントか
  bool get isFuturePlan => status.isFuturePlan;

  /// 一部のプロパティを変更した新しい [LifeEvent] インスタンスを生成する
  LifeEvent copyWith({
    String? id,
    String? date,
    String? endDate,
    String? title,
    String? description,
    EventCategory? category,
    EventStatus? status,
    String? goalId,
    bool? isGoal,
  }) {
    return LifeEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      goalId: goalId ?? this.goalId,
      isGoal: isGoal ?? this.isGoal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifeEvent &&
        other.id == id &&
        other.date == date &&
        other.endDate == endDate &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.status == status &&
        other.goalId == goalId &&
        other.isGoal == isGoal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        endDate.hashCode ^
        title.hashCode ^
        description.hashCode ^
        category.hashCode ^
        status.hashCode ^
        goalId.hashCode ^
        isGoal.hashCode;
  }
}
