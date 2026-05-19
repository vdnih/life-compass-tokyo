import 'package:flutter/material.dart';
import '../../domain/predefined_life_event.dart';

/// 結婚グループ（marriage）のカタログ定義
///
/// ## このファイルの追加・修正方法
///
/// 1件追加する場合は `marriageEvents` リストに追記する。
/// 以下に完全記述例を示す:
///
/// ```dart
/// PredefinedLifeEvent(
///   id: 'kebab-case-id',             // ★全カタログで一意。変更禁止
///   label: '日本語ラベル',
///   group: LifeEventGroup.marriage,  // このファイルは marriage 固定
///   icon: Icons.favorite,            // flutter/material.dart の IconData
///   color: Color(0xFFD4698F),        // 16進カラーコード
///   defaultDurationMonths: null,     // null=単発、整数=期間（月）
///   defaultBudgetYen: 300000,        // null=予算なし、整数=円
///   hardRules: [
///     HardPrecedence(
///       predecessorCatalogId: 'propose',   // 本SPEC内で定義済みのID
///       minMonthsAfter: null,              // null=順序制約のみ、整数=最低N月後
///       message: '〜が一般的な目安です',   // 事実提供口調。「〜すべき」禁止
///     ),
///   ],
///   softRules: [
///     SoftPrecedence(
///       predecessorCatalogId: 'dating-start',
///       recommendedMinMonthsAfter: 6,
///       message: '〜が一般的な目安です',
///     ),
///   ],
/// ),
/// ```

/// 結婚グループの全カタログイベント（11件）
const List<PredefinedLifeEvent> marriageEvents = [
  PredefinedLifeEvent(
    id: 'dating-start',
    label: 'お付き合い開始',
    group: LifeEventGroup.marriage,
    icon: Icons.favorite_border,
    color: Color(0xFFD4698F),
    hardRules: [],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'move-in-together',
    label: '同棲開始',
    group: LifeEventGroup.marriage,
    icon: Icons.home_outlined,
    color: Color(0xFFD4698F),
    defaultBudgetYen: 300000,
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'dating-start',
        recommendedMinMonthsAfter: 6,
        message: 'お付き合い開始から6ヶ月以上経ってからの同棲が一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'marriage-intent-shared',
    label: '結婚意思共有',
    group: LifeEventGroup.marriage,
    icon: Icons.handshake_outlined,
    color: Color(0xFFD4698F),
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'dating-start',
        recommendedMinMonthsAfter: 6,
        message: 'お付き合い開始から6ヶ月以上経ってからの結婚意思共有が一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'propose',
    label: 'プロポーズ',
    group: LifeEventGroup.marriage,
    icon: Icons.volunteer_activism,
    color: Color(0xFFD4698F),
    defaultBudgetYen: 400000,
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'marriage-intent-shared',
        recommendedMinMonthsAfter: 0,
        message: '結婚意思共有の後のプロポーズが一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'engagement-meeting',
    label: '両家顔合わせ',
    group: LifeEventGroup.marriage,
    icon: Icons.groups_outlined,
    color: Color(0xFFD4698F),
    defaultBudgetYen: 100000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'propose',
        message: 'プロポーズの後に置かれるイベントの目安です',
      ),
    ],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'propose',
        recommendedMinMonthsAfter: 1,
        message: 'プロポーズから1ヶ月以上経過した両家顔合わせが一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'venue-decision',
    label: '結婚式場決定',
    group: LifeEventGroup.marriage,
    icon: Icons.location_city_outlined,
    color: Color(0xFFD4698F),
    defaultBudgetYen: 50000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'propose',
        message: 'プロポーズの後に置かれるイベントの目安です',
      ),
    ],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'engagement-meeting',
        recommendedMinMonthsAfter: 1,
        message: '両家顔合わせの後の式場決定が一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'marriage-registration',
    label: '入籍',
    group: LifeEventGroup.marriage,
    icon: Icons.article_outlined,
    color: Color(0xFFD4698F),
    defaultBudgetYen: 10000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'propose',
        message: 'プロポーズの後に置かれるイベントの目安です',
      ),
    ],
    softRules: [],
  ),
  PredefinedLifeEvent(
    id: 'wedding-ceremony',
    label: '結婚式',
    group: LifeEventGroup.marriage,
    icon: Icons.celebration,
    color: Color(0xFFD4698F),
    defaultBudgetYen: 3000000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'venue-decision',
        message: '結婚式場決定の後に置かれるイベントの目安です',
      ),
    ],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'venue-decision',
        recommendedMinMonthsAfter: 6,
        message: '式場決定から6ヶ月以上の準備期間が一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'honeymoon',
    label: '新婚旅行',
    group: LifeEventGroup.marriage,
    icon: Icons.flight,
    color: Color(0xFFD4698F),
    defaultDurationMonths: 1,
    defaultBudgetYen: 500000,
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'wedding-ceremony',
        recommendedMinMonthsAfter: 0,
        message: '結婚式の後の新婚旅行が一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'wedding-photoshoot',
    label: '前撮り・フォトウェディング',
    group: LifeEventGroup.marriage,
    icon: Icons.photo_camera_outlined,
    color: Color(0xFFD4698F),
    defaultBudgetYen: 200000,
    hardRules: [],
    softRules: [
      SoftPrecedence(
        predecessorCatalogId: 'venue-decision',
        recommendedMinMonthsAfter: 1,
        message: '式場決定の後の前撮りが一般的な目安です',
      ),
    ],
  ),
  PredefinedLifeEvent(
    id: 'wedding-anniversary-1st',
    label: '結婚1周年',
    group: LifeEventGroup.marriage,
    icon: Icons.favorite,
    color: Color(0xFFD4698F),
    defaultBudgetYen: 50000,
    hardRules: [
      HardPrecedence(
        predecessorCatalogId: 'wedding-ceremony',
        minMonthsAfter: 12,
        message: '結婚式から12ヶ月後の1周年記念です',
      ),
    ],
    softRules: [],
  ),
];
