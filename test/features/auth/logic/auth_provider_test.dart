import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_career_app/features/auth/data/auth_service.dart';
import 'package:my_career_app/features/auth/logic/auth_provider.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {
  @override
  final String uid;

  MockUser(this.uid);
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  ProviderContainer _makeContainer({
    required Stream<User?> authStream,
  }) {
    when(() => mockAuthService.authStateChanges).thenAnswer((_) => authStream);
    return ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
  }

  group('AuthNotifier', () {
    group('build()', () {
      test('未認証状態のストリームを受け取ると null を返すこと', () async {
        final container = _makeContainer(
          authStream: Stream.value(null),
        );
        addTearDown(container.dispose);

        await container.read(authProvider.future);

        expect(container.read(authProvider).valueOrNull, isNull);
      });

      test('認証済みユーザーのストリームを受け取ると User を返すこと', () async {
        final user = MockUser('test-uid-123');
        final container = _makeContainer(
          authStream: Stream.value(user),
        );
        addTearDown(container.dispose);

        await container.read(authProvider.future);

        expect(container.read(authProvider).valueOrNull, equals(user));
      });

      test('currentUserIdProvider は認証済みユーザーの uid を返すこと', () async {
        final user = MockUser('test-uid-456');
        final container = _makeContainer(
          authStream: Stream.value(user),
        );
        addTearDown(container.dispose);

        await container.read(authProvider.future);

        expect(container.read(currentUserIdProvider), equals('test-uid-456'));
      });

      test('currentUserIdProvider は未認証時に null を返すこと', () async {
        final container = _makeContainer(
          authStream: Stream.value(null),
        );
        addTearDown(container.dispose);

        await container.read(authProvider.future);

        expect(container.read(currentUserIdProvider), isNull);
      });
    });

    group('signIn()', () {
      test('signIn() が AuthService.signIn() を正しいパラメータで呼び出すこと', () async {
        when(() => mockAuthService.authStateChanges)
            .thenAnswer((_) => const Stream.empty());
        when(() => mockAuthService.signIn(any(), any()))
            .thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(authProvider.notifier)
            .signIn('test@example.com', 'password123');

        verify(() => mockAuthService.signIn('test@example.com', 'password123'))
            .called(1);
      });

      test('signIn() が失敗すると AsyncError 状態になること', () async {
        when(() => mockAuthService.authStateChanges)
            .thenAnswer((_) => const Stream.empty());
        when(() => mockAuthService.signIn(any(), any()))
            .thenThrow(Exception('auth error'));

        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(authProvider.notifier)
            .signIn('bad@example.com', 'wrong');

        expect(container.read(authProvider).hasError, isTrue);
      });
    });

    group('signOut()', () {
      test('signOut() が AuthService.signOut() を呼び出すこと', () async {
        when(() => mockAuthService.authStateChanges)
            .thenAnswer((_) => const Stream.empty());
        when(() => mockAuthService.signOut()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authProvider.notifier).signOut();

        verify(() => mockAuthService.signOut()).called(1);
      });
    });
  });
}
