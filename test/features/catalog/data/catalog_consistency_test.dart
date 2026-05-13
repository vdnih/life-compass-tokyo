import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/catalog/data/predefined_catalog_registry.dart';
import 'package:my_career_app/features/catalog/domain/predefined_life_event.dart';

void main() {
  group('カタログ整合性テスト', () {
    late List<PredefinedLifeEvent> allEvents;
    late Set<String> allIds;

    setUp(() {
      allEvents = PredefinedCatalogRegistry.all;
      allIds = allEvents.map((e) => e.id).toSet();
    });

    test('全IDが一意であること（重複IDなし）', () {
      final ids = allEvents.map((e) => e.id).toList();
      final uniqueIds = ids.toSet();

      expect(ids.length, uniqueIds.length,
          reason: '重複したIDが存在します: ${ids.where((id) => ids.where((i) => i == id).length > 1).toSet()}');
    });

    test('全ラベルが非空であること', () {
      for (final event in allEvents) {
        expect(event.label, isNotEmpty,
            reason: 'ID=${event.id} のラベルが空です');
      }
    });

    test('hardRules が参照する predecessorCatalogId が実在すること（孤立参照なし）', () {
      for (final event in allEvents) {
        for (final rule in event.hardRules) {
          expect(allIds.contains(rule.predecessorCatalogId), isTrue,
              reason:
                  'ID=${event.id} の hardRule が参照する predecessorCatalogId="${rule.predecessorCatalogId}" が存在しません');
        }
      }
    });

    test('softRules が参照する predecessorCatalogId が実在すること（孤立参照なし）', () {
      for (final event in allEvents) {
        for (final rule in event.softRules) {
          expect(allIds.contains(rule.predecessorCatalogId), isTrue,
              reason:
                  'ID=${event.id} の softRule が参照する predecessorCatalogId="${rule.predecessorCatalogId}" が存在しません');
        }
      }
    });

    test('findById が既存IDで非nullを返すこと', () {
      expect(PredefinedCatalogRegistry.findById('wedding-ceremony'), isNotNull);
      expect(PredefinedCatalogRegistry.findById('childbirth'), isNotNull);
      expect(PredefinedCatalogRegistry.findById('job-change'), isNotNull);
    });

    test('findById が存在しないIDでnullを返すこと', () {
      expect(PredefinedCatalogRegistry.findById('non-existent-id'), isNull);
      expect(PredefinedCatalogRegistry.findById(''), isNull);
    });

    test('結婚グループが10件以上であること', () {
      final marriageCount = allEvents
          .where((e) => e.group == LifeEventGroup.marriage)
          .length;

      expect(marriageCount, greaterThanOrEqualTo(10));
    });

    test('出産グループが6件以上であること', () {
      final childbirthCount = allEvents
          .where((e) => e.group == LifeEventGroup.childbirth)
          .length;

      expect(childbirthCount, greaterThanOrEqualTo(6));
    });

    // Wave 4: lifestyle に home-purchase / home-search / home-purchase-signing / move-in の4件を追加
    test('全カタログが44件であること', () {
      expect(allEvents.length, 44);
    });

    test('キャリアグループが7件であること', () {
      final careerCount = allEvents
          .where((e) => e.group == LifeEventGroup.career)
          .length;

      expect(careerCount, 7);
    });

    // Wave 4: lifestyle に4件追加（合計9件）
    test('住まいグループが9件であること', () {
      final lifestyleCount = allEvents
          .where((e) => e.group == LifeEventGroup.lifestyle)
          .length;

      expect(lifestyleCount, 9);
    });

    test('旅行グループが4件であること', () {
      final travelCount = allEvents
          .where((e) => e.group == LifeEventGroup.travel)
          .length;

      expect(travelCount, 4);
    });

    test('学びグループが3件であること', () {
      final learningCount = allEvents
          .where((e) => e.group == LifeEventGroup.learning)
          .length;

      expect(learningCount, 3);
    });

    test('お金グループが3件であること', () {
      final moneyCount = allEvents
          .where((e) => e.group == LifeEventGroup.money)
          .length;

      expect(moneyCount, 3);
    });

    test('wedding-ceremony の hardRules が正しく設定されていること', () {
      final event = PredefinedCatalogRegistry.findById('wedding-ceremony');

      expect(event, isNotNull);
      expect(event!.hardRules, isNotEmpty);
      expect(event.hardRules.first.predecessorCatalogId, 'venue-decision');
    });

    test('childbirth の hardRules に pregnancy が含まれること', () {
      final event = PredefinedCatalogRegistry.findById('childbirth');

      expect(event, isNotNull);
      expect(
        event!.hardRules.any((r) => r.predecessorCatalogId == 'pregnancy'),
        isTrue,
      );
    });

    test('pregnancy の softRules に job-change が含まれること', () {
      final event = PredefinedCatalogRegistry.findById('pregnancy');

      expect(event, isNotNull);
      expect(
        event!.softRules.any((r) => r.predecessorCatalogId == 'job-change'),
        isTrue,
      );
    });

    // Wave 4: 住宅購入テンプレート用 catalogId の存在確認
    test('home-purchase が存在すること', () {
      expect(PredefinedCatalogRegistry.findById('home-purchase'), isNotNull);
    });

    test('home-search が存在すること', () {
      expect(PredefinedCatalogRegistry.findById('home-search'), isNotNull);
    });

    test('home-purchase-signing が存在すること', () {
      expect(PredefinedCatalogRegistry.findById('home-purchase-signing'), isNotNull);
    });

    test('move-in が存在すること', () {
      expect(PredefinedCatalogRegistry.findById('move-in'), isNotNull);
    });
  });
}
