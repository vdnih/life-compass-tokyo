import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/ai_coach/data/coach_repository.dart';
import 'package:my_career_app/features/ai_coach/data/gemini_coach_repository.dart';
import 'package:my_career_app/features/ai_coach/domain/coach_turn.dart';
import 'package:my_career_app/features/ai_coach/presentation/chat_controller.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';

import '../../../support/mocks.dart';
import '../../../support/pump.dart';

/// [executeTool] を呼び出さずに固定応答を返す Fake。
///
/// 実 API は叩かない（CLAUDE.md §5）。executeTool を実際に呼ぶ挙動を
/// 検証したいテストは [_ExecutingFakeCoachRepository] を使う。
class _ThrowingFakeCoachRepository implements CoachRepository {
  final Object error;

  _ThrowingFakeCoachRepository(this.error);

  @override
  Future<CoachTurn> send(String text, {required ToolExecutor executeTool}) async {
    throw error;
  }
}

/// [toolCalls] を1つずつ [executeTool] に渡して実行する Fake。
///
/// applyGoalTemplate / addEventFromCatalog が Provider に正しい引数で
/// 届くかを検証するために使う。
class _ExecutingFakeCoachRepository implements CoachRepository {
  final List<(String, Map<String, Object?>)> toolCalls;
  final String responseText;

  _ExecutingFakeCoachRepository(this.toolCalls, {this.responseText = 'AI応答'});

  @override
  Future<CoachTurn> send(String text, {required ToolExecutor executeTool}) async {
    for (final (name, args) in toolCalls) {
      await executeTool(name, args);
    }
    return CoachTurn(responseText: responseText);
  }
}

void main() {
  setUpAll(registerCommonFallbackValues);

  test('applyGoalTemplate のアクションが applyTemplate に正しい引数で届き、生成イベント・依存関係が集計されること', () async {
    final container = createContainerWithRepositories(
      overrides: [
        guestAuth(),
        coachRepositoryProvider.overrideWithValue(
          _ExecutingFakeCoachRepository([
            (
              'applyGoalTemplate',
              {
                'templateId': 'tmpl-childbirth',
                'goalYearMonth': '2028-03',
                'goalTitle': '出産',
              },
            ),
          ]),
        ),
      ],
    );
    await awaitAuthState(container);

    final result =
        await container.read(chatControllerProvider.notifier).send('子どもがほしい');

    expect(result, isNotNull);
    expect(result!.addedEvents, isNotEmpty);
    // tmpl-childbirth のゴールイベント + 関連イベント一式の依存関係が
    // すべて生成されていること（GoalTemplateNotifier.applyTemplate の仕様）。
    expect(result.addedDependencies.length, result.addedEvents.length - 1);
  });

  test('addEventFromCatalog が実行されるとイベントが1件追加され集計されること', () async {
    final container = createContainerWithRepositories(
      // ChatController は「実行前後の timelineEventsProvider の差分」で
      // 追加イベントを特定するため、デフォルトの stub（fetchEvents が常に
      // 固定リストを返す）では差分が出ない。saveEvent された内容を
      // fetchEvents に反映するスタブに差し替える
      // （test/features/timeline/logic/timeline_events_provider_test.dart
      // と同じパターン）。
      onEvents: (mock) {
        final saved = <LifeEvent>[];
        when(() => mock.saveEvent(any())).thenAnswer((invocation) async {
          saved.add(invocation.positionalArguments[0] as LifeEvent);
        });
        when(mock.fetchEvents).thenAnswer((_) async => List.of(saved));
      },
      overrides: [
        guestAuth(),
        coachRepositoryProvider.overrideWithValue(
          _ExecutingFakeCoachRepository(
            [
              (
                'addEventFromCatalog',
                {'catalogId': 'propose', 'yearMonth': '2027-06'},
              ),
            ],
            responseText: 'プロポーズの予定を置きました。',
          ),
        ),
      ],
    );
    await awaitAuthState(container);

    final result = await container
        .read(chatControllerProvider.notifier)
        .send('プロポーズの予定を置いて');

    expect(result, isNotNull);
    expect(result!.addedEvents, hasLength(1));
    expect(result.addedEvents.single.catalogId, 'propose');
    expect(result.addedDependencies, isEmpty);

    final messages = container.read(chatControllerProvider).messages;
    expect(messages.last.text, 'プロポーズの予定を置きました。');
  });

  test('未知の catalogId で addEventFromCatalog を呼んでもイベントは追加されないこと', () async {
    final container = createContainerWithRepositories(
      overrides: [
        guestAuth(),
        coachRepositoryProvider.overrideWithValue(
          _ExecutingFakeCoachRepository([
            (
              'addEventFromCatalog',
              {'catalogId': 'no-such-catalog-id', 'yearMonth': '2027-06'},
            ),
          ]),
        ),
      ],
    );
    await awaitAuthState(container);

    final result =
        await container.read(chatControllerProvider.notifier).send('よくわからない予定');

    expect(result, isNull);
  });

  test('Repository が例外を投げたとき ScriptedCoach の固定応答にフォールバックすること', () async {
    final container = createContainerWithRepositories(
      overrides: [
        guestAuth(),
        coachRepositoryProvider.overrideWithValue(
          _ThrowingFakeCoachRepository(Exception('network down')),
        ),
      ],
    );
    await awaitAuthState(container);

    final result =
        await container.read(chatControllerProvider.notifier).send('子どもがほしい');

    // ScriptedCoach のキーワード一致でテンプレートが展開されること
    // （AI が落ちてもチャットが完全に沈黙しない）。
    expect(result, isNotNull);
    expect(result!.addedEvents, isNotEmpty);

    final messages = container.read(chatControllerProvider).messages;
    expect(messages.last.text, contains('不安定'));
  });

  test('undoLast で追加されたイベントと依存関係の両方が削除されること', () async {
    late final MockEventRepository eventRepo;
    late final MockDependencyRepository dependencyRepo;

    final container = createContainerWithRepositories(
      onEvents: (m) => eventRepo = m,
      onDependencies: (m) => dependencyRepo = m,
      overrides: [
        guestAuth(),
        coachRepositoryProvider.overrideWithValue(
          _ExecutingFakeCoachRepository([
            (
              'applyGoalTemplate',
              {
                'templateId': 'tmpl-marriage',
                'goalYearMonth': '2028-01',
                'goalTitle': '結婚',
              },
            ),
          ]),
        ),
      ],
    );
    await awaitAuthState(container);

    final result =
        await container.read(chatControllerProvider.notifier).send('結婚したい');
    expect(result, isNotNull);

    await container.read(chatControllerProvider.notifier).undoLast(result!);

    for (final event in result.addedEvents) {
      verify(() => eventRepo.deleteEvent(event)).called(1);
    }
    for (final dep in result.addedDependencies) {
      verify(() => dependencyRepo.deleteDependency(dep.id)).called(1);
    }
  });
}
