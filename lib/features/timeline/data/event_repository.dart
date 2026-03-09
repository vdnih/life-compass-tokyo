import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/life_event.dart';

abstract class EventRepository {
  Future<List<LifeEvent>> fetchEvents();
  Future<void> saveEvent(LifeEvent event);
  Future<void> deleteEvent(LifeEvent event);
}

class InMemoryEventRepository implements EventRepository {
  final List<LifeEvent> _events = [
    const LifeEvent(
      date: '2019-04',
      title: 'IT企業に入社',
      description: 'SIerとしてキャリアをスタート',
      category: EventCategory.joining,
    ),
    const LifeEvent(
      date: '2023-08',
      title: '現職へ転職',
      description: 'DX推進エンジニア・AIエンジニアとして参画',
      category: EventCategory.jobChange,
    ),
    const LifeEvent(
      date: '2025-12',
      title: 'ヨーロッパ周遊',
      description: 'サンセバスチャンやロンドンなどを巡る',
      category: EventCategory.travel,
    ),
    const LifeEvent(
      date: '2026-02',
      title: '結婚式',
      description: 'タイのクラビにて挙式',
      category: EventCategory.marriage,
    ),
  ];

  @override
  Future<List<LifeEvent>> fetchEvents() async => List.unmodifiable(_events);

  @override
  Future<void> saveEvent(LifeEvent event) async {
    _events.add(event);
  }

  @override
  Future<void> deleteEvent(LifeEvent event) async {
    _events.remove(event);
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return InMemoryEventRepository();
});
