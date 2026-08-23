import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/data/predefined_catalog_registry.dart';
import '../../timeline/data/goal_template_data.dart';
import '../../timeline/domain/event_dependency.dart';
import '../../timeline/domain/life_event.dart';
import '../../timeline/domain/year_month.dart';
import '../../timeline/logic/dependency_provider.dart';
import '../../timeline/logic/goal_template_provider.dart';
import '../../timeline/logic/timeline_events_provider.dart';
import '../data/gemini_coach_repository.dart';
import '../logic/coach_tools.dart';
import 'highlight_provider.dart';
import 'scripted_coach.dart';

/// チャットの1メッセージ
@immutable
class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}

/// チャットの状態
@immutable
class ChatState {
  final List<ChatMessage> messages;

  const ChatState({this.messages = const []});
}

/// チャット送信1回の結果。UI 側がスナックバーを出す・Undo するために使う。
///
/// [addedEvents] / [addedDependencies] はこの送信自身が生成した分だけを持つ
/// （Notifier 側の「直近の」共有状態を参照しない）。連続送信で2件目の
/// スナックバーがまだ表示されている間に1件目の Undo を押しても、1件目自身の
/// 追加分だけを正しく取り消せるようにするため。
@immutable
class ChatSendResult {
  final List<LifeEvent> addedEvents;
  final List<EventDependency> addedDependencies;

  const ChatSendResult({
    this.addedEvents = const [],
    this.addedDependencies = const [],
  });

  int get addedCount => addedEvents.length;
}

/// AI コーチのチャットコントローラ
///
/// [GeminiCoachRepository]（Gemini + Function Calling）に送信し、
/// 展開されたアクションに応じて既存の [goalTemplateProvider] /
/// [timelineEventsProvider] / [dependencyProvider] を叩く。新規ドメイン
/// ロジックは持たない。AI 呼び出しが失敗した場合は [ScriptedCoach] の
/// 固定応答にフォールバックする（デモ URL が審査期間中に沈黙しないため）。
class ChatController extends Notifier<ChatState> {
  static const _welcomeMessage = ChatMessage(
    isUser: false,
    text:
        '「子どもがほしい」「そろそろ転職したい」のように話しかけてみてください。'
        '育休や産後ケアなど、制度上どこまで選べるかもお答えできます。',
  );

  @override
  ChatState build() => const ChatState(messages: [_welcomeMessage]);

