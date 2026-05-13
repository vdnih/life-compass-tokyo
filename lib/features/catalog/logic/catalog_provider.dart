import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/predefined_catalog_registry.dart';
import '../domain/predefined_life_event.dart';

/// 全カタログイベントを提供するProvider（静的データ）
///
/// Riverpod Generator を使わず、副作用なし・即時取得可能な定数Providerとして実装する。
final catalogAllProvider = Provider<List<PredefinedLifeEvent>>((ref) {
  return PredefinedCatalogRegistry.all;
});

/// グループ別カタログイベントを提供するProvider
///
/// `LifeEventGroup` をキーとして、各グループのイベントリストを返す。
final catalogByGroupProvider =
    Provider<Map<LifeEventGroup, List<PredefinedLifeEvent>>>((ref) {
  final all = ref.watch(catalogAllProvider);
  final map = <LifeEventGroup, List<PredefinedLifeEvent>>{};

  for (final group in LifeEventGroup.values) {
    map[group] = all.where((e) => e.group == group).toList();
  }

  return map;
});

/// カタログ検索クエリの状態Provider
final catalogSearchQueryProvider = StateProvider<String>((ref) => '');

/// 検索クエリで絞り込んだカタログイベントを提供するProvider
///
/// クエリが空文字の場合は全件を返す。
/// ラベルまたはグループラベルにクエリが含まれるイベントを返す。
final catalogSearchProvider = Provider<List<PredefinedLifeEvent>>((ref) {
  final all = ref.watch(catalogAllProvider);
  final query = ref.watch(catalogSearchQueryProvider).trim();

  if (query.isEmpty) return all;

  return all
      .where((e) =>
          e.label.contains(query) ||
          e.group.label.contains(query))
      .toList();
});

/// catalogId → PredefinedLifeEvent のルックアップマップを提供するProvider
///
/// `constraintCheckerProvider` や `budgetSummaryProvider` からの高速参照用。
final catalogLookupProvider =
    Provider<Map<String, PredefinedLifeEvent>>((ref) {
  final all = ref.watch(catalogAllProvider);
  return {for (final e in all) e.id: e};
});
