import 'package:flutter/foundation.dart';

/// 制度上限値（B1）の出典を表す値オブジェクト。
///
/// PDR-008 の方針で「出典付きで可視化する」ことが必須条件になっているため、
/// `InstitutionalLimit` は必ずこの型を1つ持つ。
@immutable
class DataSource {
  /// データセット名、または根拠となる法令名
  final String name;

  /// 提供元（例: '東京都', '厚生労働省'）
  final String publisher;

  /// 出典URL。法令のように定まったURLが無い場合は null
  final String? url;

  /// 東京都オープンデータカタログ等のデータセットID。法令由来なら null
  final String? datasetId;

  /// データを取得した日（yyyy-MM-dd）。法令由来なら null
  final String? retrievedOn;

  /// ライセンス（例: 'CC BY 4.0'）。法令に一般的な意味でのライセンスは無いため
  /// その場合は '該当なし（公的な法令情報）' のような説明文を入れる
  final String license;

  const DataSource({
    required this.name,
    required this.publisher,
    this.url,
    this.datasetId,
    this.retrievedOn,
    required this.license,
  });

  /// UI に1行で出すための短いラベル（例: '出典: 育児・介護休業法（厚生労働省）'）
  String get label => '出典: $name（$publisher）';
}
