import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/logic/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/timeline/presentation/timeline_screen.dart';

/// アプリのルーティングを管理するProvider
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  return GoRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      // 認証済みならログイン/サインアップ画面に留まらせない
      if (isLoggedIn && isAuthRoute) return '/';
      // 未認証でもタイムラインは閲覧可能（リダイレクトなし）
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
    ],
  );
});

/// Riverpod の [authProvider] の変化を GoRouter に通知するブリッジ
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
