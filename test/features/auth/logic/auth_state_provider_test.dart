import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/auth/data/auth_repository.dart';
import 'package:my_career_app/features/auth/domain/app_user.dart';
import 'package:my_career_app/features/auth/logic/auth_state_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

ProviderContainer createContainer(MockAuthRepository mock) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(mock)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('authStateChangesProvider', () {
    test('未認証時は null を流す', () async {
      final mock = MockAuthRepository();
      when(() => mock.authStateChanges())
          .thenAnswer((_) => Stream.value(null));
      final container = createContainer(mock);

      await expectLater(
        container.read(authStateChangesProvider.stream),
        emits(null),
      );
    });

    test('認証済みの場合は AppUser を流す', () async {
      const user = AppUser(uid: 'uid-1', displayName: 'Taro');
      final mock = MockAuthRepository();
      when(() => mock.authStateChanges())
          .thenAnswer((_) => Stream.value(user));
      final container = createContainer(mock);

      await expectLater(
        container.read(authStateChangesProvider.stream),
        emits(user),
      );
    });
  });

  group('AuthNotifier.signInWithGoogle', () {
    test('成功時に AsyncLoading → AsyncData(AppUser) に遷移する', () async {
      const user = AppUser(uid: 'uid-1', displayName: 'Taro');
      final mock = MockAuthRepository();
      when(() => mock.authStateChanges())
          .thenAnswer((_) => Stream.value(null));
      when(() => mock.signInWithGoogle()).thenAnswer((_) async => user);

      final container = createContainer(mock);
      // build() が完了してから listen を登録することで、
      // signInWithGoogle() による状態変化のみをキャプチャする
      await container.read(authNotifierProvider.future);

      final states = <AsyncValue<AppUser?>>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await container.read(authNotifierProvider.notifier).signInWithGoogle();

      expect(states.first, isA<AsyncLoading>());
      expect(states.last.value, equals(user));
    });

    test('失敗時に AsyncError になる', () async {
      final mock = MockAuthRepository();
      when(() => mock.authStateChanges())
          .thenAnswer((_) => Stream.value(null));
      when(() => mock.signInWithGoogle())
          .thenThrow(Exception('キャンセルされました'));

      final container = createContainer(mock);
      await container.read(authNotifierProvider.notifier).signInWithGoogle();

      expect(container.read(authNotifierProvider), isA<AsyncError>());
    });
  });

  group('AuthNotifier.signOut', () {
    test('サインアウト後に AsyncData(null) になる', () async {
      const user = AppUser(uid: 'uid-1');
      final mock = MockAuthRepository();
      when(() => mock.authStateChanges())
          .thenAnswer((_) => Stream.value(user));
      when(() => mock.signOut()).thenAnswer((_) async {});

      final container = createContainer(mock);
      await container.read(authNotifierProvider.notifier).signOut();

      expect(container.read(authNotifierProvider).value, isNull);
    });
  });
}
