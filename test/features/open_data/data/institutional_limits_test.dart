import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/catalog/data/predefined_catalog_registry.dart';
import 'package:my_career_app/features/open_data/data/institutional_limits.dart';

/// message に含まれてはいけない語（PDR-008 の文言ポリシー: Value 4 と B2 混入防止）。
///
/// 「〜すべき」「〜が必要」「リミット」「〜しておくと」は指示・推奨表現として
/// scripted_coach.dart と同じ理由で禁止する。「歳まで」は暦年齢に紐づく上限
/// （B2）の典型的な言い回しで、B1（起点イベントからの相対的な上限）だけを
/// 扱うこの一覧に紛れ込んでいないかを見る。
const _forbiddenWords = ['すべき', 'が必要', 'リミット', 'しておくと', '歳まで'];

void main() {
  group('institutional_limits データ整合性テスト', () {
    test('全エントリの catalogId が PredefinedCatalogRegistry で解決できること', () {
      for (final limit in institutionalLimits) {
        expect(
          PredefinedCatalogRegistry.findById(limit.catalogId),
          isNotNull,
          reason: '${limit.id} の catalogId "${limit.catalogId}" が'
              'カタログに存在しません',
        );
      }
    });

    test('全エントリが出典（データセット名・提供元・ライセンス）を持つこと', () {
      for (final limit in institutionalLimits) {
        expect(limit.source.name, isNotEmpty, reason: limit.id);
        expect(limit.source.publisher, isNotEmpty, reason: limit.id);
        expect(limit.source.license, isNotEmpty, reason: limit.id);
      }
    });

    test('id が一意であること', () {
      final ids = institutionalLimits.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('message に禁止語（指示表現・暦年齢起点の上限=B2）が含まれないこと', () {
      for (final limit in institutionalLimits) {
        for (final word in _forbiddenWords) {
          expect(
            limit.message.contains(word),
            isFalse,
            reason: '${limit.id} の message に禁止語「$word」が含まれています: '
                '${limit.message}',
          );
        }
      }
    });

    test('limitMonths が正の値であること', () {
      for (final limit in institutionalLimits) {
        expect(limit.limitMonths, greaterThan(0), reason: limit.id);
      }
    });
  });
}
