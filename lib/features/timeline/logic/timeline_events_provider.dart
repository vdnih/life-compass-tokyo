import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_repository.dart';
import '../domain/career_event.dart';

class TimelineEventsNotifier extends AsyncNotifier<List<CareerEvent>> {
  @override
  Future<List<CareerEvent>> build() async {
    final repository = ref.read(eventRepositoryProvider);
    return repository.fetchEvents();
  }

  Future<void> addEvent(CareerEvent event) async {
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

  Future<void> deleteEvent(CareerEvent event) async {
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
    AsyncNotifierProvider<TimelineEventsNotifier, List<CareerEvent>>(() {
      return TimelineEventsNotifier();
    });
