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

  /// 直近の展開結果（Undo 用に保持。展開していない/Undo 済みなら null）
  final GoalExpansionResult? lastExpansion;

  const ChatState({this.messages = const [], this.lastExpansion});
}

/// チャット送信1回の結果。UI 側がスナックバーを出すために使う
@immutable
class ChatSendResult {
  final int addedCount;

  const ChatSendResult({required this.addedCount});
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
      lastExpansion: state.lastExpansion,
    );

    final reply = ScriptedCoach.reply(trimmed);
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(text: reply.responseText, isUser: false),
      ],
      lastExpansion: state.lastExpansion,
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

    state = ChatState(messages: state.messages, lastExpansion: result);

    ref
        .read(chatHighlightProvider.notifier)
        .show(result.generatedEvents.map((e) => e.id).toSet(), goalYearMonth);

    return ChatSendResult(addedCount: result.generatedEvents.length);
  }

  /// 直近の展開を取り消す（生成イベント・依存関係を削除）
  Future<void> undoLast() async {
    final expansion = state.lastExpansion;
    if (expansion == null) return;

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
      lastExpansion: null,
    );
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
