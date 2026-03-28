import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/logic/auth_state_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/timeline/presentation/timeline_screen.dart';

/// アプリ内のルートパス定数。
class AppRoutes {
  static const timeline = '/';
  static const login = '/login';
}

/// GoRouter インスタンスを提供する Provider。
final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthStateListenable(ref);

  return GoRouter(
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authAsync = ref.read(authStateChangesProvider);
      // 初期ロード中はリダイレクトしない（チラつき防止）
      if (authAsync.isLoading || authAsync.hasError) return null;

      final isAuthenticated = authAsync.valueOrNull != null;
      final isOnLoginPage = state.matchedLocation == AppRoutes.login;

      if (!isAuthenticated && !isOnLoginPage) return AppRoutes.login;
      if (isAuthenticated && isOnLoginPage) return AppRoutes.timeline;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.timeline,
        builder: (_, __) => const TimelineScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
    ],
  );
});

/// Riverpod の認証 Stream を GoRouter の [Listenable] インターフェースに橋渡しするクラス。
///
/// 認証状態が変化するたびに [notifyListeners] を呼び出し、
/// GoRouter のリダイレクト処理を再トリガーする。
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(ProviderRef ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }
}
