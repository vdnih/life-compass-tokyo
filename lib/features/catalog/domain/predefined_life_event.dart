import 'package:flutter/material.dart';

/// ライフイベントのグループ分類
///
/// 20代後半〜30代前半の女性のライフステージを7グループに分類する。
enum LifeEventGroup {
  marriage('結婚'),
  childbirth('出産'),
  career('キャリア'),
  lifestyle('住まい'),
  travel('旅行'),
  learning('学び'),
  money('お金');

  const LifeEventGroup(this.label);

  /// 日本語表示名
  final String label;
}

/// hard 先行ルール
///
/// 物理的・法的・論理的に成立しない順序の前提。
/// UI では赤フィードバックで表示するが、配置はブロックしない。
@immutable
class HardPrecedence {
  /// 先行すべきカタログID
  final String predecessorCatalogId;

  /// 先行イベントから最低何ヶ月後に配置すべきか（null = 順序制約のみ）
  final int? minMonthsAfter;

  /// ユーザーに表示するメッセージ（事実の情報提供に留める）
  final String message;

  const HardPrecedence({
    required this.predecessorCatalogId,
    this.minMonthsAfter,
    required this.message,
  });
}

/// soft 先行ルール
///
/// 慣習・準備期間として推奨される前提。
/// UI では黄フィードバックで表示するが、配置はブロックしない。
@immutable
class SoftPrecedence {
  /// 先行すべきカタログID
  final String predecessorCatalogId;

  /// 推奨経過月数
  final int recommendedMinMonthsAfter;

  /// ユーザーに表示するメッセージ（事実の情報提供に留める）
  final String message;

  const SoftPrecedence({
    required this.predecessorCatalogId,
    required this.recommendedMinMonthsAfter,
    required this.message,
  });
}

/// 既定マイルストーンのテンプレート
///
/// 親イベントがタイムラインに配置されたとき、
/// 自動生成される子マイルストーンの定義。
@immutable
class MilestoneTemplate {
  /// マイルストーンのラベル
  final String label;

  /// 親イベントの開始日からの月数オフセット（負=前、正=後）
  final int offsetMonthsFromParent;

  /// 予算プリセット（円、null の場合は予算なし）
  final int? defaultBudgetYen;

  const MilestoneTemplate({
    required this.label,
    required this.offsetMonthsFromParent,
    this.defaultBudgetYen,
  });
}

/// 規定ライフイベントカタログの1件を表すイミュータブルなモデル
///
/// アプリ内にハードコードされた静的データ。
/// Firestore には保存しない（ADR-010）。
@immutable
class PredefinedLifeEvent {
  /// カタログID（kebab-case。全カタログで一意）
  final String id;

  /// 表示ラベル（日本語）
  final String label;

  /// グループ分類
  final LifeEventGroup group;

  /// アイコン
  final IconData icon;

  /// カラー
  final Color color;

  /// 推奨表示期間（月数）。null = 単発イベント
  final int? defaultDurationMonths;

  /// 予算プリセット（円、中央値の目安）。null = 予算なし
  final int? defaultBudgetYen;

  /// hard 先行ルール一覧
  final List<HardPrecedence> hardRules;

  /// soft 先行ルール一覧
  final List<SoftPrecedence> softRules;

  /// 既定マイルストーンテンプレート一覧
  final List<MilestoneTemplate> milestoneTemplates;

  const PredefinedLifeEvent({
    required this.id,
    required this.label,
    required this.group,
    required this.icon,
    required this.color,
    this.defaultDurationMonths,
    this.defaultBudgetYen,
    required this.hardRules,
    required this.softRules,
    required this.milestoneTemplates,
  });
}
