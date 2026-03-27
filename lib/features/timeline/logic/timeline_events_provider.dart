import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_repository.dart';
import '../domain/life_event.dart';

/// タイムラインイベントの状態を管理するNotifier
class TimelineEventsNotifier extends AsyncNotifier<List<LifeEvent>> {
  @override
  Future<List<LifeEvent>> build() async {
    final repository = ref.read(eventRepositoryProvider);
    return repository.fetchEvents();
  }

  /// 新しいイベントをリストに追加する
  Future<void> addEvent(LifeEvent event) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.saveEvent(event);
      final events = await repository.fetchEvents();
      state = AsyncData(events);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// 既存のイベントを削除する
  Future<void> deleteEvent(LifeEvent event) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.deleteEvent(event);
      final events = await repository.fetchEvents();
      state = AsyncData(events);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// 既存のイベントを更新する（編集に使用）
  Future<void> updateEvent(LifeEvent event) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.updateEvent(event);
      final events = await repository.fetchEvents();
      state = AsyncData(events);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// 指定したIDのイベントの日付を更新する（D&D移動に使用）
  Future<void> moveEvent(String eventId, String newDate, {String? newEndDate}) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repository = ref.read(eventRepositoryProvider);
      final events = await repository.fetchEvents();
      final target = events.firstWhere((e) => e.id == eventId);
      final updated = newEndDate != null
          ? target.copyWith(date: newDate, endDate: newEndDate)
          : target.copyWith(date: newDate);
      await repository.updateEvent(updated);
      final updatedEvents = await repository.fetchEvents();
      state = AsyncData(updatedEvents);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }
}

/// タイムラインイベントの状態を提供するProvider
final timelineEventsProvider =
    AsyncNotifierProvider<TimelineEventsNotifier, List<LifeEvent>>(() {
      return TimelineEventsNotifier();
    });
