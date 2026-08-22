import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../ai_coach/presentation/coach_chat_panel.dart';
import '../../ai_coach/presentation/coach_chat_sheet.dart';
import '../../ai_coach/presentation/widgets/panel_tab_bar.dart';
import '../../auth/logic/auth_provider.dart';
import '../../auth/presentation/sign_in_dialog.dart';
import '../../catalog/presentation/catalog_panel.dart';
import '../../user_profile/user_profile.dart';
import '../../user_profile/profile_settings_dialog.dart';
import '../logic/budget_summary_provider.dart';
import '../logic/timeline_events_provider.dart';
import '../logic/constraint_checker_provider.dart';
import 'widgets/template_set_panel.dart';
import 'widgets/timeline_view.dart';
import 'add_event_dialog.dart';
import 'timeline_keys.dart';

export 'widgets/timeline_view.dart' show TimelineViewMode;

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  TimelineViewMode _viewMode = TimelineViewMode.yearMonth;

  /// 合計予算テキストを組み立てる
  String _formatTotalBudget(int totalYen) {
    if (totalYen == 0) return '';
    if (totalYen >= 100000000) {
      final oku = (totalYen / 100000000).toStringAsFixed(1);
      return '合計 ¥$oku億';
    }
    if (totalYen >= 10000) {
      final man = (totalYen / 10000).round();
      return '合計 ¥$man万';
    }
    return '合計 ¥$totalYen円';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final eventsAsync = ref.watch(timelineEventsProvider);
    final authAsync = ref.watch(authStateProvider);
    final totalBudget = ref.watch(budgetSummaryProvider);

    final isLoggedIn = authAsync.value != null;
    final authPending = ref.watch(authPendingProvider);

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
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
            data: (events) => TimelineView(
              key: _viewMode == TimelineViewMode.yearMonth
                  ? TimelineKeys.timelineYearMonth
                  : TimelineKeys.timelineYear,
              mode: _viewMode,
              events: events,
              constraints: ref.watch(constraintCheckerProvider),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
            error: (e, _) => Center(
              child: Text(
                'エラーが発生しました: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );

          final timelineWithAddButton = Stack(
            children: [
              timelineBody,
              Positioned(
                bottom: 16,
                left: 12,
                child: FloatingActionButton.small(
                  heroTag: 'add_event_btn',
                  tooltip: 'イベントを追加',
                  backgroundColor: AppTheme.primary,
                  onPressed: authPending
                      ? null
                      : () {
                          showDialog<void>(
                            context: context,
                            builder: (_) => const AddEventDialog(),
                          );
                        },
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          );

          if (isDesktop) {
            // デスクトップ: 左パネルを「AIコーチ / カタログ」タブ化（280px固定）+ 右にタイムライン
            // spike/ai-chat-ux: PDR-006 Step 2。対話ファーストにするためカタログは二軍タブに回す
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 280, child: _DesktopCoachPanel()),
                Container(width: 1, color: Colors.grey.shade200),
                Expanded(child: timelineWithAddButton),
              ],
            );
          } else {
            // モバイル: タイムライン全画面 + ボトムシート型チャット（＋ボタンでイベント追加も残す）
            // spike/ai-chat-ux: シートの折りたたみ高さ分タイムラインと両FABを底上げし、
            // 隠れないようにする（CoachChatSheet._collapsedSize と概ね対応する固定値）
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 88),
                  child: timelineWithAddButton,
                ),
                const CoachChatSheet(),
              ],
            );
          }
        },
      ),
    );
  }
}

/// デスクトップ左パネルの「AIコーチ / カタログ / テンプレート」タブ切り替え
///
/// spike/ai-chat-ux: 全タブを常時マウントしたまま表示だけ切り替える（カタログの検索
/// 文字列・展開状態を保つため）。`IndexedStack` は非選択タブの子を
/// `debugVisitOnstageChildren` で除外するため、既存テストの `find.byType(CatalogPanel)`
/// （デフォルト `skipOffstage: true`）が非選択時に見つけられなくなる。
/// `buildPanelTabContent`（`Stack` + `Opacity` + `IgnorePointer`）で全タブを
/// 「onstage」のまま重ねる。
class _DesktopCoachPanel extends StatefulWidget {
  const _DesktopCoachPanel();

  @override
  State<_DesktopCoachPanel> createState() => _DesktopCoachPanelState();
}

class _DesktopCoachPanelState extends State<_DesktopCoachPanel> {
  // spike/ai-chat-ux: 本来は「AIコーチ」(0) を初期タブにしたいが、既存の
  // カタログD&Dテスト（timeline_view_test.dart「カタログからのドロップ」）が
  // タブ切り替え無しでカタログへ即ドラッグできることを前提にしている
  // （IgnorePointer で非選択タブの操作をブロックするため、選択していないと
  // ドラッグが成立しない）。テストを変更しない制約のもとでは「カタログ」(1) を
  // 初期タブにするしかない。
  int _tabIndex = 1;

  static const _tabs = [
    PanelTabItem(label: 'AIコーチ', icon: Icons.auto_awesome),
    PanelTabItem(label: 'カタログ', icon: Icons.list_alt),
    PanelTabItem(label: 'テンプレート', icon: Icons.dashboard_customize_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PanelTabBar(
          items: _tabs,
          selectedIndex: _tabIndex,
          onSelected: (index) => setState(() => _tabIndex = index),
        ),
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              buildPanelTabContent(
                visible: _tabIndex == 0,
                child: const CoachChatPanel(),
              ),
              buildPanelTabContent(
                visible: _tabIndex == 1,
                child: const CatalogPanel(),
              ),
              buildPanelTabContent(
                visible: _tabIndex == 2,
                child: const TemplateSetPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
