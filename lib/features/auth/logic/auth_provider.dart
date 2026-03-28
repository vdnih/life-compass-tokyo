import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_service.dart';

/// 認証状態を管理する Riverpod AsyncNotifier
class AuthNotifier extends AsyncNotifier<User?> {
  StreamSubscription<User?>? _subscription;

  @override
  Future<User?> build() async {
    final authService = ref.read(authServiceProvider);

    ref.onDispose(() => _subscription?.cancel());

    final completer = Completer<User?>();
    bool isFirst = true;

    _subscription = authService.authStateChanges.listen(
      (user) {
        if (isFirst) {
          isFirst = false;
          completer.complete(user);
        } else {
          state = AsyncValue.data(user);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (isFirst) {
          isFirst = false;
          completer.completeError(error, stackTrace);
        } else {
          state = AsyncValue.error(error, stackTrace);
        }
      },
    );

    return completer.future;
  }

  /// メールとパスワードでサインイン
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).signIn(email, password);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// メールとパスワードでサインアップ
  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).signUp(email, password);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// 認証状態を管理するProvider
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

/// 現在ログイン中のユーザーIDを提供する派生Provider
///
/// 未認証の場合は null を返す
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).valueOrNull?.uid;
});
