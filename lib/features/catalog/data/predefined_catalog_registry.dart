import '../domain/predefined_life_event.dart';
import 'groups/career_events.dart';
import 'groups/childbirth_events.dart';
import 'groups/learning_events.dart';
import 'groups/lifestyle_events.dart';
import 'groups/marriage_events.dart';
import 'groups/money_events.dart';
import 'groups/travel_events.dart';

/// 規定ライフイベントカタログの全グループを集約するレジストリ
///
/// アプリ内にハードコードされた静的データ。Firestore には保存しない（ADR-010）。
/// グループ別ファイルからカタログを集約し、統一的なアクセス手段を提供する。
/// 件数の正は `test/features/catalog/data/catalog_consistency_test.dart` のアサーション。
class PredefinedCatalogRegistry {
  PredefinedCatalogRegistry._();

  /// 全グループのカタログイベントリスト
  static List<PredefinedLifeEvent> get all => [
        ...marriageEvents,
        ...childbirthEvents,
        ...careerEvents,
        ...lifestyleEvents,
        ...travelEvents,
        ...learningEvents,
        ...moneyEvents,
      ];

  /// catalogId でカタログイベントを検索する
  ///
  /// 存在しない ID の場合は null を返す。
  static PredefinedLifeEvent? findById(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
