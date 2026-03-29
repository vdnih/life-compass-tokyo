import '../domain/goal_template.dart';
import '../domain/life_event.dart';

/// ゴールテンプレートの定義データ（ハードコード）
///
/// テンプレートはすべてのユーザーで共通の静的データ。
/// テンプレートから生成されたイベントと依存関係のみが永続化対象。
class GoalTemplateRegistry {
  GoalTemplateRegistry._();

  /// 利用可能な全テンプレート
  static List<GoalTemplate> get templates => [childbirthTemplate];

  /// 出産テンプレート
  ///
  /// ゴール日 T を基準に逆算で関連イベントを生成する。
  /// PRD セクション6.1 の定義に基づく。
  static final childbirthTemplate = GoalTemplate(
    id: 'tmpl-childbirth',
    name: '出産',
    description: '出産に向けたライフプランを逆算で設計します',
    goalCategory: EventCategory.childbirth,
    relatedEvents: [
      // #1 妊活開始: T - 12ヶ月
      const TemplateEvent(
        titleTemplate: '妊活開始',
        category: EventCategory.marriage,
        offsetMonthsFromGoal: -12,
      ),
      // #2 転職タイミングの目安: T - 12ヶ月
      const TemplateEvent(
        titleTemplate: '転職タイミングの目安',
        category: EventCategory.jobChange,
        offsetMonthsFromGoal: -12,
      ),
      // #3 海外旅行の目安: T - 4ヶ月
      const TemplateEvent(
        titleTemplate: '海外旅行の目安',
        category: EventCategory.travel,
        offsetMonthsFromGoal: -4,
      ),
      // #4 産休開始: T - 2ヶ月 〜 T
      const TemplateEvent(
        titleTemplate: '産休開始',
        category: EventCategory.maternityLeave,
        offsetMonthsFromGoal: -2,
        durationMonths: 2,
      ),
      // #5 育休: T 〜 T + 12ヶ月
      const TemplateEvent(
        titleTemplate: '育休',
        category: EventCategory.childcareLeave,
        offsetMonthsFromGoal: 0,
        durationMonths: 12,
      ),
      // #6 復職: T + 12ヶ月
      const TemplateEvent(
        titleTemplate: '復職',
        category: EventCategory.returnToWork,
        offsetMonthsFromGoal: 12,
      ),
    ],
  );
}
