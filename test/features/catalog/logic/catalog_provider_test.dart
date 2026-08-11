import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/catalog/domain/predefined_life_event.dart';
import 'package:my_career_app/features/catalog/logic/catalog_provider.dart';

void main() {
  group('catalogAllProvider の仕様', () {
    // career に副業準備・短期副業の2件を追加したため46件に更新
    test('catalogAllProvider が46件返すこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final all = container.read(catalogAllProvider);

      expect(all.length, 46);
    });

    test('catalogAllProvider が marriage グループのイベントを含むこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final all = container.read(catalogAllProvider);

      expect(
        all.any((e) => e.group == LifeEventGroup.marriage),
        isTrue,
      );
    });
  });

  group('catalogByGroupProvider の仕様', () {
    test('catalogByGroupProvider で marriage グループだけ取れること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final byGroup = container.read(catalogByGroupProvider);
      final marriageEvents = byGroup[LifeEventGroup.marriage];

      expect(marriageEvents, isNotNull);
      expect(marriageEvents!, isNotEmpty);
      expect(
        marriageEvents.every((e) => e.group == LifeEventGroup.marriage),
        isTrue,
      );
    });

    test('catalogByGroupProvider で全グループがキーとして存在すること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final byGroup = container.read(catalogByGroupProvider);

      for (final group in LifeEventGroup.values) {
        expect(byGroup.containsKey(group), isTrue,
            reason: 'グループ ${group.label} がマップに存在しません');
      }
    });

    test('catalogByGroupProvider の結婚グループが11件であること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final byGroup = container.read(catalogByGroupProvider);

      expect(byGroup[LifeEventGroup.marriage]!.length, 11);
    });
  });

  group('catalogSearchProvider の仕様', () {
    // career に副業準備・短期副業の2件を追加したため46件に更新
    test('catalogSearchProvider でクエリ空文字のとき全件返ること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(catalogSearchQueryProvider.notifier).setQuery('');
      final results = container.read(catalogSearchProvider);

      expect(results.length, 46);
    });

    test('catalogSearchProvider で「結婚」で検索すると関連イベントが返ること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(catalogSearchQueryProvider.notifier).setQuery('結婚');
      final results = container.read(catalogSearchProvider);

      expect(results, isNotEmpty);
      expect(
        results.every((e) =>
            e.label.contains('結婚') ||
            e.group == LifeEventGroup.marriage),
        isTrue,
      );
    });

    test('catalogSearchProvider で「転職」で検索すると転職イベントが返ること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(catalogSearchQueryProvider.notifier).setQuery('転職');
      final results = container.read(catalogSearchProvider);

      expect(results, isNotEmpty);
      expect(results.any((e) => e.label.contains('転職')), isTrue);
    });

    test('catalogSearchProvider で存在しないキーワードで検索すると空リストが返ること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(catalogSearchQueryProvider.notifier).setQuery('xxxxxxxxxxx');
      final results = container.read(catalogSearchProvider);

      expect(results, isEmpty);
    });
  });
}
