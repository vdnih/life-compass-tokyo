import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/logic/auth_provider.dart';
import '../domain/event_dependency.dart';
import 'firestore_dependency_repository.dart';

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

  /// 依存関係を更新する（offsetMonths変更に使用）
  Future<void> updateDependency(EventDependency dependency);
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

  @override
  Future<void> updateDependency(EventDependency dependency) async {
    final index = _dependencies.indexWhere((d) => d.id == dependency.id);
    if (index != -1) {
      _dependencies[index] = dependency;
    }
  }
}

/// ゲストモードで使う [InMemoryDependencyRepository] を 1 インスタンスだけ保持する Provider。
///
/// [dependencyRepositoryProvider] の中で直接生成すると [authStateProvider] の
/// emission ごとに新品が作られ、ゲストの編集が消えてしまう
/// （event_repository.dart の同名 Provider と同じ理由）。
final inMemoryDependencyRepositoryProvider =
    Provider<InMemoryDependencyRepository>(
  (ref) => InMemoryDependencyRepository(),
);

/// uid ごとに同一の [FirestoreDependencyRepository] インスタンスを返す Provider。
final firestoreDependencyRepositoryProvider =
    Provider.family<FirestoreDependencyRepository, String>(
  (ref, userId) => FirestoreDependencyRepository(userId: userId),
);

/// [DependencyRepository] を提供するProvider
///
/// 認証済みの場合は Firestore 実装、未認証（ゲストモード）の場合は
/// インメモリ実装を返す。実体は保持されるため、Provider が再構築されても
/// 中身は同じインスタンスのまま。
final dependencyRepositoryProvider = Provider<DependencyRepository>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final user = userAsync.valueOrNull;
  if (user != null) {
    return ref.watch(firestoreDependencyRepositoryProvider(user.uid));
  }
  return ref.watch(inMemoryDependencyRepositoryProvider);
});
