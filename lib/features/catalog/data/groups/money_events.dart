import 'package:flutter/material.dart';
import '../../domain/predefined_life_event.dart';

/// お金グループ（money）のカタログ定義
///
/// ## このファイルの追加・修正方法
///
/// 1件追加する場合は `moneyEvents` リストに追記する。
/// 以下に完全記述例を示す:
///
/// ```dart
/// PredefinedLifeEvent(
///   id: 'kebab-case-id',           // ★全カタログで一意。変更禁止
///   label: '日本語ラベル',
///   group: LifeEventGroup.money,   // このファイルは money 固定
///   icon: Icons.savings,
///   color: Color(0xFFCCA87A),
///   defaultDurationMonths: null,   // null=単発、整数=期間（月）
///   defaultBudgetYen: null,        // null=予算なし、整数=円
///   hardRules: [],                 // お金グループは hard ルールなし
///   softRules: [],                 // お金グループは soft ルールなし
///   milestoneTemplates: [
///     MilestoneTemplate(
///       label: '口座開設',
///       offsetMonthsFromParent: 0,
///     ),
///   ],
/// ),
/// ```

/// お金グループの全カタログイベント（3件）
const List<PredefinedLifeEvent> moneyEvents = [
  PredefinedLifeEvent(
    id: 'start-nisa',
    label: 'NISA開始',
    group: LifeEventGroup.money,
    icon: Icons.savings,
    color: Color(0xFFCCA87A),
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '口座開設',
        offsetMonthsFromParent: 0,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'start-ideco',
    label: 'iDeCo開始',
    group: LifeEventGroup.money,
    icon: Icons.account_balance_outlined,
    color: Color(0xFFCCA87A),
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '加入手続き',
        offsetMonthsFromParent: 0,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'review-insurance',
    label: '保険見直し',
    group: LifeEventGroup.money,
    icon: Icons.health_and_safety_outlined,
    color: Color(0xFFCCA87A),
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '比較検討',
        offsetMonthsFromParent: -1,
      ),
    ],
  ),
];
