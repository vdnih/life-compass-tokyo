import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';

void main() {
  group('InMemoryDependencyRepository', () {
    late InMemoryDependencyRepository repository;

    setUp(() {
      repository = InMemoryDependencyRepository();
    });

    group('saveDependency / fetchDependencies', () {
      test('保存した依存関係がfetchDependenciesで取得できること', () async {
        const dep = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          type: DependencyType.prerequisite,
          offsetMonths: 3,
        );

        await repository.saveDependency(dep);
        final result = await repository.fetchDependencies();

        expect(result.contains(dep), isTrue);
      });

      test('複数の依存関係を保存すると全件取得できること', () async {
        const dep1 = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          type: DependencyType.prerequisite,
          offsetMonths: 3,
        );
        const dep2 = EventDependency(
          id: 'dep-2',
          sourceEventId: 'event-b',
          targetEventId: 'event-c',
          type: DependencyType.consequence,
          offsetMonths: 0,
        );

        await repository.saveDependency(dep1);
        await repository.saveDependency(dep2);
        final result = await repository.fetchDependencies();

        expect(result.length, equals(2));
      });

      test('初期状態では空リストを返すこと', () async {
        final result = await repository.fetchDependencies();

        expect(result, isEmpty);
      });
    });

    group('deleteDependency', () {
      test('IDを指定して依存関係を削除できること', () async {
        const dep = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          type: DependencyType.prerequisite,
          offsetMonths: 3,
        );

        await repository.saveDependency(dep);
        await repository.deleteDependency('dep-1');
        final result = await repository.fetchDependencies();

        expect(result, isEmpty);
      });

      test('存在しないIDで削除しても例外を投げないこと', () async {
        await expectLater(
          repository.deleteDependency('non-existent'),
          completes,
        );
      });
    });

    group('deleteDependenciesForEvent', () {
      test('指定イベントに関連するすべての依存関係が削除されること', () async {
        const dep1 = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          type: DependencyType.prerequisite,
          offsetMonths: 3,
        );
        const dep2 = EventDependency(
          id: 'dep-2',
          sourceEventId: 'event-b',
          targetEventId: 'event-c',
          type: DependencyType.consequence,
          offsetMonths: 0,
        );
        const dep3 = EventDependency(
          id: 'dep-3',
          sourceEventId: 'event-x',
          targetEventId: 'event-y',
          type: DependencyType.deadline,
          offsetMonths: 6,
        );

        await repository.saveDependency(dep1);
        await repository.saveDependency(dep2);
        await repository.saveDependency(dep3);

        await repository.deleteDependenciesForEvent('event-b');
        final result = await repository.fetchDependencies();

        expect(result.length, equals(1));
        expect(result.first.id, equals('dep-3'));
      });

      test('関連する依存関係がない場合も例外を投げないこと', () async {
        await expectLater(
          repository.deleteDependenciesForEvent('event-z'),
          completes,
        );
      });
    });

    group('fetchDependenciesForEvent', () {
      test('指定イベントが関わる依存関係のみ返すこと', () async {
        const dep1 = EventDependency(
          id: 'dep-1',
          sourceEventId: 'event-a',
          targetEventId: 'event-b',
          type: DependencyType.prerequisite,
          offsetMonths: 3,
        );
        const dep2 = EventDependency(
          id: 'dep-2',
          sourceEventId: 'event-b',
          targetEventId: 'event-c',
          type: DependencyType.consequence,
          offsetMonths: 0,
        );
        const dep3 = EventDependency(
          id: 'dep-3',
          sourceEventId: 'event-x',
          targetEventId: 'event-y',
          type: DependencyType.deadline,
          offsetMonths: 6,
        );

        await repository.saveDependency(dep1);
        await repository.saveDependency(dep2);
        await repository.saveDependency(dep3);

        final result = await repository.fetchDependenciesForEvent('event-b');

        expect(result.length, equals(2));
        expect(result.map((d) => d.id).toList(), containsAll(['dep-1', 'dep-2']));
      });

      test('関連する依存関係がない場合は空リストを返すこと', () async {
        final result = await repository.fetchDependenciesForEvent('event-z');

        expect(result, isEmpty);
      });
    });
  });
}
