import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/presentation/goal_setup_dialog.dart';

import '../../../support/mocks.dart';
import '../../../support/pump.dart';

void main() {
  setUpAll(registerCommonFallbackValues);

  late MockEventRepository mockEventRepo;
  late MockDependencyRepository mockDependencyRepo;

  setUp(() {
    mockEventRepo = stubEventRepository();
    mockDependencyRepo = stubDependencyRepository();
  });

  List<Override> repositoryOverrides() => [
        eventRepositoryProvider.overrideWithValue(mockEventRepo),
        dependencyRepositoryProvider.overrideWithValue(mockDependencyRepo),
      ];

  Future<void> pumpDialog(WidgetTester tester) {
    return pumpInScaffold(
      tester,
      const GoalSetupDialog(),
      overrides: repositoryOverrides(),
    );
  }

  group('GoalSetupDialog', () {
    testWidgets('ダイアログが正しく表示されること', (tester) async {
      await pumpDialog(tester);

      expect(find.text('目標を設定'), findsOneWidget);
    });

    testWidgets('テンプレート一覧に「出産」が含まれること', (tester) async {
      await pumpDialog(tester);

      expect(find.text('出産'), findsAtLeast(1));
    });

    testWidgets('キャンセルボタンが表示されること', (tester) async {
      await pumpDialog(tester);

      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('適用ボタンが表示されること', (tester) async {
      await pumpDialog(tester);

      expect(find.text('適用'), findsOneWidget);
    });

    testWidgets('テンプレート選択後にゴール日設定セクションが表示されること', (tester) async {
      await pumpDialog(tester);

      // 「出産」テンプレートをタップ
      await tester.tap(find.text('出産').first);
      await tester.pumpAndSettle();

      expect(find.text('ゴール日'), findsOneWidget);
    });

    testWidgets('テンプレート選択後にプレビューセクションが表示されること', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text('出産').first);
      await tester.pumpAndSettle();

      expect(find.text('生成されるイベント'), findsOneWidget);
    });

    testWidgets('プレビューに妊活が含まれること', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text('出産').first);
      await tester.pumpAndSettle();

      expect(find.text('妊活'), findsOneWidget);
    });

    testWidgets('プレビューに転職タイミングの目安が含まれること', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text('出産').first);
      await tester.pumpAndSettle();

      expect(find.text('転職タイミングの目安'), findsOneWidget);
    });

    testWidgets('キャンセルボタンでダイアログが閉じること', (tester) async {
      bool dialogClosed = false;
      await pumpInScaffold(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (_) => const GoalSetupDialog(),
              );
              dialogClosed = true;
            },
            child: const Text('Open'),
          ),
        ),
        overrides: repositoryOverrides(),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(dialogClosed, isTrue);
    });

    testWidgets('テンプレート未選択時に適用ボタンが無効であること', (tester) async {
      await pumpDialog(tester);

      // 適用ボタンを探す - テンプレート未選択なのでボタンが非活性またはクリック不可
      final applyButton = find.text('適用');
      expect(applyButton, findsOneWidget);

      // ボタンのElevatedButton/FilledButtonのonPressedがnullであることを確認
      final buttonWidget = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '適用'),
      );
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('適用後にイベントが保存されること', (tester) async {
      final savedEvents = <LifeEvent>[];
      when(() => mockEventRepo.saveEvent(any())).thenAnswer((invocation) async {
        savedEvents.add(invocation.positionalArguments[0] as LifeEvent);
      });
      when(() => mockEventRepo.fetchEvents()).thenAnswer(
        (_) async => List.unmodifiable(savedEvents),
      );

      final savedDependencies = <EventDependency>[];
      when(
        () => mockDependencyRepo.saveDependency(any()),
      ).thenAnswer((invocation) async {
        savedDependencies.add(
          invocation.positionalArguments[0] as EventDependency,
        );
      });
      when(() => mockDependencyRepo.fetchDependencies()).thenAnswer(
        (_) async => List.unmodifiable(savedDependencies),
      );

      await pumpDialog(tester);

      // テンプレートを選択
      await tester.tap(find.text('出産').first);
      await tester.pumpAndSettle();

      // 適用ボタンをタップ
      await tester.tap(find.text('適用'));
      await tester.pumpAndSettle();

      // 少なくともゴールイベントが保存されたことを確認
      expect(savedEvents.isNotEmpty, isTrue);
    });
  });
}
