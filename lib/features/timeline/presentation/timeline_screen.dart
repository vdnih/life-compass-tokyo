import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../user_profile/user_profile.dart';
import '../../user_profile/profile_settings_dialog.dart';
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileNotifierProvider);
    final ageText = profile.age != null ? '${profile.age}歳' : '';
    final eventsAsync = ref.watch(timelineEventsProvider);
    final constraints = ref.watch(constraintCheckerProvider);

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
              ageText.isNotEmpty ? '${profile.name}  $ageText' : profile.name,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
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
          // 目標設定ボタン
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: '目標設定',
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const GoalSetupDialog(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person_outline, color: Colors.white, size: 18),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ProfileSettingsDialog(),
                );
              },
            ),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) => _viewMode == TimelineViewMode.yearMonth
            ? YearMonthTimeline(events: events, constraints: constraints)
            : YearTimeline(events: events, constraints: constraints),
        loading: () => Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'エラーが発生しました: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddEventDialog(),
          );
        },
        tooltip: 'イベントを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
