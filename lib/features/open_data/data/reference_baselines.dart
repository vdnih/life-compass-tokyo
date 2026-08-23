// このファイルは PDR-008 の A 分類（実態の中心値。平均・中央値・最頻値）の
// 出典を記録する内部専用ファイルである。
//
// **`presentation/` から参照禁止。** ここに書く値は UI に一切出さない。
// カタログ・テンプレートの初期値（`defaultDurationMonths` 等）を決めるときの
// 内部的な根拠としてのみ用いる。
//
// PDR-008 の一行ルール: 「平均は他人がどうだったか、上限は自分に何が許されて
// いるか。前者は比較を生み、後者は選択肢を増やす。」— A 分類は前者に属する。
//
// 現時点ではカタログ側の値は変更しない（このファイルは根拠の記録のみ）。
// 残り5カタログ群（career / marriage / lifestyle / travel / learning / money）
// への展開は Issue #88 で扱う。

/// 育休の既定期間（`childcare-leave.defaultDurationMonths` = 12）の根拠。
///
/// 育児休業の取得期間は個人差が大きく単一の公的統計値は無いため、育児・
/// 介護休業法が定める原則の休業可能期間（子が1歳になるまで）を初期値の
/// 目安として採用している。制度上の延長可能上限（子が2歳まで）は A では
/// なく B1 に分類され、`institutional_limits.dart` の `IL-childcare-leave`
/// が UI 表示を担う。
/// 出典: 育児・介護休業法 第5条（厚生労働省）
const int refChildcareLeaveDefaultMonths = 12;

/// 産休の既定期間（`maternity-leave.defaultDurationMonths` = 4）の根拠。
///
/// 労働基準法が定める産前6週間・産後8週間を合算し、月単位に丸めた値。
/// 出典: 労働基準法 第65条（厚生労働省）
const int refMaternityLeaveDefaultMonths = 4;

/// 「妊娠」→「出産」の hard ルール（`minMonthsAfter` = 10）の根拠。
///
/// 妊娠期間（在胎週数）の一般的な目安（約40週 ≒ 10ヶ月）。
/// 出典: 厚生労働省 e-ヘルスネット「妊娠期間」の解説
const int refPregnancyToChildbirthMonths = 10;

/// 「妊活」→「妊娠」の hard ルール（`minMonthsAfter` = 6）の根拠。
///
/// 妊活開始から妊娠までの期間には大きな個人差があり単一の統計代表値は
/// 存在しないため、カタログ設計時に準備期間の目安として置いた値。
/// 公的統計による裏付けは無く、UI の初期配置を破綻させないための
/// 経験的な目安であることを明記する。
const int refFertilityTreatmentToPregnancyMonths = 6;

/// 「復職」の soft ルール（`recommendedMinMonthsAfter` = 12）の根拠。
///
/// 育休開始から1年程度での復職が一般的である旨は厚生労働省
/// 「雇用均等基本調査」の育児休業取得期間の分布（女性の最頻値帯が
/// 「12か月〜18か月未満」付近）に基づく目安。この分布そのもの（実態の
/// 分布）は PDR-008 の分類 C に該当し、UI 表示は今回のスコープ外
/// （→ Issue #89）。
/// 出典: 厚生労働省「雇用均等基本調査」
const int refReturnToWorkRecommendedMonths = 12;

/// 「保育園入園」の soft ルール（`recommendedMinMonthsAfter` = 12）の根拠。
///
/// 上記の復職時期の目安（育休開始から概ね1年）と保育園入園のタイミングが
/// 実務上連動することが多いため、復職と同じ12ヶ月を採用した。
/// 出典: 厚生労働省「雇用均等基本調査」（復職の根拠を準用）
const int refChildEntersKindergartenRecommendedMonths = 12;
