import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

/// Firebase の認証状態変化を流す StreamProvider。
///
/// GoRouter のリダイレクト判断に使用する。
/// サインアウト時は null を流す。
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Google Sign-In / サインアウト操作と、その非同期状態を管理する Notifier。
///
/// ログインボタンの loading / error 表示に使用する。
class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.watch(authRepositoryProvider).authStateChanges().first;
  }

  /// Google アカウントでサインインする。
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  /// サインアウトする。
  Future<void> signOut() async {
    state = const AsyncLoading();
    await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
    state = const AsyncData(null);
  }
}

/// [AuthNotifier] を提供する Provider。
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AppUser?>(() => AuthNotifier());
