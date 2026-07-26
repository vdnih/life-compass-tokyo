import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/logic/goal_template_provider.dart';

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

    test('妊活イベントの日付がゴール-12ヶ月であること (2028-06 -> 2027-06)', () async {
      final container = createContainer();

      final result = await container
          .read(goalTemplateProvider.notifier)
          .applyTemplate(
            templateId: 'tmpl-childbirth',
            goalDate: '2028-06',
            goalTitle: '出産',
          );

      final nikkatsuEvent = result.generatedEvents
          .firstWhere((e) => e.title == '妊活');
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

    group('依存関係のoffsetMonthsの符号', () {
      test('妊活(T-12) -> 出産(T) の offsetMonths が +12 であること', () async {
        final container = createContainer();

        final result = await container
            .read(goalTemplateProvider.notifier)
            .applyTemplate(
              templateId: 'tmpl-childbirth',
              goalDate: '2028-06',
              goalTitle: '出産',
            );

        final goalEvent = result.generatedEvents.firstWhere((e) => e.isGoal);
        final katsudoEvent =
            result.generatedEvents.firstWhere((e) => e.title == '妊活');
        final dep = result.generatedDependencies
            .firstWhere((d) => d.sourceEventId == katsudoEvent.id);

        expect(dep.targetEventId, equals(goalEvent.id));
        // 妊活(T-12) -> 出産(T): offsetMonths = targetDate - sourceDate = +12
        expect(dep.offsetMonths, equals(12));
      });

      test('復職(T+12) -> 出産(T) の offsetMonths が -12 であること', () async {
        final container = createContainer();

        final result = await container
            .read(goalTemplateProvider.notifier)
            .applyTemplate(
              templateId: 'tmpl-childbirth',
              goalDate: '2028-06',
              goalTitle: '出産',
            );

        final goalEvent = result.generatedEvents.firstWhere((e) => e.isGoal);
        final returnEvent =
            result.generatedEvents.firstWhere((e) => e.title == '復職');
        final dep = result.generatedDependencies
            .firstWhere((d) => d.sourceEventId == returnEvent.id);

        expect(dep.targetEventId, equals(goalEvent.id));
        // 復職(T+12) -> 出産(T): offsetMonths = targetDate - sourceDate = -12
        expect(dep.offsetMonths, equals(-12));
      });
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

    // Wave 4: 結婚テンプレートのテスト
    group('結婚テンプレート (tmpl-marriage)', () {
      test('結婚テンプレートを適用すると wedding-ceremony ゴール + 5件のイベントが生成されること', () async {
        final container = createContainer();

        final result = await container
            .read(goalTemplateProvider.notifier)
            .applyTemplate(
              templateId: 'tmpl-marriage',
              goalDate: '2027-06',
              goalTitle: '結婚式',
            );

        // ゴール1件 + 関連5件 = 計6件
        expect(result.generatedEvents.length, equals(6));
      });

      test('結婚テンプレートのゴールイベントのcatalogIdがwedding-ceremonyであること', () async {
        final container = createContainer();

        final result = await container
            .read(goalTemplateProvider.notifier)
            .applyTemplate(
              templateId: 'tmpl-marriage',
              goalDate: '2027-06',
              goalTitle: '結婚式',
            );

        final goalEvent = result.generatedEvents.firstWhere((e) => e.isGoal);
        expect(goalEvent.catalogId, equals('wedding-ceremony'));
      });

      test('プロポーズイベントの日付がゴール-12ヶ月であること', () async {
        final container = createContainer();

        final result = await container
            .read(goalTemplateProvider.notifier)
            .applyTemplate(
              templateId: 'tmpl-marriage',
              goalDate: '2027-06',
              goalTitle: '結婚式',
            );

        final propose = result.generatedEvents
            .firstWhere((e) => e.title == 'プロポーズ');
        expect(propose.date, equals('2026-06'));
      });
    });

    // Wave 4: 転職テンプレートのテスト
    group('転職テンプレート (tmpl-job-change)', () {
      test('転職テンプレートを適用すると joining-company ゴール + 2件のイベントが生成されること', () async {
        final container = createContainer();

        final result = await container
            .read(goalTemplateProvider.notifier)
            .applyTemplate(
              templateId: 'tmpl-job-change',
              goalDate: '2027-04',
              goalTitle: '入社',
            );

        // ゴール1件 + 関連2件 = 計3件
        expect(result.generatedEvents.length, equals(3));
      });

      test('転職テンプレートのゴールイベントのcatalogIdがjoining-companyであること', () async {
        final container = createContainer();

        final result = await container
            .read(goalTemplateProvider.notifier)
            .applyTemplate(
              templateId: 'tmpl-job-change',
              goalDate: '2027-04',
              goalTitle: '入社',
            );

        final goalEvent = result.generatedEvents.firstWhere((e) => e.isGoal);
        expect(goalEvent.catalogId, equals('joining-company'));
      });
    });
  });
}
