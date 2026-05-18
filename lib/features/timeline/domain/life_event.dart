import 'package:flutter/foundation.dart';

/// イベントの種別
///
/// - `event`: 通常のライフイベント
/// - `milestone`: 親イベントに紐づくマイルストーン
enum EventKind {
  event,
  milestone;
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

/// ライフイベントを表すイミュータブルなデータモデル（v6.0）
///
/// v6.0 変更点:
/// - `EventCategory` enum を削除。代わりに `catalogId` (String) を使用
/// - `parentEventId` を追加（マイルストーンの親参照用）
/// - `kind` (EventKind) を追加
/// - `budgetYen` (int?) を追加
@immutable
class LifeEvent {
  /// イベントの一意識別子（UUID）
  final String id;

  /// カタログID（kebab-case）。`PredefinedCatalogRegistry` で参照可能
  final String catalogId;

  /// 親イベントのID（kind == milestone のときのみ非null）
  final String? parentEventId;

  /// イベントの種別（event または milestone）
  final EventKind kind;

  /// イベント開始日（yyyy-MM 形式）
  final String date;

  /// イベント終了日（yyyy-MM 形式、期間イベントの場合のみ）
  final String? endDate;

  /// イベントタイトル
  final String title;

  /// イベント詳細説明
  final String description;

  /// イベントステータス
  final EventStatus status;

  /// このイベントが属するゴールのID（ゴールテンプレートから生成された場合）
  final String? goalId;

  /// このイベント自体がゴールであるか
  final bool isGoal;

  /// 予算（円）。null の場合は catalog.defaultBudgetYen を UI 側で参照
  final int? budgetYen;

  const LifeEvent({
    required this.id,
    required this.catalogId,
    this.parentEventId,
    this.kind = EventKind.event,
    required this.date,
    this.endDate,
    required this.title,
    required this.description,
    this.status = EventStatus.recorded,
    this.goalId,
    this.isGoal = false,
    this.budgetYen,
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

  /// 将来計画イベントか
  bool get isFuturePlan => status.isFuturePlan;

  /// 仕事系イベントか（catalogId 経由で判定）
  ///
  /// Wave 2 では暫定的に catalogId で判断する。
  /// career グループに属するイベントを仕事系とみなす。
  bool get isWork {
    const workCatalogIds = {
      'joining-company',
      'job-change',
      'promotion',
      'start-side-job',
      'obtain-certification',
      'entrepreneurship',
      'resignation',
    };
    return workCatalogIds.contains(catalogId);
  }

  /// 一部のプロパティを変更した新しい [LifeEvent] インスタンスを生成する
  LifeEvent copyWith({
    String? id,
    String? catalogId,
    Object? parentEventId = _sentinel,
    EventKind? kind,
    String? date,
    Object? endDate = _sentinel,
    String? title,
    String? description,
    EventStatus? status,
    Object? goalId = _sentinel,
    bool? isGoal,
    Object? budgetYen = _sentinel,
  }) {
    return LifeEvent(
      id: id ?? this.id,
      catalogId: catalogId ?? this.catalogId,
      parentEventId: parentEventId == _sentinel
          ? this.parentEventId
          : parentEventId as String?,
      kind: kind ?? this.kind,
      date: date ?? this.date,
      endDate: endDate == _sentinel ? this.endDate : endDate as String?,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      goalId: goalId == _sentinel ? this.goalId : goalId as String?,
      isGoal: isGoal ?? this.isGoal,
      budgetYen: budgetYen == _sentinel ? this.budgetYen : budgetYen as int?,
    );
  }

  /// Firestore 保存用に Map に変換する
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catalogId': catalogId,
      'parentEventId': parentEventId,
      'kind': kind.name,
      'date': date,
      'endDate': endDate,
      'title': title,
      'description': description,
      'status': status.name,
      'goalId': goalId,
      'isGoal': isGoal,
      'budgetYen': budgetYen,
    };
  }

  /// Firestore から取得した Map を [LifeEvent] に変換する
  factory LifeEvent.fromJson(Map<String, dynamic> json) {
    return LifeEvent(
      id: json['id'] as String,
      catalogId: (json['catalogId'] as String?) ?? '',
      parentEventId: json['parentEventId'] as String?,
      kind: EventKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => EventKind.event,
      ),
      date: json['date'] as String,
      endDate: json['endDate'] as String?,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      status: EventStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EventStatus.recorded,
      ),
      goalId: json['goalId'] as String?,
      isGoal: (json['isGoal'] as bool?) ?? false,
      budgetYen: json['budgetYen'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifeEvent &&
        other.id == id &&
        other.catalogId == catalogId &&
        other.parentEventId == parentEventId &&
        other.kind == kind &&
        other.date == date &&
        other.endDate == endDate &&
        other.title == title &&
        other.description == description &&
        other.status == status &&
        other.goalId == goalId &&
        other.isGoal == isGoal &&
        other.budgetYen == budgetYen;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        catalogId.hashCode ^
        parentEventId.hashCode ^
        kind.hashCode ^
        date.hashCode ^
        endDate.hashCode ^
        title.hashCode ^
        description.hashCode ^
        status.hashCode ^
        goalId.hashCode ^
        isGoal.hashCode ^
        budgetYen.hashCode;
  }
}

// sentinel object for copyWith optional null clearing
const _sentinel = Object();
