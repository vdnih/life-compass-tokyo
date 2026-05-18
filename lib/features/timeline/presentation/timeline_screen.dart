import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/logic/auth_provider.dart';
import '../../auth/presentation/sign_in_dialog.dart';
import '../../catalog/presentation/catalog_panel.dart';
import '../../user_profile/user_profile.dart';
import '../../user_profile/profile_settings_dialog.dart';
import '../logic/budget_summary_provider.dart';
import '../logic/timeline_events_provider.dart';
import '../logic/constraint_checker_provider.dart';
import 'widgets/year_month_timeline.dart';
import 'widgets/year_timeline.dart';
import 'add_event_dialog.dart';
import 'goal_setup_dialog.dart';

enum TimelineViewMode { yearMonth, year }

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  TimelineViewMode _viewMode = TimelineViewMode.yearMonth;

  /// 書き込み操作に認証ガードをかけるヘルパー
  ///
  /// 未認証の場合は [SignInDialog] を表示し、認証済みの場合は [action] を実行する。
  void _withAuth(VoidCallback action) {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      showDialog<void>(
        context: context,
        builder: (context) => const SignInDialog(),
      );
    } else {
      action();
    }
  }

  /// 合計予算テキストを組み立てる
  String _formatTotalBudget(int totalYen) {
    if (totalYen == 0) return '';
    if (totalYen >= 100000000) {
      final oku = (totalYen / 100000000).toStringAsFixed(1);
      return '合計 ¥${oku}億';
    }
    if (totalYen >= 10000) {
      final man = (totalYen / 10000).round();
      return '合計 ¥${man}万';
    }
    return '合計 ¥${totalYen}円';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final eventsAsync = ref.watch(timelineEventsProvider);
    final authAsync = ref.watch(authStateProvider);
    final totalBudget = ref.watch(budgetSummaryProvider);

    final isLoggedIn = authAsync.valueOrNull != null;

    // AppBar に表示するユーザー名テキストを構築
    final displayName = profileAsync.maybeWhen(
      data: (profile) => profile?.name ?? 'ゲスト',
      orElse: () => 'ゲスト',
    );
    final ageText = profileAsync.maybeWhen(
      data: (profile) => profile?.age != null ? '${profile!.age}歳' : '',
      orElse: () => '',
    );
    final totalBudgetText = _formatTotalBudget(totalBudget);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'わたしのライフプラン',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              ageText.isNotEmpty ? '$displayName  $ageText' : displayName,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // 合計予算チップ
          if (totalBudgetText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  totalBudgetText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<TimelineViewMode>(
              segments: const [
                ButtonSegment(
                  value: TimelineViewMode.yearMonth,
                  label: Text('年月', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.calendar_view_month, size: 16),
                ),
                ButtonSegment(
                  value: TimelineViewMode.year,
                  label: Text('年', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.calendar_today, size: 16),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (Set<TimelineViewMode> newSelection) {
                setState(() {
                  _viewMode = newSelection.first;
                });
              },
              showSelectedIcon: false,
            ),
          ),
          // 目標設定ボタン（認証ガード付き）
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: '目標設定',
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              onPressed: () => _withAuth(() {
                showDialog(
                  context: context,
                  builder: (context) => const GoalSetupDialog(),
                );
              }),
            ),
          ),
          // プロフィール / サインインボタン
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: isLoggedIn
                    ? const Icon(Icons.person, color: Colors.white, size: 18)
                    : const Icon(
                        Icons.login_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
              onPressed: () {
                if (isLoggedIn) {
                  showDialog(
                    context: context,
                    builder: (context) => const ProfileSettingsDialog(),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => const SignInDialog(),
                  );
                }
              },
            ),
          ),
          // サインアウトボタン（ログイン中のみ表示）
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                tooltip: 'サインアウト',
                icon:
                    const Icon(Icons.logout, color: Colors.white70, size: 20),
                onPressed: () async {
                  final authRepo = ref.read(authRepositoryProvider);
                  await authRepo.signOut();
                },
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 600;

          final timelineBody = eventsAsync.when(
            data: (events) => _viewMode == TimelineViewMode.yearMonth
                ? YearMonthTimeline(
                    events: events,
                    constraints: ref.watch(constraintCheckerProvider),
                  )
                : YearTimeline(
                    events: events,
                    constraints: ref.watch(constraintCheckerProvider),
                  ),
            loading: () => Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
            error: (e, _) => Center(
              child: Text(
                'エラーが発生しました: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );

          if (isDesktop) {
            // デスクトップ: 左にカタログパネル（200px固定）+ 右にタイムライン
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 200,
                  child: CatalogPanel(),
                ),
                Container(width: 1, color: Colors.grey.shade200),
                Expanded(child: timelineBody),
              ],
            );
          } else {
            // モバイル: タイムラインのみ表示（カタログはドロワーボタンで開く）
            return Builder(
              builder: (ctx) => Stack(
                children: [
                  timelineBody,
                  Positioned(
                    bottom: 88,
                    left: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'catalog_panel_btn',
                      tooltip: 'カタログを開く',
                      backgroundColor: AppTheme.primary,
                      onPressed: () {
                        Scaffold.of(ctx).openDrawer();
                      },
                      child: const Icon(Icons.menu_book_outlined,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      drawer: const Drawer(
        width: 220,
        child: CatalogPanel(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _withAuth(() {
          showDialog(
            context: context,
            builder: (context) => const AddEventDialog(),
          );
        }),
        tooltip: 'イベントを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
