import 'package:firebase_ai/firebase_ai.dart';

import '../../catalog/data/predefined_catalog_registry.dart';
import '../../open_data/data/institutional_limits.dart';
import '../../timeline/data/goal_template_data.dart';

/// AI に公開する Function Calling 宣言を組み立てる。
///
/// enum の許容値は [GoalTemplateRegistry] / [PredefinedCatalogRegistry] /
/// [institutionalLimits] の実データから直接引く（ID をハードコードしない）。
/// こうすることでカタログ・テンプレートの追加に自動で追従し、AI が
/// 存在しない ID を幻覚するのも防げる。
///
/// `reference_baselines.dart`（PDR-008 の A分類＝平均値）はここで一切参照
/// しない。AI が平均値を発話しないための設計上のガード。
List<FunctionDeclaration> buildCoachToolDeclarations() {
  final templateIds = GoalTemplateRegistry.templates.map((t) => t.id).toList();
  final catalogIds = PredefinedCatalogRegistry.all.map((e) => e.id).toList();
  final limitCatalogIds =
      institutionalLimits.map((l) => l.catalogId).toSet().toList();

  return [
    FunctionDeclaration(
      'applyGoalTemplate',
      'ゴールに向けた定番のイベント群をまとめてタイムラインに配置する。'
          '「子どもがほしい」「そろそろ転職したい」のように、大きな目標に向けた'
          '準備を一括で置きたいときに使う。',
      parameters: {
        'templateId': Schema.enumString(
          enumValues: templateIds,
          description: '適用するゴールテンプレートのID',
        ),
        'goalYearMonth': Schema.string(
          description: 'ゴールの年月。yyyy-MM 形式（例: 2027-08）',
        ),
        'goalTitle': Schema.string(description: 'ゴールイベントのタイトル'),
      },
    ),
    FunctionDeclaration(
      'addEventFromCatalog',
      '単一のイベントをタイムラインに追加する。テンプレートほど大きな展開が'
          '要らない、単発の予定を置きたいときに使う。',
      parameters: {
        'catalogId': Schema.enumString(
          enumValues: catalogIds,
          description: '追加するイベントのカタログID',
        ),
        'yearMonth': Schema.string(
          description: '追加する年月。yyyy-MM 形式（例: 2027-08）',
        ),
      },
    ),
    FunctionDeclaration(
      'getInstitutionalLimit',
      '育休・産後ケアなど、指定したイベントに関して制度上どこまで選べるか'
          '（上限）を確認する。制度の話をするときは必ずこの関数の結果だけを'
          '根拠にすること。',
      parameters: {
        'catalogId': Schema.enumString(
          enumValues: limitCatalogIds,
          description: '確認したいイベントのカタログID',
        ),
      },
    ),
  ];
}

/// [catalogId] に紐づく制度上限（B1）を Function Response 用の Map 列挙で返す。
///
/// 1つの catalogId に複数の制度が紐づくことがある（例: 'childbirth' は
/// 産後ケア事業・産後パパ育休など複数件を持つ）。該当なしの場合は空リスト。
List<Map<String, Object?>> institutionalLimitResponsesFor(String catalogId) {
  return [
    for (final limit in institutionalLimits)
      if (limit.catalogId == catalogId)
        {
          'message': limit.message,
          'scope': limit.scope.label,
          'sourceName': limit.source.name,
          'sourcePublisher': limit.source.publisher,
          if (limit.source.url != null) 'sourceUrl': limit.source.url!,
        },
  ];
}
