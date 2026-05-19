import 'package:flutter/material.dart';
import '../../domain/predefined_life_event.dart';

/// 出産グループ（childbirth）のカタログ定義
///
/// ## このファイルの追加・修正方法
///
/// 1件追加する場合は `childbirthEvents` リストに追記する。
/// 以下に完全記述例を示す:
///
/// ```dart
/// PredefinedLifeEvent(
///   id: 'kebab-case-id',               // ★全カタログで一意。変更禁止
///   label: '日本語ラベル',
///   group: LifeEventGroup.childbirth,  // このファイルは childbirth 固定
///   icon: Icons.child_care,
///   color: Color(0xFFE87EA1),
///   defaultDurationMonths: 12,         // null=単発、整数=期間（月）
///   defaultBudgetYen: 500000,          // null=予算なし、整数=円
///   hardRules: [
///     HardPrecedence(
///       predecessorCatalogId: 'pregnancy',  // 本SPEC内で定義済みのID
///       minMonthsAfter: 9,
///       message: '妊娠から約9ヶ月後の出産が一般的な目安です',
///     ),
///   ],
///   softRules: [
///     SoftPrecedence(
///       predecessorCatalogId: 'job-change',
///       recommendedMinMonthsAfter: 12,
///       message: '転職から12ヶ月以上経過していると、育休取得の条件を満たしやすくなります',
///     ),
///   ],
/// ),
/// ```

/// 出産グループの全カタログイベント（7件）
const List<PredefinedLifeEvent> childbirthEvents = [
  PredefinedLifeEvent(
    id: 'fertility-treatment-start',
    label: '妊活開始',
    group: LifeEventGroup.childbirth,
    icon: Icons.spa_outlined,
    color: Color(0xFFE87EA1),
    hardRules: [],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'pregnancy',
    label: '妊娠',
    group: LifeEventGroup.childbirth,
    icon: Icons.pregnant_woman,
    color: Color(0xFFE87EA1),
    defaultDurationMonths: 10,
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'job-change',
        recommendedMinMonthsAfter: 12,
        message: '転職から12ヶ月以上経過していると、育休取得の条件を満たしやすくなります',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'childbirth',
    label: '出産',
    group: LifeEventGroup.childbirth,
    icon: Icons.child_care,
    color: Color(0xFFE87EA1),
    defaultBudgetYen: 500000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'pregnancy',
        minMonthsAfter: 9,
        message: '妊娠から約9ヶ月後の出産が一般的な目安です',
      ),
    ],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'job-change',
        recommendedMinMonthsAfter: 12,
        message: '転職から12ヶ月以上経過していると、育休取得の条件を満たしやすくなります',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'maternity-leave',
    label: '産休',
    group: LifeEventGroup.childbirth,
    icon: Icons.self_improvement,
    color: Color(0xFFE87EA1),
    defaultDurationMonths: 4,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'pregnancy',
        message: '妊娠の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'childcare-leave',
    label: '育休',
    group: LifeEventGroup.childbirth,
    icon: Icons.family_restroom,
    color: Color(0xFFEC9BB8),
    defaultDurationMonths: 12,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'childbirth',
        message: '出産の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'return-to-work',
    label: '復職',
    group: LifeEventGroup.childbirth,
    icon: Icons.keyboard_return,
    color: Color(0xFFE87EA1),
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'childcare-leave',
        message: '育休の後の復職が一般的です',
      ),
    ],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'childcare-leave',
        recommendedMinMonthsAfter: 12,
        message: '育休開始から12ヶ月程度が一般的な復職時期の目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'child-enters-kindergarten',
    label: '保育園入園',
    group: LifeEventGroup.childbirth,
    icon: Icons.school_outlined,
    color: Color(0xFFE87EA1),
    defaultBudgetYen: 200000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'childbirth',
        message: '出産の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'childbirth',
        recommendedMinMonthsAfter: 12,
        message: '出産から12ヶ月以上経過した入園が一般的な目安です',
      ),
    ],
  ),
];
