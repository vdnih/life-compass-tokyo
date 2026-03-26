import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/life_event.dart';

/// イベントの永続化を担うリポジトリインターフェース
abstract class EventRepository {
  /// 全イベントを取得する
  Future<List<LifeEvent>> fetchEvents();

  /// イベントを保存する
  Future<void> saveEvent(LifeEvent event);

  /// イベントを削除する
  Future<void> deleteEvent(LifeEvent event);

  /// 既存のイベントを更新する（id で対象を特定する）
  Future<void> updateEvent(LifeEvent event);
}

/// インメモリ実装の [EventRepository]（MVP用）
class InMemoryEventRepository implements EventRepository {
  final List<LifeEvent> _events = [
    const LifeEvent(
      id: 'event-1',
      date: '2019-04',
      title: 'IT企業に入社',
      description: 'SIerとしてキャリアをスタート',
      category: EventCategory.joining,
    ),
    const LifeEvent(
      id: 'event-2',
      date: '2023-08',
      title: '現職へ転職',
      description: 'DX推進エンジニア・AIエンジニアとして参画',
      category: EventCategory.jobChange,
    ),
    const LifeEvent(
      id: 'event-3',
      date: '2025-12',
      title: 'ヨーロッパ周遊',
      description: 'サンセバスチャンやロンドンなどを巡る',
      category: EventCategory.travel,
    ),
    const LifeEvent(
      id: 'event-4',
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

  @override
  Future<void> updateEvent(LifeEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
  }
}

/// [EventRepository] を提供するProvider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return InMemoryEventRepository();
});
