import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/event_dependency.dart';

/// 依存関係の永続化を担うリポジトリインターフェース
abstract class DependencyRepository {
  /// 全依存関係を取得する
  Future<List<EventDependency>> fetchDependencies();

  /// 依存関係を保存する
  Future<void> saveDependency(EventDependency dependency);

  /// 指定IDの依存関係を削除する
  Future<void> deleteDependency(String dependencyId);

  /// 指定イベントに関連する全依存関係を削除する（sourceEventId または targetEventId が一致）
  Future<void> deleteDependenciesForEvent(String eventId);

  /// 指定イベントに関連する依存関係を取得する（sourceEventId または targetEventId が一致）
  Future<List<EventDependency>> fetchDependenciesForEvent(String eventId);
}

/// インメモリ実装の [DependencyRepository]（MVP用）
class InMemoryDependencyRepository implements DependencyRepository {
  final List<EventDependency> _dependencies = [];

  @override
  Future<List<EventDependency>> fetchDependencies() async {
    return List.unmodifiable(_dependencies);
  }

  @override
  Future<void> saveDependency(EventDependency dependency) async {
    _dependencies.add(dependency);
  }

  @override
  Future<void> deleteDependency(String dependencyId) async {
    _dependencies.removeWhere((d) => d.id == dependencyId);
  }

  @override
  Future<void> deleteDependenciesForEvent(String eventId) async {
    _dependencies.removeWhere(
      (d) => d.sourceEventId == eventId || d.targetEventId == eventId,
    );
  }

  @override
  Future<List<EventDependency>> fetchDependenciesForEvent(String eventId) async {
    return _dependencies
        .where((d) => d.sourceEventId == eventId || d.targetEventId == eventId)
        .toList();
  }
}

/// [DependencyRepository] を提供するProvider
final dependencyRepositoryProvider = Provider<DependencyRepository>((ref) {
  return InMemoryDependencyRepository();
});
