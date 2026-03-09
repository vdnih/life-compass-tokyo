import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/career_event.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';

class MockEventRepository extends Mock implements EventRepository {}

class FakeCareerEvent extends Fake implements CareerEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCareerEvent());
  });

  group('TimelineEventsProvider の機能一覧（仕様）', () {
    late MockEventRepository mockRepository;

    setUp(() {
      mockRepository = MockEventRepository();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('初期状態: EventRepositoryからイベント一覧を取得し、AsyncDataとして状態を保持すること', () async {
      final mockEvents = [
        CareerEvent(date: '2020-01', title: 'Test 1', description: ''),
      ];
      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => mockEvents);

      final container = createContainer();

      // 初期状態はLoadingになる場合があるため、Future完了を待つ
      final events = await container.read(timelineEventsProvider.future);

      expect(events, equals(mockEvents));
      verify(() => mockRepository.fetchEvents()).called(1);
    });

    test('追加成功: 新しいイベントを追加した際、AsyncLoadingを経て新しい一覧のAsyncDataに遷移すること', () async {
      final initialEvents = [
        CareerEvent(date: '2020-01', title: 'Test 1', description: ''),
      ];
      final newEvent = CareerEvent(
        date: '2021-01',
        title: 'Test 2',
        description: '',
      );
      final updatedEvents = [...initialEvents, newEvent];

      // 初期ロード用
      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => initialEvents);
      when(() => mockRepository.saveEvent(any())).thenAnswer((_) async {});

      final container = createContainer();

      // まず初期状態をロードさせる
      await container.read(timelineEventsProvider.future);

      // 追加処理後のfetch用モック更新
      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => updatedEvents);

      // providerのリスナーを登録して状態変化を監視
      final states = <AsyncValue<List<CareerEvent>>>[];
      container.listen(timelineEventsProvider, (previous, next) {
        states.add(next);
      });

      // 実行
      await container.read(timelineEventsProvider.notifier).addEvent(newEvent);

      // AsyncLoading状態を経て、データ状態になることを検証
      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.first is AsyncLoading, isTrue);
      expect(states.last.value, equals(updatedEvents));

      verify(() => mockRepository.saveEvent(newEvent)).called(1);
      verify(() => mockRepository.fetchEvents()).called(2); // 初期ロード + 追加後ロード
    });

    test('削除成功: 既存のイベントを削除した際、AsyncLoadingを経て新しい一覧のAsyncDataに遷移すること', () async {
      final targetEvent = CareerEvent(
        date: '2020-01',
        title: 'Test 1',
        description: '',
      );
      final initialEvents = [targetEvent];

      // 初期ロード用
      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => initialEvents);
      when(() => mockRepository.deleteEvent(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      // 削除後のfetch用モック更新
      when(() => mockRepository.fetchEvents()).thenAnswer((_) async => []);

      final states = <AsyncValue<List<CareerEvent>>>[];
      container.listen(timelineEventsProvider, (previous, next) {
        states.add(next);
      });

      // 実行
      await container
          .read(timelineEventsProvider.notifier)
          .deleteEvent(targetEvent);

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.first is AsyncLoading, isTrue);
      // 空のリストになっているか
      expect(states.last.value, isEmpty);

      verify(() => mockRepository.deleteEvent(targetEvent)).called(1);
    });

    test('削除エラー: EventRepositoryの削除処理が例外を投げた場合、状態がAsyncErrorに遷移すること', () async {
      final targetEvent = CareerEvent(
        date: '2020-01',
        title: 'Test 1',
        description: '',
      );
      final initialEvents = [targetEvent];
      final exception = Exception('Failed to delete event');

      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => initialEvents);
      when(() => mockRepository.deleteEvent(any())).thenThrow(exception);

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      final states = <AsyncValue<List<CareerEvent>>>[];
      container.listen(timelineEventsProvider, (previous, next) {
        states.add(next);
      });

      await container
          .read(timelineEventsProvider.notifier)
          .deleteEvent(targetEvent);

      expect(states.any((s) => s is AsyncError), isTrue);
      verify(() => mockRepository.deleteEvent(targetEvent)).called(1);
    });

    test('エラー発生時: EventRepositoryの処理が例外を投げた場合、状態がAsyncErrorに遷移すること', () async {
      final initialEvents = [
        CareerEvent(date: '2020-01', title: 'Test 1', description: ''),
      ];
      final newEvent = CareerEvent(
        date: '2021-01',
        title: 'Error Event',
        description: '',
      );
      final exception = Exception('Failed to save event');

      when(
        () => mockRepository.fetchEvents(),
      ).thenAnswer((_) async => initialEvents);
      // saveEventで例外を発生させる
      when(() => mockRepository.saveEvent(any())).thenThrow(exception);

      final container = createContainer();
      await container.read(timelineEventsProvider.future);

      final states = <AsyncValue<List<CareerEvent>>>[];
      container.listen(timelineEventsProvider, (previous, next) {
        states.add(next);
      });

      // 実行 (例外が発生した場合に内部でキャッチしてstateを更新する処理のため、awaitのみ)
      await container.read(timelineEventsProvider.notifier).addEvent(newEvent);

      // 直後にはAsyncErrorになり、その後前回の状態へフォールバックされる実装となっている場合の確認
      // 実装の `if (previousState.hasValue)` により AsyncData へ戻るが、
      // 途中で AsyncError がEmitされていることを確認する。
      expect(states.any((s) => s is AsyncError), isTrue);

      verify(() => mockRepository.saveEvent(newEvent)).called(1);
    });
  });
}
