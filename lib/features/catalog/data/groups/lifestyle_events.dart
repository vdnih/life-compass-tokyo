import 'package:flutter/material.dart';
import '../../domain/predefined_life_event.dart';

/// 住まいグループ（lifestyle）のカタログ定義
///
/// ## このファイルの追加・修正方法
///
/// 1件追加する場合は `lifestyleEvents` リストに追記する。
/// 以下に完全記述例を示す:
///
/// ```dart
/// PredefinedLifeEvent(
///   id: 'kebab-case-id',              // ★全カタログで一意。変更禁止
///   label: '日本語ラベル',
///   group: LifeEventGroup.lifestyle,  // このファイルは lifestyle 固定
///   icon: Icons.home,
///   color: Color(0xFF82B38A),
///   defaultDurationMonths: null,      // null=単発、整数=期間（月）
///   defaultBudgetYen: 300000,         // null=予算なし、整数=円
///   hardRules: [
///     HardPrecedence(
///       predecessorCatalogId: 'consider-home-purchase',  // 本SPEC内で定義済みのID
///       message: '住宅購入検討の後に置かれるイベントの目安です',
///     ),
///   ],
///   softRules: [
///     SoftPrecedence(
///       predecessorCatalogId: 'consider-home-purchase',
///       recommendedMinMonthsAfter: 6,
///       message: '検討開始から6ヶ月以上の比較期間が一般的な目安です',
///     ),
///   ],
/// ),
/// ```

/// 住まいグループの全カタログイベント（9件）
const List<PredefinedLifeEvent> lifestyleEvents = [
  PredefinedLifeEvent(
    id: 'moving',
    label: '引越し',
    group: LifeEventGroup.lifestyle,
    icon: Icons.local_shipping_outlined,
    color: Color(0xFF82B38A),
    defaultBudgetYen: 300000,
    hardRules: [],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'rental-contract-renewal',
    label: '賃貸契約更新',
    group: LifeEventGroup.lifestyle,
    icon: Icons.assignment_outlined,
    color: Color(0xFF82B38A),
    defaultBudgetYen: 100000,
    hardRules: [],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'consider-home-purchase',
    label: '住宅購入検討',
    group: LifeEventGroup.lifestyle,
    icon: Icons.search_outlined,
    color: Color(0xFF82B38A),
    hardRules: [],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'purchase-home',
    label: '住宅購入',
    group: LifeEventGroup.lifestyle,
    icon: Icons.home,
    color: Color(0xFF82B38A),
    defaultBudgetYen: 35000000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'consider-home-purchase',
        message: '住宅購入検討の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'consider-home-purchase',
        recommendedMinMonthsAfter: 6,
        message: '検討開始から6ヶ月以上の比較期間が一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'renovation',
    label: 'リフォーム',
    group: LifeEventGroup.lifestyle,
    icon: Icons.construction_outlined,
    color: Color(0xFF82B38A),
    defaultDurationMonths: 2,
    defaultBudgetYen: 2000000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'purchase-home',
        message: '住宅購入の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
  ),
  // Wave 4: 住宅購入テンプレート用に追加
  PredefinedLifeEvent(
    id: 'home-purchase',
    label: '住宅購入（ゴール）',
    group: LifeEventGroup.lifestyle,
    icon: Icons.home,
    color: Color(0xFF82B38A),
    defaultBudgetYen: 35000000,
    hardRules: [],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'home-search',
    label: '物件探し開始',
    group: LifeEventGroup.lifestyle,
    icon: Icons.search,
    color: Color(0xFF82B38A),
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'consider-home-purchase',
        recommendedMinMonthsAfter: 0,
        message: '住宅購入検討の後に物件探しを始めるのが一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'home-purchase-signing',
    label: '住宅購入契約',
    group: LifeEventGroup.lifestyle,
    icon: Icons.draw_outlined,
    color: Color(0xFF82B38A),
    defaultBudgetYen: 500000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'home-search',
        message: '物件探し開始の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'move-in',
    label: '引越し（新居）',
    group: LifeEventGroup.lifestyle,
    icon: Icons.local_shipping,
    color: Color(0xFF82B38A),
    defaultBudgetYen: 300000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'home-purchase',
        message: '住宅購入の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
  ),
];
