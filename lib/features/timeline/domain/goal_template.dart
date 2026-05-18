import 'package:flutter/foundation.dart';

/// ゴールテンプレート定義
/// ユーザーが選択するゴールと、それに関連するイベント群を定義する
@immutable
class GoalTemplate {
  /// テンプレートの一意識別子
  final String id;

  /// テンプレート名（例: "出産", "転職"）
  final String name;

  /// テンプレートの説明
  final String description;

  /// ゴールイベントのカタログID
  final String goalCatalogId;

  /// ゴールに関連するテンプレートイベント群
  final List<TemplateEvent> relatedEvents;

  const GoalTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.goalCatalogId,
    required this.relatedEvents,
  });
}

/// テンプレート内のイベント定義
/// ゴール日付を基準とした相対位置でイベントを定義する
@immutable
class TemplateEvent {
  /// イベントタイトルのテンプレート文字列
  final String titleTemplate;

  /// イベントのカタログID（PredefinedCatalogRegistry で参照可能）
  final String catalogId;

  /// ゴールからの相対月数（負=ゴール前、正=ゴール後）
  final int offsetMonthsFromGoal;

  /// イベントの期間（月数）。null の場合は期間なし
  final int? durationMonths;

  const TemplateEvent({
    required this.titleTemplate,
    required this.catalogId,
    required this.offsetMonthsFromGoal,
    this.durationMonths,
  });
}
