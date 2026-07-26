import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/logic/auth_provider.dart';
import '../domain/life_event.dart';
import 'firestore_event_repository.dart';

/// イベントの永続化を担うリポジトリインターフェース
abstract class EventRepository {
  /// 全イベントを取得する
  Future<List<LifeEvent>> fetchEvents();

  /// イベントを保存する
  Future<void> saveEvent(LifeEvent event);

  /// イベントを削除する
  Future<void> deleteEvent(LifeEvent event);

  /// 既存のイベントを更新する（id で対象を特定する）
  Future<void> updateEvent(LifeEvent event);
}

/// インメモリ実装の [EventRepository]（MVP用）
class InMemoryEventRepository implements EventRepository {
  final List<LifeEvent> _events = [
    const LifeEvent(
      id: 'event-1',
      date: '2020-04',
      title: 'メーカーに入社',
      description: '新卒で消費財メーカーのマーケティング部門へ',
      catalogId: 'joining-company',
      status: EventStatus.recorded,
    ),
    const LifeEvent(
      id: 'event-2',
      date: '2022-09',
      title: '資格取得',
      description: 'Webマーケティング検定を取得',
      catalogId: 'obtain-certification',
      status: EventStatus.recorded,
    ),
    const LifeEvent(
      id: 'event-3',
      date: '2023-06',
      title: 'スタートアップへ転職',
      description: 'D2C事業を立ち上げるスタートアップにマーケターとして参画',
      catalogId: 'job-change',
      status: EventStatus.recorded,
    ),
    const LifeEvent(
      id: 'event-4',
      date: '2024-11',
      title: '入籍',
      description: 'パートナーと入籍・新生活スタート',
      catalogId: 'marriage-registration',
      status: EventStatus.recorded,
    ),
    const LifeEvent(
      id: 'event-5',
      date: '2026-06',
      title: '第一子誕生（目標）',
      description: '出産を目標に設定しライフプランを描く',
      catalogId: 'childbirth',
      status: EventStatus.goal,
    ),
    const LifeEvent(
      id: 'event-6',
      date: '2026-04',
      endDate: '2026-06',
      title: '産休',
      description: '出産2ヶ月前から産前休業開始',
      catalogId: 'maternity-leave',
      status: EventStatus.planned,
    ),
    const LifeEvent(
      id: 'event-7',
      date: '2026-06',
      endDate: '2027-06',
      title: '育休',
      description: '育児休業取得・子育て中心の1年',
      catalogId: 'childcare-leave',
      status: EventStatus.planned,
    ),
    const LifeEvent(
      id: 'event-8',
      date: '2027-06',
      title: '復職',
      description: 'マーケター職として職場復帰',
      catalogId: 'return-to-work',
      status: EventStatus.planned,
    ),
  ];

  @override
  Future<List<LifeEvent>> fetchEvents() async => List.unmodifiable(_events);

  @override
  Future<void> saveEvent(LifeEvent event) async {
    _events.add(event);
  }

  @override
  Future<void> deleteEvent(LifeEvent event) async {
    // id 基準。値等価（_events.remove）で消すと、編集済みの古いインスタンスを
    // 渡されたとき無言で失敗する（依存だけ消えてイベントが残るデータ不整合になる）。
    _events.removeWhere((e) => e.id == event.id);
  }

  @override
  Future<void> updateEvent(LifeEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
  }
}

/// [EventRepository] を提供するProvider
///
/// 認証済みの場合は Firestore 実装、未認証（ゲストモード）の場合は
/// サンプルデータ入りのインメモリ実装を返す。
/// authStateProvider の変更により自動的に再構築される。
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final user = userAsync.valueOrNull;
  if (user != null) {
    return FirestoreEventRepository(userId: user.uid);
  }
  return InMemoryEventRepository();
});
