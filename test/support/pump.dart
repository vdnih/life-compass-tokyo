import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/auth/logic/auth_provider.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';

import 'mocks.dart';

/// テスト用の [ProviderContainer] を生成し、テスト終了時に破棄する。
ProviderContainer createContainer({List<Override> overrides = const []}) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

/// スタブ済みリポジトリを差し込んだ [ProviderContainer] を生成する。
///
/// 差し込んだモックは [onEvents] / [onDependencies] で受け取り、
/// 呼び出し検証（`verify`）や異常系の再スタブに使う。
ProviderContainer createContainerWithRepositories({
  List<LifeEvent> events = const [],
  List<EventDependency> dependencies = const [],
  void Function(MockEventRepository)? onEvents,
  void Function(MockDependencyRepository)? onDependencies,
  List<Override> overrides = const [],
}) {
  final eventRepo = stubEventRepository(events: events);
  final dependencyRepo = stubDependencyRepository(dependencies: dependencies);
  onEvents?.call(eventRepo);
  onDependencies?.call(dependencyRepo);

  return createContainer(
    overrides: [
      eventRepositoryProvider.overrideWithValue(eventRepo),
      dependencyRepositoryProvider.overrideWithValue(dependencyRepo),
      ...overrides,
    ],
  );
}

/// [authStateProvider] を能動的に購読しつつ解決を待つ。
///
/// riverpod 3 では listener のいない [StreamProvider] の購読は一時停止されるため、
/// `container.read(provider.future)` を単独で呼ぶだけだと override した
/// Stream（`Stream.value` など）が配信されずハングする。テストで解決を待つ場合は
/// この関数を使い、能動的な listener を張ってから解決を待つこと。
Future<void> awaitAuthState(ProviderContainer container) {
  container.listen(authStateProvider, (_, _) {});
  return container.read(authStateProvider.future);
}

/// 未認証（ゲストモード）を表す [authStateProvider] の override。
Override guestAuth() =>
    authStateProvider.overrideWith((ref) => Stream<User?>.value(null));

/// 認証済みを表す [authStateProvider] の override。
Override signedInAuth({String uid = 'test-uid'}) {
  final user = MockUser();
  when(() => user.uid).thenReturn(uid);
  return authStateProvider.overrideWith((ref) => Stream<User?>.value(user));
}

/// 認証状態が未解決（`AsyncLoading` のまま）であることを表す [authStateProvider] の override。
///
/// 何も emit しないまま閉じない [StreamController] を使う。`Stream.empty()` は
/// 即座に完了扱いになり `AsyncLoading` のまま止まらないため使えない。
Override pendingAuth() {
  final controller = StreamController<User?>();
  addTearDown(controller.close);
  return authStateProvider.overrideWith((ref) => controller.stream);
}

/// [ProviderScope] と [MaterialApp] で包んだ [child] を pump する。
///
/// [size] を渡すと論理サイズを固定する（レスポンシブ分岐の検証用）。
/// テスト終了時に元のサイズへ戻す。
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// [pumpApp] の [Scaffold] 版。ダイアログ単体を置く場合に使う。
Future<void> pumpInScaffold(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Size? size,
}) {
  return pumpApp(
    tester,
    Scaffold(body: child),
    overrides: overrides,
    size: size,
  );
}
