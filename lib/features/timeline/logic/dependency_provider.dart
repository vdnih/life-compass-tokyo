import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dependency_repository.dart';
import '../domain/event_dependency.dart';

/// 依存関係の状態を管理するNotifier
///
/// CRUD操作と循環依存検出を担う。
class DependencyNotifier extends AsyncNotifier<List<EventDependency>> {
  @override
  Future<List<EventDependency>> build() async {
    // ref.watch によりauth変化時に自動再構築
    final repo = ref.watch(dependencyRepositoryProvider);
    return repo.fetchDependencies();
  }

  /// 依存関係を追加する
  Future<void> addDependency(EventDependency dep) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repo = ref.read(dependencyRepositoryProvider);
      await repo.saveDependency(dep);
      final deps = await repo.fetchDependencies();
      state = AsyncData(deps);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// 指定IDの依存関係を削除する
  Future<void> removeDependency(String dependencyId) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repo = ref.read(dependencyRepositoryProvider);
      await repo.deleteDependency(dependencyId);
      final deps = await repo.fetchDependencies();
      state = AsyncData(deps);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// 指定イベントに関連するすべての依存関係を削除する
  Future<void> removeDependenciesForEvent(String eventId) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repo = ref.read(dependencyRepositoryProvider);
      await repo.deleteDependenciesForEvent(eventId);
      final deps = await repo.fetchDependencies();
      state = AsyncData(deps);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// 依存関係の offsetMonths を更新する（連動期間変更に使用）
  ///
  /// [dependencyId] 更新対象の依存関係ID
  /// [newOffsetMonths] 新しい offsetMonths 値
  Future<void> updateDependencyOffset(
    String dependencyId,
    int newOffsetMonths,
  ) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repo = ref.read(dependencyRepositoryProvider);
      final deps = previousState.valueOrNull ?? [];
      final target = deps.firstWhere((d) => d.id == dependencyId);
      final updated = target.copyWith(offsetMonths: newOffsetMonths);
      await repo.updateDependency(updated);
      final newDeps = await repo.fetchDependencies();
      state = AsyncData(newDeps);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// [sourceEventId] から [targetEventId] への依存関係を追加すると循環が生じるか検出する
  ///
  /// BFS で [targetEventId] を起点に既存の依存グラフを探索し、
  /// [sourceEventId] に到達できれば循環とみなす。
  /// 自己参照（sourceEventId == targetEventId）も循環として扱う。
  bool wouldCreateCycle(String sourceEventId, String targetEventId) {
    if (sourceEventId == targetEventId) return true;

    final currentDeps = state.valueOrNull ?? [];

    // BFS: targetEventId から source に到達できるか探索する
    final visited = <String>{};
    final queue = <String>[targetEventId];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == sourceEventId) return true;
      if (visited.contains(current)) continue;
      visited.add(current);

      // current を source とする依存関係のターゲットを次のキューに追加
      final nextIds = currentDeps
          .where((d) => d.sourceEventId == current)
          .map((d) => d.targetEventId);
      queue.addAll(nextIds);
    }

    return false;
  }
}

/// 依存関係の状態を提供するProvider
final dependencyProvider =
    AsyncNotifierProvider<DependencyNotifier, List<EventDependency>>(() {
  return DependencyNotifier();
});