  /// メッセージを送信し、AI が展開したアクションをタイムラインに反映する
  Future<ChatSendResult?> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(text: trimmed, isUser: true),
      ],
    );

    final addedEvents = <LifeEvent>[];
    final addedDependencies = <EventDependency>[];

    String responseText;
    try {
      final repository = ref.read(coachRepositoryProvider);
      final turn = await repository.send(
        trimmed,
        executeTool: (name, args) => _executeTool(
          name,
          args,
          addedEvents: addedEvents,
          addedDependencies: addedDependencies,
        ),
      );
      responseText = turn.responseText;
    } catch (e) {
      // AI 呼び出しの失敗（ネットワーク・API 側の障害など）でチャットが
      // 完全に沈黙しないよう、固定応答にフォールバックする。
      final reply = ScriptedCoach.reply(trimmed);
      responseText =
          '${reply.responseText}\n\n（現在AIとの接続が不安定なため、簡易応答です）';

      final templateId = reply.templateId;
      if (templateId != null) {
        final goalYearMonth = YearMonth.fromDateTime(
          DateTime.now(),
        ).addMonths(reply.goalMonthsFromNow);
        final result = await ref
            .read(goalTemplateProvider.notifier)
            .applyTemplate(
              templateId: templateId,
              goalDate: goalYearMonth.toString(),
              goalTitle: reply.goalTitle,
            );
        addedEvents.addAll(result.generatedEvents);
        addedDependencies.addAll(result.generatedDependencies);
      }
    }

    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(text: responseText, isUser: false),
      ],
    );

    if (addedEvents.isEmpty) return null;

    // `_executeTool` が年月を検証済みのため通常は例外にならないが、呼び出し元
    // （`coach_chat_panel.dart`）に try/catch が無く、ここで例外を投げると
    // 送信ボタンが固まったままになる。ハイライトは副次的な演出のため、
    // 失敗しても送信結果自体は返す。
    try {
      final focus = YearMonth.parse(addedEvents.first.date);
      ref
          .read(chatHighlightProvider.notifier)
          .show(addedEvents.map((e) => e.id).toSet(), focus);
    } on FormatException {
      // ハイライト演出のみ諦める。
    }

    return ChatSendResult(
      addedEvents: addedEvents,
      addedDependencies: addedDependencies,
    );
  }

  /// Function Calling 1件を実行し、Gemini に返す Function Response を返す。
  ///
  /// [addedEvents] / [addedDependencies] は呼び出し元の `send()` が
  /// このメッセージ全体を通じて共有する集計先。
  Future<Map<String, Object?>> _executeTool(
    String name,
    Map<String, Object?> args, {
    required List<LifeEvent> addedEvents,
    required List<EventDependency> addedDependencies,
  }) async {
    switch (name) {
      case 'applyGoalTemplate':
        final templateId = args['templateId'] as String;
        final templateExists = GoalTemplateRegistry.templates.any(
          (t) => t.id == templateId,
        );
        if (!templateExists) {
          return {'status': 'error', 'message': '不明なテンプレートIDです: $templateId'};
        }
        final goalYearMonth = args['goalYearMonth'] as String;
        if (!_isValidYearMonth(goalYearMonth)) {
          return {
            'status': 'error',
            'message': 'goalYearMonth は yyyy-MM 形式で指定してください: $goalYearMonth',
          };
        }

        final result = await ref
            .read(goalTemplateProvider.notifier)
            .applyTemplate(
              templateId: templateId,
              goalDate: goalYearMonth,
              goalTitle: args['goalTitle'] as String,
            );
        addedEvents.addAll(result.generatedEvents);
        addedDependencies.addAll(result.generatedDependencies);
        return {
          'status': 'ok',
          'addedEventCount': result.generatedEvents.length,
        };

      case 'addEventFromCatalog':
        final catalogId = args['catalogId'] as String;
        final catalog = PredefinedCatalogRegistry.findById(catalogId);
        if (catalog == null) {
          return {'status': 'error', 'message': '不明なカタログIDです: $catalogId'};
        }
        final yearMonth = args['yearMonth'] as String;
        if (!_isValidYearMonth(yearMonth)) {
          return {
            'status': 'error',
            'message': 'yearMonth は yyyy-MM 形式で指定してください: $yearMonth',
          };
        }

        // build() が未解決（AsyncLoading）のまま before/after を比較すると
        // 追加分を取りこぼすため、先に解決を待つ。
        final beforeEvents = await ref.read(timelineEventsProvider.future);
        final beforeIds = beforeEvents.map((e) => e.id).toSet();
        await ref
            .read(timelineEventsProvider.notifier)
            .addEventFromCatalog(catalog, yearMonth);
        final after =
            ref.read(timelineEventsProvider).value ?? const <LifeEvent>[];
        final added = after.where((e) => !beforeIds.contains(e.id)).toList();
        if (added.isEmpty) {
          // TimelineEventsNotifier は書き込み失敗時に previousState へ
          // 静かに復元するため、ここで空を検知して Gemini に伝える
          // （そうしないと「追加しました」と誤って発話しうる）。
          return {'status': 'error', 'message': 'イベントの追加に失敗しました'};
        }
        addedEvents.addAll(added);
        return {'status': 'ok', 'addedEventCount': added.length};

      case 'getInstitutionalLimit':
        final catalogId = args['catalogId'] as String;
        final limits = institutionalLimitResponsesFor(catalogId);
        if (limits.isEmpty) {
          return {'found': false};
        }
        return {'found': true, 'limits': limits};

      default:
        return {'status': 'error', 'message': '未対応の関数です: $name'};
    }
  }

  /// [value] が `YearMonth.parse` で解釈できる `yyyy-MM` 形式か検証する。
  ///
  /// AI が生成した年月文字列は検証なしで [LifeEvent.date] に書き込まれうるため
  /// （`TimelineEventsNotifier.addEventFromCatalog` は `endDate` 計算時にしか
  /// パースしない）、実行前にここで弾く。素通しすると `send()` 末尾の
  /// `YearMonth.parse(addedEvents.first.date)` が捕捉されずに例外を投げ、
  /// 呼び出し元（`coach_chat_panel.dart`）に try/catch が無いため送信ボタンが
  /// 固まる。
  bool _isValidYearMonth(String value) {
    try {
      YearMonth.parse(value);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// [addedEvents] / [addedDependencies] の追加を取り消す。
  ///
  /// 呼び出し元（スナックバーの「元に戻す」）はその送信自身が返した
  /// [ChatSendResult] を渡す。Notifier 側で「直近の」追加を共有状態として
  /// 持たないのは、連続送信時に別の送信の結果を誤って取り消さないため。
  Future<void> undoLast(ChatSendResult result) async {
    for (final dep in result.addedDependencies) {
      await ref.read(dependencyProvider.notifier).removeDependency(dep.id);
    }
    for (final event in result.addedEvents) {
      await ref.read(timelineEventsProvider.notifier).deleteEvent(event);
    }

    ref.read(chatHighlightProvider.notifier).clear();

    state = ChatState(
      messages: [
        ...state.messages,
        const ChatMessage(text: '元に戻しました。', isUser: false),
      ],
    );
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
