import 'package:go_router/go_router.dart';
import '../../features/timeline/presentation/timeline_screen.dart';

/// アプリのルーティング設定
///
/// 現在はタイムライン画面（`/`）のみ。
/// 認証フローはダイアログで処理するためルートは不要。
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TimelineScreen(),
    ),
  ],
);
