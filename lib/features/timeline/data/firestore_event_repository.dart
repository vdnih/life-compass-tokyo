import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../domain/life_event.dart';
import 'event_repository.dart';

/// Firestore を使用した [EventRepository] の実装
///
/// コレクションパス: `users/{userId}/events`
class FirestoreEventRepository implements EventRepository {
  final String userId;
  final FirebaseFirestore _db;

  FirestoreEventRepository(this.userId, {FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(userId).collection('events');

  @override
  Future<List<LifeEvent>> fetchEvents() async {
    final snapshot = await _col.orderBy('date').get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> saveEvent(LifeEvent event) async {
    final id = event.id.isEmpty ? const Uuid().v4() : event.id;
    await _col.doc(id).set(_toMap(event.id.isEmpty ? _withId(event, id) : event));
  }

  LifeEvent _withId(LifeEvent event, String id) => LifeEvent(
        id: id,
        date: event.date,
        endDate: event.endDate,
        title: event.title,
        description: event.description,
        category: event.category,
        status: event.status,
        goalId: event.goalId,
        isGoal: event.isGoal,
      );

  @override
  Future<void> updateEvent(LifeEvent event) async {
    await _col.doc(event.id).update(_toMap(event));
  }

  @override
  Future<void> deleteEvent(LifeEvent event) async {
    await _col.doc(event.id).delete();
  }

  Map<String, dynamic> _toMap(LifeEvent e) => {
        'id': e.id,
        'date': e.date,
        'endDate': e.endDate,
        'title': e.title,
        'description': e.description,
        'category': e.category.name,
        'status': e.status.name,
        'goalId': e.goalId,
        'isGoal': e.isGoal,
      };

  LifeEvent _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return LifeEvent(
      id: data['id'] as String,
      date: data['date'] as String,
      endDate: data['endDate'] as String?,
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      category: EventCategory.values.byName(data['category'] as String),
      status: data['status'] != null
          ? EventStatus.values.byName(data['status'] as String)
          : EventStatus.recorded,
      goalId: data['goalId'] as String?,
      isGoal: data['isGoal'] as bool? ?? false,
    );
  }
}
