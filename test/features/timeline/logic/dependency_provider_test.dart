import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';
import 'package:my_career_app/features/timeline/logic/dependency_provider.dart';

class MockDependencyRepository extends Mock implements DependencyRepository {}

class FakeEventDependency extends Fake implements EventDependency {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEventDependency());
  });

  group('DependencyNotifier', () {
    late MockDependencyRepository mockRepository;

    setUp(() {
      mockRepository = MockDependencyRepository();
    });

    ProviderContainer createContainer({
      List<EventDependency> initialDeps = const [],
    }) {
      when(() => mockRepository.fetchDependencies())
          .thenAnswer((_) async => List.of(initialDeps));
      final container = ProviderContainer(
        overrides: [
          dependencyRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('初期状態: リポジトリから依存関係一覧を取得すること', () async {
      const dep = EventDependency(
        id: 'dep-1',
        sourceEventId: 'event-a',
        targetEventId: 'event-b',
        offsetMonths: 3,
      );
      final container = createContainer(initialDeps: [dep]);

      final result = await container.read(dependencyProvider.future);

      expect(result, contains(dep));
    });

    group('addDependency', () {
      test('依存関係を追加するとリストに含まれること', () async {
        const dep = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          offsetMonths: 3,
        );

        // createContainerを先に呼ぶことでbuild()のfetchは[]を返す
        final container = createContainer();
        when(() => mockRepository.saveDependency(dep))
            .thenAnswer((_) async {});
        // 2回目のfetchDependencies（addDependency後）は[dep]を返す
        when(() => mockRepository.fetchDependencies())
            .thenAnswer((_) async => [dep]);

        await container.read(dependencyProvider.future);
        await container.read(dependencyProvider.notifier).addDependency(dep);

        final result = await container.read(dependencyProvider.future);
        expect(result, contains(dep));
      });

      test('saveDependencyが呼ばれること', () async {
        const dep = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          offsetMonths: 3,
        );

        final container = createContainer();
        when(() => mockRepository.saveDependency(dep))
            .thenAnswer((_) async {});
        when(() => mockRepository.fetchDependencies())
            .thenAnswer((_) async => [dep]);

        await container.read(dependencyProvider.future);
        await container.read(dependencyProvider.notifier).addDependency(dep);

        verify(() => mockRepository.saveDependency(dep)).called(1);
      });
    });

    group('removeDependency', () {
      test('依存関係を削除するとリストから除かれること', () async {
        const dep = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          offsetMonths: 3,
        );

        // createContainer(initialDeps: [dep])でbuild()のfetchは[dep]を返す
        final container = createContainer(initialDeps: [dep]);
        when(() => mockRepository.deleteDependency('dep-1'))
            .thenAnswer((_) async {});
        // 2回目のfetchDependencies（deleteDependency後）は[]を返す
        when(() => mockRepository.fetchDependencies())
            .thenAnswer((_) async => []);

        await container.read(dependencyProvider.future);

        await container
            .read(dependencyProvider.notifier)
            .removeDependency('dep-1');

        final result = await container.read(dependencyProvider.future);
        expect(result, isEmpty);
      });
    });

    group('removeDependenciesForEvent', () {
      test('イベントに関連する依存関係をすべて削除すること', () async {
        when(() =>
                mockRepository.deleteDependenciesForEvent('event-a'))
            .thenAnswer((_) async {});
        when(() => mockRepository.fetchDependencies())
            .thenAnswer((_) async => []);

        final container = createContainer();
        await container.read(dependencyProvider.future);

        await container
            .read(dependencyProvider.notifier)
            .removeDependenciesForEvent('event-a');

        verify(() => mockRepository.deleteDependenciesForEvent('event-a'))
            .called(1);
      });
    });

    group('updateDependencyOffset', () {
      test('offsetMonthsが更新されること', () async {
        const dep = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          offsetMonths: 3,
        );
        final updated = dep.copyWith(offsetMonths: 6);

        final container = createContainer(initialDeps: [dep]);
        when(() => mockRepository.updateDependency(updated))
            .thenAnswer((_) async {});
        when(() => mockRepository.fetchDependencies())
            .thenAnswer((_) async => [updated]);

        await container.read(dependencyProvider.future);
        await container
            .read(dependencyProvider.notifier)
            .updateDependencyOffset('dep-1', 6);

        final result = await container.read(dependencyProvider.future);
        expect(result.first.offsetMonths, equals(6));
      });

      test('updateDependencyが呼ばれること', () async {
        const dep = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          offsetMonths: 3,
        );

        final container = createContainer(initialDeps: [dep]);
        when(() => mockRepository.updateDependency(any()))
            .thenAnswer((_) async {});
        when(() => mockRepository.fetchDependencies())
            .thenAnswer((_) async => [dep.copyWith(offsetMonths: 9)]);

        await container.read(dependencyProvider.future);
        await container
            .read(dependencyProvider.notifier)
            .updateDependencyOffset('dep-1', 9);

        verify(() => mockRepository.updateDependency(any())).called(1);
      });
    });

    group('wouldCreateCycle', () {
      test('直接循環: A->B の後に B->A を追加すると循環が検出されること', () async {
        const depAB = EventDependency(
          id: 'dep-ab',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          offsetMonths: 1,
        );

        final container = createContainer(initialDeps: [depAB]);
        await container.read(dependencyProvider.future);

        final result = container
            .read(dependencyProvider.notifier)
            .wouldCreateCycle('event-b', 'event-a');

        expect(result, isTrue);
      });

      test('間接循環: A->B->C の後に C->A を追加すると循環が検出されること', () async {
        const depAB = EventDependency(
          id: 'dep-ab',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          offsetMonths: 1,
        );
        const depBC = EventDependency(
          id: 'dep-bc',
          sourceEventId: 'event-b',
          targetEventId: 'event-c',
          offsetMonths: 1,
        );

        final container = createContainer(initialDeps: [depAB, depBC]);
        await container.read(dependencyProvider.future);

        final result = container
            .read(dependencyProvider.notifier)
            .wouldCreateCycle('event-c', 'event-a');

        expect(result, isTrue);
      });

      test('循環しない依存関係は許可されること', () async {
        const depAB = EventDependency(
          id: 'dep-ab',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          offsetMonths: 1,
        );

        final container = createContainer(initialDeps: [depAB]);
        await container.read(dependencyProvider.future);

        final result = container
            .read(dependencyProvider.notifier)
            .wouldCreateCycle('event-b', 'event-c');

        expect(result, isFalse);
      });

      test('依存関係が存在しない場合は循環なしと判定されること', () async {
        final container = createContainer();
        await container.read(dependencyProvider.future);

        final result = container
            .read(dependencyProvider.notifier)
            .wouldCreateCycle('event-a', 'event-b');

        expect(result, isFalse);
      });

      test('自己参照は循環として検出されること', () async {
        final container = createContainer();
        await container.read(dependencyProvider.future);

        final result = container
            .read(dependencyProvider.notifier)
            .wouldCreateCycle('event-a', 'event-a');

        expect(result, isTrue);
      });
    });
  });
}
