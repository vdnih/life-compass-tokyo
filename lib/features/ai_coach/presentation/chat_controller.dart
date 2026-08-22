import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../timeline/domain/year_month.dart';
import '../../timeline/logic/dependency_provider.dart';
import '../../timeline/logic/goal_template_provider.dart';
import '../../timeline/logic/timeline_events_provider.dart';
import 'highlight_provider.dart';
import 'scripted_coach.dart';

/// spike/ai-chat-ux: チャットの1メッセージ
@immutable
class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}

/// spike/ai-chat-ux: チャットの状態
@immutable
class ChatState {
  final List<ChatMessage> messages;

  const ChatState({this.messages = const []});
}

/// チャット送信1回の結果。UI 側がスナックバーを出す・Undo するために使う。
///
/// [expansion] はこの送信で生成された展開結果そのものを持つ（Notifier 側の
/// 「直近の」共有状態を参照しない）。連続送信で2件目のスナックバーがまだ
/// 表示されている間に1件目の Undo を押しても、1件目自身の展開を正しく
/// 取り消せるようにするため。
@immutable
class ChatSendResult {
  final int addedCount;
  final GoalExpansionResult expansion;

  const ChatSendResult({required this.addedCount, required this.expansion});
}

/// spike/ai-chat-ux: 固定応答チャットのコントローラ
///
/// AI は呼ばない。[ScriptedCoach] のキーワード一致結果に従って
/// 既存の [goalTemplateProvider] / [timelineEventsProvider] /
/// [dependencyProvider] を叩くだけで、新規ドメインロジックは持たない。
class ChatController extends Notifier<ChatState> {
  static const _welcomeMessage = ChatMessage(
    isUser: false,
    text:
        '「子どもがほしい」「そろそろ転職したい」のように話しかけてみてください。'
        '今はまだ AI とは接続しておらず、決まったキーワードにだけ反応する試作です。',
  );

  @override
  ChatState build() => const ChatState(messages: [_welcomeMessage]);

  /// メッセージを送信し、該当キーワードがあればテンプレートを展開する
  Future<ChatSendResult?> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(text: trimmed, isUser: true),
      ],
    );

    final reply = ScriptedCoach.reply(trimmed);
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(text: reply.responseText, isUser: false),
      ],
    );

    final templateId = reply.templateId;
    if (templateId == null) return null;

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

    ref
        .read(chatHighlightProvider.notifier)
        .show(result.generatedEvents.map((e) => e.id).toSet(), goalYearMonth);

    return ChatSendResult(
      addedCount: result.generatedEvents.length,
      expansion: result,
    );
  }

  /// [expansion] の展開を取り消す（生成イベント・依存関係を削除）。
  ///
  /// 呼び出し元（スナックバーの「元に戻す」）はその送信自身が返した
  /// [ChatSendResult.expansion] を渡す。Notifier 側で「直近の」展開を
  /// 共有状態として持たないのは、連続送信時に別の送信の結果を誤って
  /// 取り消さないようにするため。
  Future<void> undoLast(GoalExpansionResult expansion) async {
    for (final dep in expansion.generatedDependencies) {
      await ref.read(dependencyProvider.notifier).removeDependency(dep.id);
    }
    for (final event in expansion.generatedEvents) {
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
