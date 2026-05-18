import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../catalog/domain/predefined_life_event.dart';
import '../data/event_repository.dart';
import '../domain/life_event.dart';

const _uuid = Uuid();

/// マイルストーンの日付を計算するヘルパー
///
/// parentDate（yyyy-MM）に offsetMonths を加算した yyyy-MM 文字列を返す。
String _addMonths(String parentDate, int offsetMonths) {
  final parts = parentDate.split('-');
  int year = int.parse(parts[0]);
  int month = int.parse(parts[1]) + offsetMonths;
  while (month > 12) {
    year++;
    month -= 12;
  }
  while (month < 1) {
    year--;
    month += 12;
  }
  return '$year-${month.toString().padLeft(2, '0')}';
}

/// タイムラインイベントの状態を管理するNotifier
class TimelineEventsNotifier extends AsyncNotifier<List<LifeEvent>> {
  @override
  Future<List<LifeEvent>> build() async {
    // ref.watch により authStateProvider 変化時（ログイン/ログアウト）に
    // build() が自動再実行され、正しいリポジトリからイベントを取得し直す。
    final repository = ref.watch(eventRepositoryProvider);
    return repository.fetchEvents();
  }

  /// 新しいイベントをリストに追加する
  Future<void> addEvent(LifeEvent event) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.saveEvent(event);
      final events = await repository.fetchEvents();
      state = AsyncData(events);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// カタログからイベントをドロップ追加する
  ///
  /// 親イベント（kind: event）を生成し、catalog.milestoneTemplates が空でない場合は
  /// 各テンプレートから子マイルストーン（kind: milestone）を自動生成して同時に追加する。
  ///
  /// - [catalog]: ドロップされたカタログ定義
  /// - [date]: 親イベントの開始日（yyyy-MM）
  Future<void> addEventFromCatalog(
    PredefinedLifeEvent catalog,
    String date,
  ) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repository = ref.read(eventRepositoryProvider);

      // 親イベントを生成
      final parentId = _uuid.v4();
      final parentEvent = LifeEvent(
        id: parentId,
        catalogId: catalog.id,
        kind: EventKind.event,
        date: date,
        endDate: catalog.defaultDurationMonths != null
            ? _addMonths(date, catalog.defaultDurationMonths!)
            : null,
        title: catalog.label,
        description: '',
        status: EventStatus.planned,
        budgetYen: catalog.defaultBudgetYen,
      );
      await repository.saveEvent(parentEvent);

      // マイルストーンを自動生成
      for (final template in catalog.milestoneTemplates) {
        final milestoneDate =
            _addMonths(date, template.offsetMonthsFromParent);
        final milestone = LifeEvent(
          id: _uuid.v4(),
          catalogId: catalog.id,
          parentEventId: parentId,
          kind: EventKind.milestone,
          date: milestoneDate,
          title: template.label,
          description: '',
          status: EventStatus.planned,
          budgetYen: template.defaultBudgetYen,
        );
        await repository.saveEvent(milestone);
      }

      final events = await repository.fetchEvents();
      state = AsyncData(events);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// 既存のイベントを削除する
  Future<void> deleteEvent(LifeEvent event) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.deleteEvent(event);
      final events = await repository.fetchEvents();
      state = AsyncData(events);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// 既存のイベントを更新する（編集に使用）
  Future<void> updateEvent(LifeEvent event) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.updateEvent(event);
      final events = await repository.fetchEvents();
      state = AsyncData(events);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }

  /// 指定したIDのイベントの日付を更新する（D&D移動に使用）
  Future<void> moveEvent(String eventId, String newDate,
      {String? newEndDate}) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final repository = ref.read(eventRepositoryProvider);
      final events = await repository.fetchEvents();
      final target = events.firstWhere((e) => e.id == eventId);
      final updated = newEndDate != null
          ? target.copyWith(date: newDate, endDate: newEndDate)
          : target.copyWith(date: newDate);
      await repository.updateEvent(updated);
      final updatedEvents = await repository.fetchEvents();
      state = AsyncData(updatedEvents);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      if (previousState.hasValue) {
        state = previousState;
      }
    }
  }
}

/// タイムラインイベントの状態を提供するProvider
final timelineEventsProvider =
    AsyncNotifierProvider<TimelineEventsNotifier, List<LifeEvent>>(() {
  return TimelineEventsNotifier();
});
