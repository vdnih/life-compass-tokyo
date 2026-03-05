import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/career_event.dart';

abstract class EventRepository {
  Future<List<CareerEvent>> fetchEvents();
  Future<void> saveEvent(CareerEvent event);
  Future<void> deleteEvent(CareerEvent event);
}

class InMemoryEventRepository implements EventRepository {
  final List<CareerEvent> _events = [
    CareerEvent(
      date: '2019-04',
      title: 'IT企業に入社',
      description: 'SIerとしてキャリアをスタート',
    ),
    CareerEvent(
      date: '2023-08',
      title: '現職へ転職',
      description: 'DX推進エンジニア・AIエンジニアとして参画',
    ),
    CareerEvent(
      date: '2025-12',
      title: 'ヨーロッパ周遊',
      description: 'サンセバスチャンやロンドンなどを巡る',
      isLifeEvent: true,
    ),
    CareerEvent(
      date: '2026-02',
      title: '結婚式',
      description: 'タイのクラビにて挙式',
      isLifeEvent: true,
    ),
  ];

  @override
  Future<List<CareerEvent>> fetchEvents() async => List.unmodifiable(_events);

  @override
  Future<void> saveEvent(CareerEvent event) async {
    _events.add(event);
  }

  @override
  Future<void> deleteEvent(CareerEvent event) async {
    _events.remove(event);
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return InMemoryEventRepository();
});
