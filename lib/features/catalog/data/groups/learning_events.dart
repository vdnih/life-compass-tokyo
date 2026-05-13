import 'package:flutter/material.dart';
import '../../domain/predefined_life_event.dart';

/// 学びグループ（learning）のカタログ定義
///
/// ## このファイルの追加・修正方法
///
/// 1件追加する場合は `learningEvents` リストに追記する。
/// 以下に完全記述例を示す:
///
/// ```dart
/// PredefinedLifeEvent(
///   id: 'kebab-case-id',              // ★全カタログで一意。変更禁止
///   label: '日本語ラベル',
///   group: LifeEventGroup.learning,   // このファイルは learning 固定
///   icon: Icons.menu_book,
///   color: Color(0xFFA08DC0),
///   defaultDurationMonths: null,      // null=単発、整数=期間（月）
///   defaultBudgetYen: 50000,          // null=予算なし、整数=円
///   hardRules: [],
///   softRules: [
///     SoftPrecedence(
///       predecessorCatalogId: 'start-studying',  // 本SPEC内で定義済みのID
///       recommendedMinMonthsAfter: 24,
///       message: '学習開始から24ヶ月程度が一般的な学位取得期間の目安です',
///     ),
///   ],
///   milestoneTemplates: [
///     MilestoneTemplate(
///       label: '入学',
///       offsetMonthsFromParent: -24,
///     ),
///   ],
/// ),
/// ```

/// 学びグループの全カタログイベント（3件）
const List<PredefinedLifeEvent> learningEvents = [
  PredefinedLifeEvent(
    id: 'start-studying',
    label: '資格・スキル学習開始',
    group: LifeEventGroup.learning,
    icon: Icons.menu_book,
    color: Color(0xFFA08DC0),
    defaultBudgetYen: 50000,
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '教材購入',
        offsetMonthsFromParent: 0,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'obtain-degree',
    label: '学位取得',
    group: LifeEventGroup.learning,
    icon: Icons.school,
    color: Color(0xFFA08DC0),
    defaultBudgetYen: 1500000,
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'start-studying',
        recommendedMinMonthsAfter: 24,
        message: '学習開始から24ヶ月程度が一般的な学位取得期間の目安です',
      ),
    ],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '入学',
        offsetMonthsFromParent: -24,
      ),
      MilestoneTemplate(
        label: '論文執筆',
        offsetMonthsFromParent: -3,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'language-study-abroad',
    label: '語学留学',
    group: LifeEventGroup.learning,
    icon: Icons.language,
    color: Color(0xFFA08DC0),
    defaultDurationMonths: 6,
    defaultBudgetYen: 1000000,
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '学校決定',
        offsetMonthsFromParent: -3,
      ),
      MilestoneTemplate(
        label: 'ビザ申請',
        offsetMonthsFromParent: -2,
      ),
    ],
  ),
];
