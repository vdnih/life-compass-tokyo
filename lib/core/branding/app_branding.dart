/// 作品名・タグラインの単一情報源。
///
/// 作品名は `docs/hackathon/SUBMISSION_DRAFT.md`（2-2 作品名）が正で、
/// 提出後は変更できない。タグラインは `docs/hackathon/PRESENTATION_OUTLINE.md`
/// の表紙コピーで、[PDR-010](../../../docs/pdr/PDR-010-messaging-institution-as-instrument.md)
/// のメッセージング規約（制度を文の主語・修飾語の先頭に置かない）に従う。
/// 新しいコピーを足すときもこの規約を満たすものだけを追加すること。
class AppBranding {
  AppBranding._();

  static const String appName = 'ライフコンパス東京';
  static const String tagline = '制度を知って、自分の人生を自分で描く';
  static const String logoAsset = 'assets/icons/app_icon_1024.png';
}
