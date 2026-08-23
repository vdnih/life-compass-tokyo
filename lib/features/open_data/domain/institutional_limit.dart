import 'package:flutter/foundation.dart';

import 'data_source.dart';

/// 制度上限（B1）の形。PDR-008 の分類に基づき2種類を区別する。
///
/// 育休のような「そのイベント自体の期間の上限」と、産後ケア事業のような
/// 「起点イベントからの利用可能期間」は判定方法が異なるため、単一の
/// `limitMonths` だけでは表現できない。
enum InstitutionalLimitKind {
  /// 対象イベント自身の期間（`endDate - date`）に対する上限
  /// （例: 育休は最長で子が2歳になるまで）
  duration,

  /// 起点イベントの発生からの利用可能期間
  /// （例: 産後ケア事業は出産から1年を経過するまで利用できる）
  window,
}

/// 制度上限（B1）の値オブジェクト。
///
/// PDR-008: 「制度上の上限値のみ、出典付きで可視化する」の実装対象。
/// 平均値（A分類）とは異なり UI に出すことを前提とする。
///
/// 文言ポリシー（`scripted_coach.dart` と同じ）: 「〜すべき」「〜が必要」
/// 「リミット」「〜しておくと」等の指示・推奨表現を `message` に使わない。
/// また暦年齢に紐づく上限（PDR-008 の B2）はこの型で表現しない。
@immutable
class InstitutionalLimit {
  /// この上限のID（例: 'IL-childcare-leave'）。`ConstraintResult.ruleId` に使う
  final String id;

  /// 紐づくカタログID。`PredefinedCatalogRegistry.findById` で解決できること
  final String catalogId;

  final InstitutionalLimitKind kind;

  /// 上限月数
  final int limitMonths;

  /// 事実文（出典と合わせて表示する）
  final String message;

  final DataSource source;

  const InstitutionalLimit({
    required this.id,
    required this.catalogId,
    required this.kind,
    required this.limitMonths,
    required this.message,
    required this.source,
  });
}
