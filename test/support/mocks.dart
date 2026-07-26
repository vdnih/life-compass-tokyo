import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/timeline/data/dependency_repository.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';
import 'package:my_career_app/features/timeline/domain/event_dependency.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';

/// テスト全体で共有するモック定義。
///
/// 各テストファイルで個別に `class MockEventRepository extends Mock ...` を
/// 宣言すると、スタブの初期値が少しずつ食い違ったまま増殖する。定義はここだけに置く。
class MockEventRepository extends Mock implements EventRepository {}

class MockDependencyRepository extends Mock implements DependencyRepository {}

class MockUser extends Mock implements User {}

class _FakeLifeEvent extends Fake implements LifeEvent {}

class _FakeEventDependency extends Fake implements EventDependency {}

/// `any()` をドメインモデル引数に対して使うための fallback 値を登録する。
///
/// mocktail は `any()` に対して型ごとの fallback 値を要求する。各テストの
/// `setUpAll` から呼ぶこと。重複して呼んでも副作用は無い。
void registerCommonFallbackValues() {
  registerFallbackValue(_FakeLifeEvent());
  registerFallbackValue(_FakeEventDependency());
}

/// 全メソッドをスタブ済みの [MockEventRepository] を返す。
///
/// 読み取りは [events] を返し、書き込みは何もしない。
/// 個別のテストで異常系を検証したい場合は、戻り値に対して `when` を上書きする。
MockEventRepository stubEventRepository({List<LifeEvent> events = const []}) {
  final mock = MockEventRepository();
  when(mock.fetchEvents).thenAnswer((_) async => List.of(events));
  when(() => mock.saveEvent(any())).thenAnswer((_) async {});
  when(() => mock.deleteEvent(any())).thenAnswer((_) async {});
  when(() => mock.updateEvent(any())).thenAnswer((_) async {});
  return mock;
}

/// 全メソッドをスタブ済みの [MockDependencyRepository] を返す。
///
/// 読み取りは [dependencies] を返し、書き込みは何もしない。
MockDependencyRepository stubDependencyRepository({
  List<EventDependency> dependencies = const [],
}) {
  final mock = MockDependencyRepository();
  when(mock.fetchDependencies).thenAnswer((_) async => List.of(dependencies));
  when(() => mock.saveDependency(any())).thenAnswer((_) async {});
  when(() => mock.deleteDependency(any())).thenAnswer((_) async {});
  when(() => mock.updateDependency(any())).thenAnswer((_) async {});
  when(() => mock.deleteDependenciesForEvent(any())).thenAnswer((_) async {});
  when(() => mock.fetchDependenciesForEvent(any()))
      .thenAnswer((_) async => const []);
  return mock;
}
