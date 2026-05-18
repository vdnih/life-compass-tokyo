import 'package:flutter/material.dart';
import '../../domain/predefined_life_event.dart';

/// 旅行グループ（travel）のカタログ定義
///
/// ## このファイルの追加・修正方法
///
/// 1件追加する場合は `travelEvents` リストに追記する。
/// 以下に完全記述例を示す:
///
/// ```dart
/// PredefinedLifeEvent(
///   id: 'kebab-case-id',            // ★全カタログで一意。変更禁止
///   label: '日本語ラベル',
///   group: LifeEventGroup.travel,   // このファイルは travel 固定
///   icon: Icons.flight,
///   color: Color(0xFF7BBFB5),
///   defaultDurationMonths: 1,       // null=単発、整数=期間（月）
///   defaultBudgetYen: 300000,       // null=予算なし、整数=円
///   hardRules: [],                  // 旅行グループは hard ルールなし
///   softRules: [
///     SoftPrecedence(
///       predecessorCatalogId: 'obtain-certification',  // 本SPEC内で定義済みのID
///       recommendedMinMonthsAfter: 0,
///       message: '語学資格取得の後の留学が一般的な目安です',
///     ),
///   ],
///   milestoneTemplates: [
///     MilestoneTemplate(
///       label: '学校決定',
///       offsetMonthsFromParent: -3,
///     ),
///   ],
/// ),
/// ```

/// 旅行グループの全カタログイベント（4件）
const List<PredefinedLifeEvent> travelEvents = [
  PredefinedLifeEvent(
    id: 'overseas-travel',
    label: '海外旅行',
    group: LifeEventGroup.travel,
    icon: Icons.flight,
    color: Color(0xFF7BBFB5),
    defaultBudgetYen: 300000,
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '航空券予約',
        offsetMonthsFromParent: -2,
      ),
      MilestoneTemplate(
        label: 'ホテル予約',
        offsetMonthsFromParent: -1,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'long-vacation',
    label: '長期休暇旅行',
    group: LifeEventGroup.travel,
    icon: Icons.beach_access,
    color: Color(0xFF7BBFB5),
    defaultBudgetYen: 200000,
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '旅行計画',
        offsetMonthsFromParent: -2,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'workation',
    label: 'ワーケーション',
    group: LifeEventGroup.travel,
    icon: Icons.laptop_outlined,
    color: Color(0xFF7BBFB5),
    defaultBudgetYen: 150000,
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '滞在先決定',
        offsetMonthsFromParent: -1,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'study-abroad',
    label: '留学',
    group: LifeEventGroup.travel,
    icon: Icons.public,
    color: Color(0xFF7BBFB5),
    defaultDurationMonths: 6,
    defaultBudgetYen: 1500000,
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'obtain-certification',
        recommendedMinMonthsAfter: 0,
        message: '語学資格取得の後の留学が一般的な目安です',
      ),
    ],
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
