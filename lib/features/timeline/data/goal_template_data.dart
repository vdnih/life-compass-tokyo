import '../domain/goal_template.dart';

/// ゴールテンプレートの定義データ（ハードコード）
///
/// テンプレートはすべてのユーザーで共通の静的データ。
/// テンプレートから生成されたイベントと依存関係のみが永続化対象。
/// v6.0: TemplateEvent の category を catalogId 参照に書き換え（ADR-010）
class GoalTemplateRegistry {
  GoalTemplateRegistry._();

  /// 利用可能な全テンプレート
  static List<GoalTemplate> get templates => [
        childbirthTemplate,
        marriageTemplate,
        jobChangeTemplate,
        homePurchaseTemplate,
      ];

  /// 出産テンプレート
  ///
  /// ゴール日 T を基準に逆算で関連イベントを生成する。
  /// PRD セクション6.1 の定義に基づく。
  static final childbirthTemplate = GoalTemplate(
    id: 'tmpl-childbirth',
    name: '出産',
    description: '出産に向けたライフプランを逆算で設計します',
    goalCatalogId: 'childbirth',
    relatedEvents: [
      // #1 妊活開始: T - 12ヶ月
      const TemplateEvent(
        titleTemplate: '妊活開始',
        catalogId: 'fertility-treatment-start',
        offsetMonthsFromGoal: -12,
      ),
      // #2 転職タイミングの目安: T - 12ヶ月
      const TemplateEvent(
        titleTemplate: '転職タイミングの目安',
        catalogId: 'job-change',
        offsetMonthsFromGoal: -12,
      ),
      // #3 海外旅行の目安: T - 4ヶ月
      const TemplateEvent(
        titleTemplate: '海外旅行の目安',
        catalogId: 'overseas-travel',
        offsetMonthsFromGoal: -4,
      ),
      // #4 産休開始: T - 2ヶ月 〜 T
      const TemplateEvent(
        titleTemplate: '産休開始',
        catalogId: 'maternity-leave',
        offsetMonthsFromGoal: -2,
        durationMonths: 2,
      ),
      // #5 育休: T 〜 T + 12ヶ月
      const TemplateEvent(
        titleTemplate: '育休',
        catalogId: 'childcare-leave',
        offsetMonthsFromGoal: 0,
        durationMonths: 12,
      ),
      // #6 復職: T + 12ヶ月
      const TemplateEvent(
        titleTemplate: '復職',
        catalogId: 'return-to-work',
        offsetMonthsFromGoal: 12,
      ),
    ],
  );

  /// 結婚テンプレート（Wave 4）
  ///
  /// ゴール: wedding-ceremony（結婚式）
  /// 関連イベント5件を逆算・順算で生成する。
  static final marriageTemplate = GoalTemplate(
    id: 'tmpl-marriage',
    name: '結婚',
    description: '結婚に向けたライフプランを逆算で設計します',
    goalCatalogId: 'wedding-ceremony',
    relatedEvents: [
      // #1 プロポーズ: T - 12ヶ月
      const TemplateEvent(
        titleTemplate: 'プロポーズ',
        catalogId: 'propose',
        offsetMonthsFromGoal: -12,
      ),
      // #2 両家顔合わせ: T - 10ヶ月
      const TemplateEvent(
        titleTemplate: '両家顔合わせ',
        catalogId: 'engagement-meeting',
        offsetMonthsFromGoal: -10,
      ),
      // #3 結婚式場決定: T - 9ヶ月
      const TemplateEvent(
        titleTemplate: '結婚式場決定',
        catalogId: 'venue-decision',
        offsetMonthsFromGoal: -9,
      ),
      // #4 入籍: T - 1ヶ月
      const TemplateEvent(
        titleTemplate: '入籍',
        catalogId: 'marriage-registration',
        offsetMonthsFromGoal: -1,
      ),
      // #5 新婚旅行: T + 1ヶ月
      const TemplateEvent(
        titleTemplate: '新婚旅行',
        catalogId: 'honeymoon',
        offsetMonthsFromGoal: 1,
      ),
    ],
  );

  /// 転職テンプレート（Wave 4）
  ///
  /// ゴール: joining-company（入社）
  /// 関連イベント2件を逆算で生成する。
  static final jobChangeTemplate = GoalTemplate(
    id: 'tmpl-job-change',
    name: '転職',
    description: '転職に向けたライフプランを逆算で設計します',
    goalCatalogId: 'joining-company',
    relatedEvents: [
      // #1 転職活動開始: T - 6ヶ月
      const TemplateEvent(
        titleTemplate: '転職活動開始',
        catalogId: 'job-change',
        offsetMonthsFromGoal: -6,
      ),
      // #2 資格取得（目安）: T - 12ヶ月（soft: 転職前に取得しておくと有利）
      const TemplateEvent(
        titleTemplate: '資格取得',
        catalogId: 'obtain-certification',
        offsetMonthsFromGoal: -12,
      ),
    ],
  );

  /// 住宅購入テンプレート（Wave 4）
  ///
  /// ゴール: home-purchase（住宅購入）
  /// 関連イベント3件を逆算・順算で生成する。
  static final homePurchaseTemplate = GoalTemplate(
    id: 'tmpl-home-purchase',
    name: '住宅購入',
    description: '住宅購入に向けたライフプランを逆算で設計します',
    goalCatalogId: 'home-purchase',
    relatedEvents: [
      // #1 物件探し開始: T - 6ヶ月
      const TemplateEvent(
        titleTemplate: '物件探し開始',
        catalogId: 'home-search',
        offsetMonthsFromGoal: -6,
      ),
      // #2 契約: T - 2ヶ月
      const TemplateEvent(
        titleTemplate: '契約',
        catalogId: 'home-purchase-signing',
        offsetMonthsFromGoal: -2,
      ),
      // #3 引越し: T + 1ヶ月
      const TemplateEvent(
        titleTemplate: '引越し',
        catalogId: 'move-in',
        offsetMonthsFromGoal: 1,
      ),
    ],
  );
}
