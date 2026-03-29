import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/event_dependency.dart';
import 'dependency_repository.dart';

/// Firestore を使用した [DependencyRepository] 実装
///
/// `users/{userId}/dependencies` コレクションに対して CRUD を行う。
class FirestoreDependencyRepository implements DependencyRepository {
  FirestoreDependencyRepository({required this.userId});

  final String userId;

  CollectionReference<Map<String, dynamic>> get _depsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('dependencies');

  @override
  Future<List<EventDependency>> fetchDependencies() async {
    final snapshot = await _depsRef.get();
    return snapshot.docs
        .map((doc) => EventDependency.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> saveDependency(EventDependency dependency) async {
    await _depsRef.doc(dependency.id).set(dependency.toJson());
  }

  @override
  Future<void> deleteDependency(String dependencyId) async {
    await _depsRef.doc(dependencyId).delete();
  }

  @override
  Future<void> deleteDependenciesForEvent(String eventId) async {
    final snapshot = await _depsRef
        .where(Filter.or(
          Filter('sourceEventId', isEqualTo: eventId),
          Filter('targetEventId', isEqualTo: eventId),
        ))
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<List<EventDependency>> fetchDependenciesForEvent(
      String eventId) async {
    final snapshot = await _depsRef
        .where(Filter.or(
          Filter('sourceEventId', isEqualTo: eventId),
          Filter('targetEventId', isEqualTo: eventId),
        ))
        .get();
    return snapshot.docs
        .map((doc) => EventDependency.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> updateDependency(EventDependency dependency) async {
    await _depsRef.doc(dependency.id).update(dependency.toJson());
  }
}
