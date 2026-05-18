import 'package:flutter/material.dart';
import '../../domain/predefined_life_event.dart';

/// キャリアグループ（career）のカタログ定義
///
/// ## このファイルの追加・修正方法
///
/// 1件追加する場合は `careerEvents` リストに追記する。
/// 以下に完全記述例を示す:
///
/// ```dart
/// PredefinedLifeEvent(
///   id: 'kebab-case-id',           // ★全カタログで一意。変更禁止
///   label: '日本語ラベル',
///   group: LifeEventGroup.career,  // このファイルは career 固定
///   icon: Icons.work,
///   color: Color(0xFF5B7FD4),
///   defaultDurationMonths: null,   // null=単発、整数=期間（月）
///   defaultBudgetYen: null,        // null=予算なし、整数=円
///   hardRules: [
///     HardPrecedence(
///       predecessorCatalogId: 'joining-company',  // 本SPEC内で定義済みのID
///       message: '入社の後に置かれるイベントの目安です',
///     ),
///   ],
///   softRules: [
///     SoftPrecedence(
///       predecessorCatalogId: 'joining-company',
///       recommendedMinMonthsAfter: 12,
///       message: '入社から12ヶ月以上経過した転職が一般的な目安です',
///     ),
///   ],
///   milestoneTemplates: [
///     MilestoneTemplate(
///       label: '情報収集',
///       offsetMonthsFromParent: -3,
///     ),
///   ],
/// ),
/// ```

/// キャリアグループの全カタログイベント（9件）
const List<PredefinedLifeEvent> careerEvents = [
  PredefinedLifeEvent(
    id: 'joining-company',
    label: '入社',
    group: LifeEventGroup.career,
    icon: Icons.business_center,
    color: Color(0xFF5B7FD4),
    hardRules: [],
    softRules: [],
    milestoneTemplates: [],
  ),
  PredefinedLifeEvent(
    id: 'job-change',
    label: '転職',
    group: LifeEventGroup.career,
    icon: Icons.swap_horiz,
    color: Color(0xFF7B9CE0),
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'joining-company',
        recommendedMinMonthsAfter: 12,
        message: '入社から12ヶ月以上経過した転職が一般的な目安です',
      ),
    ],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '情報収集',
        offsetMonthsFromParent: -3,
      ),
      MilestoneTemplate(
        label: '面接',
        offsetMonthsFromParent: -2,
      ),
      MilestoneTemplate(
        label: '内定',
        offsetMonthsFromParent: -1,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'promotion',
    label: '昇進',
    group: LifeEventGroup.career,
    icon: Icons.trending_up,
    color: Color(0xFF3D63C3),
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'joining-company',
        message: '入社の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'joining-company',
        recommendedMinMonthsAfter: 24,
        message: '入社から24ヶ月以上経過した昇進が一般的な目安です',
      ),
    ],
    milestoneTemplates: [],
  ),
  PredefinedLifeEvent(
    id: 'start-side-job',
    label: '長期副業',
    group: LifeEventGroup.career,
    icon: Icons.work_outline,
    color: Color(0xFF9DB5E8),
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'joining-company',
        message: '入社の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '副業内容検討',
        offsetMonthsFromParent: -1,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'side-job-preparation',
    label: '副業準備',
    group: LifeEventGroup.career,
    icon: Icons.edit_note,
    color: Color(0xFF9DB5E8),
    defaultDurationMonths: 3,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'joining-company',
        message: '入社の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(label: '副業内容検討', offsetMonthsFromParent: 0),
      MilestoneTemplate(label: '事業計画', offsetMonthsFromParent: 1),
    ],
  ),
  PredefinedLifeEvent(
    id: 'side-job-short',
    label: '短期副業',
    group: LifeEventGroup.career,
    icon: Icons.timelapse,
    color: Color(0xFF9DB5E8),
    defaultDurationMonths: 3,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'joining-company',
        message: '入社の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
    milestoneTemplates: [],
  ),
  PredefinedLifeEvent(
    id: 'obtain-certification',
    label: '資格取得',
    group: LifeEventGroup.career,
    icon: Icons.workspace_premium,
    color: Color(0xFF8B73B5),
    defaultBudgetYen: 50000,
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '学習開始',
        offsetMonthsFromParent: -6,
      ),
      MilestoneTemplate(
        label: '模試',
        offsetMonthsFromParent: -1,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'entrepreneurship',
    label: '起業',
    group: LifeEventGroup.career,
    icon: Icons.rocket_launch,
    color: Color(0xFF6B4FA0),
    defaultBudgetYen: 1000000,
    hardRules: [],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '事業計画',
        offsetMonthsFromParent: -3,
      ),
      MilestoneTemplate(
        label: '登記準備',
        offsetMonthsFromParent: -1,
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'resignation',
    label: '退職',
    group: LifeEventGroup.career,
    icon: Icons.exit_to_app,
    color: Color(0xFF8BA5DE),
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'joining-company',
        message: '入社の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
    milestoneTemplates: [
      MilestoneTemplate(
        label: '退職意思表明',
        offsetMonthsFromParent: -1,
      ),
      MilestoneTemplate(
        label: '引継ぎ',
        offsetMonthsFromParent: -1,
      ),
    ],
  ),
];
