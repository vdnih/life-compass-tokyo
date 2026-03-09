import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_repository.dart';
import '../domain/life_event.dart';

class TimelineEventsNotifier extends AsyncNotifier<List<LifeEvent>> {
  @override
  Future<List<LifeEvent>> build() async {
    final repository = ref.read(eventRepositoryProvider);
    return repository.fetchEvents();
  }

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
}

final timelineEventsProvider =
    AsyncNotifierProvider<TimelineEventsNotifier, List<LifeEvent>>(() {
      return TimelineEventsNotifier();
    });
