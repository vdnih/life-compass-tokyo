/// spike/ai-chat-ux: AI を呼ばずにキーワード一致でテンプレートを選ぶ固定応答。
///
/// Step 4 でシステムプロンプトを書く際の叩き台にするため、文言は仮置きではなく
/// PRODUCT_VISION.md の Values（特に Value 4: Empowerment, not Direction）に
/// 従って書く。「〜すべき」「〜が必要」「リミット」「〜しておくと」等の
/// 指示・推奨表現は使わない。
library;

/// [ScriptedCoach.reply] の戻り値。
///
/// [templateId] が null の場合はテンプレートを展開しない（該当キーワード無し）。
class ScriptedReply {
  /// チャットに表示する応答文
  final String responseText;

  /// 展開するゴールテンプレートのID（`GoalTemplateRegistry` 参照）。該当なしは null
  final String? templateId;

  /// ゴールイベントのタイトル
  final String goalTitle;

  /// ゴール年月を「現在から何ヶ月後」で指定
  final int goalMonthsFromNow;

  const ScriptedReply({
    required this.responseText,
    this.templateId,
    this.goalTitle = '',
    this.goalMonthsFromNow = 0,
  });
}

/// キーワード → 既存4テンプレートへの固定マッピング
abstract final class ScriptedCoach {
  static ScriptedReply reply(String input) {
    if (_matchesAny(input, const ['子ども', 'こども', '子供', '出産', '妊娠'])) {
      return const ScriptedReply(
        responseText:
            '出産に向けた一般的な流れをタイムラインに置きました。妊活の目安から産休・育休・復職までが並びます。'
            '実際の時期は体調や職場の状況で変わるので、気になるところはドラッグで動かせます。',
        templateId: 'tmpl-childbirth',
        goalTitle: '出産',
        goalMonthsFromNow: 24,
      );
    }
    if (_matchesAny(input, const ['結婚', 'プロポーズ', '入籍'])) {
      return const ScriptedReply(
        responseText:
            '結婚に向けた一般的な流れを置きました。プロポーズから新婚旅行までの目安です。'
            '順番や間隔はいつでも引き直せます。',
        templateId: 'tmpl-marriage',
        goalTitle: '結婚',
        goalMonthsFromNow: 18,
      );
    }
    if (_matchesAny(input, const ['転職', '仕事を変え', 'キャリアチェンジ'])) {
      return const ScriptedReply(
        responseText: '転職に向けた準備の目安を置きました。資格取得から活動開始までの流れです。',
        templateId: 'tmpl-job-change',
        goalTitle: '転職',
        goalMonthsFromNow: 12,
      );
    }
    if (_matchesAny(input, const ['家', '住宅', 'マンション', '引越し', '引っ越し'])) {
      return const ScriptedReply(
        responseText: '住宅購入に向けた流れを置きました。物件探しから引越しまでの目安です。',
        templateId: 'tmpl-home-purchase',
        goalTitle: '住宅購入',
        goalMonthsFromNow: 36,
      );
    }
    return const ScriptedReply(
      responseText:
          'このプロトタイプは「出産」「結婚」「転職」「住宅購入」の4つのキーワードにのみ固定応答します'
          '（AI とは接続していません）。「子どもがほしい」のように送ると反応します。',
    );
  }

  static bool _matchesAny(String text, List<String> keywords) =>
      keywords.any(text.contains);
}
