import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/logic/catalog_provider.dart';
import 'timeline_events_provider.dart';

/// タイムライン上の全イベントの予算合計を提供するProvider（v6.0 新設）
///
/// 各イベントの budgetYen が null の場合は catalog.defaultBudgetYen を使う。
/// どちらも null の場合は 0 として加算する。
final budgetSummaryProvider = Provider<int>((ref) {
  final eventsAsync = ref.watch(timelineEventsProvider);
  final catalog = ref.watch(catalogLookupProvider);
  return eventsAsync.maybeWhen(
    data: (events) => events.fold<int>(0, (sum, e) {
      final preset = catalog[e.catalogId]?.defaultBudgetYen ?? 0;
      return sum + (e.budgetYen ?? preset);
    }),
    orElse: () => 0,
  );
});
