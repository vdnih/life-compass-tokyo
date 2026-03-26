import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/dependency_provider.dart';
import 'package:my_career_app/features/timeline/logic/goal_template_provider.dart';
import 'package:my_career_app/features/timeline/logic/timeline_events_provider.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockDependencyRepository extends Mock implements DependencyRepository {}

class FakeLifeEvent extends Fake implements LifeEvent {}

class FakeEventDependency extends Fake implements EventDependency {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLifeEvent());
    registerFallbackValue(FakeEventDependency());
  });

  group('GoalTemplateNotifier', () {
    late MockEventRepository mockEventRepository;
    late MockDependencyRepository mockDependencyRepository;

    setUp(() {
      mockEventRepository = MockEventRepository();
      mockDependencyRepository = MockDependencyRepository();
    });

    ProviderContainer createContainer() {
      when(() => mockEventRepository.fetchEvents()).thenAnswer((_) async => []);
      when(() => mockEventRepository.saveEvent(any())).thenAnswer((_) async {});
      when(() => mockDependencyRepository.fetchDependencies())
          .thenAnswer((_) async => []);
      when(() => mockDependencyRepository.saveDependency(any()))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
          dependencyRepositoryProvider
              .overrideWithValue(mockDependencyRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('出産テンプレートを適用すると7件のイベントが生成されること', () async {
      final container = createContainer();

      when(() => mockEventRepository.fetchEvents())
          .thenAnswer((_) async => []);

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-06',
            goalTitle: '出産',
          );

      expect(result.generatedEvents.length, equals(7));
    });

    test('ゴールイベントはisGoal=trueであること', () async {
      final container = createContainer();

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-06',
            goalTitle: '出産',
          );

      final goalEvents = result.generatedEvents.where((e) => e.isGoal).toList();
      expect(goalEvents.length, equals(1));
    });

    test('すべての生成イベントにgoalIdが設定されていること', () async {
      final container = createContainer();

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-06',
            goalTitle: '出産',
          );

      final allHaveGoalId = result.generatedEvents.every((e) => e.goalId != null);
      expect(allHaveGoalId, isTrue);
    });

    test('すべての生成イベントのgoalIdがゴールイベントのidと一致すること', () async {
      final container = createContainer();

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-06',
            goalTitle: '出産',
          );

      final goalEvent = result.generatedEvents.firstWhere((e) => e.isGoal);
      final allGoalIds = result.generatedEvents.map((e) => e.goalId).toSet();
      expect(allGoalIds, equals({goalEvent.id}));
    });

    test('妊活開始イベントの日付がゴール-12ヶ月であること (2028-06 -> 2027-06)', () async {
      final container = createContainer();

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-06',
            goalTitle: '出産',
          );

      final nikkatsuEvent = result.generatedEvents
          .firstWhere((e) => e.title == '妊活開始');
      expect(nikkatsuEvent.date, equals('2027-06'));
    });

    test('産休開始イベントの日付がゴール-2ヶ月であること (2028-06 -> 2028-04)', () async {
      final container = createContainer();

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-06',
            goalTitle: '出産',
          );

      final sankyu = result.generatedEvents
          .firstWhere((e) => e.title == '産休開始');
      expect(sankyu.date, equals('2028-04'));
    });

    test('復職イベントの日付がゴール+12ヶ月であること (2028-06 -> 2029-06)', () async {
      final container = createContainer();

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-06',
            goalTitle: '出産',
          );

      final returnEvent = result.generatedEvents
          .firstWhere((e) => e.title == '復職');
      expect(returnEvent.date, equals('2029-06'));
    });

    test('依存関係が生成されていること', () async {
      final container = createContainer();

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-06',
            goalTitle: '出産',
          );

      expect(result.generatedDependencies, isNotEmpty);
    });

    test('年境界: ゴール日が1月でゴール-2ヶ月の場合に前年11月になること (2028-01 -> 2027-11)', () async {
      final container = createContainer();

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-01',
            goalTitle: '出産',
          );

      final sankyu = result.generatedEvents
          .firstWhere((e) => e.title == '産休開始');
      expect(sankyu.date, equals('2027-11'));
    });
  });
}
