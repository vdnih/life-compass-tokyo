import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/life_event.dart';
import 'event_repository.dart';

/// Firestore を使用した [EventRepository] 実装
///
/// `users/{userId}/events` コレクションに対して CRUD を行う。
class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository({required this.userId});

  final String userId;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('events');

  @override
  Future<List<LifeEvent>> fetchEvents() async {
    final snapshot = await _eventsRef.get();
    // 廃止されたマイルストーン機能で保存されたドキュメント（kind == 'milestone'）は
    // 読み込み時に除外する。Firestore 上のデータは将来の再設計に備えて残す。
    return snapshot.docs
        .where((doc) => doc.data()['kind'] != 'milestone')
        .map((doc) => LifeEvent.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> saveEvent(LifeEvent event) async {
    await _eventsRef.doc(event.id).set(event.toJson());
  }

  @override
  Future<void> deleteEvent(LifeEvent event) async {
    await _eventsRef.doc(event.id).delete();
  }

  @override
  Future<void> updateEvent(LifeEvent event) async {
    await _eventsRef.doc(event.id).update(event.toJson());
  }
}
