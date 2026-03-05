import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user_profile/user_profile.dart';
import '../../user_profile/profile_settings_dialog.dart';
import '../logic/timeline_events_provider.dart';
import 'widgets/year_month_timeline.dart';
import 'widgets/year_timeline.dart';
import 'add_event_dialog.dart';

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
    final ageText = profile.age != null ? ' (${profile.age}歳)' : '';
    final eventsAsync = ref.watch(timelineEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${profile.name}$ageText'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<TimelineViewMode>(
              segments: const [
                ButtonSegment(
                  value: TimelineViewMode.yearMonth,
                  label: Text('年月'),
                  icon: Icon(Icons.calendar_view_month),
                ),
                ButtonSegment(
                  value: TimelineViewMode.year,
                  label: Text('年'),
                  icon: Icon(Icons.calendar_today),
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
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ProfileSettingsDialog(),
              );
            },
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) => _viewMode == TimelineViewMode.yearMonth
            ? YearMonthTimeline(events: events)
            : YearTimeline(events: events),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラーが発生しました: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddEventDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
