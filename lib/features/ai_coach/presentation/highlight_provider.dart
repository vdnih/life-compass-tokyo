import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../timeline/domain/year_month.dart';

/// spike/ai-chat-ux: チャットがタイムラインを書き換えた直後に
/// 「どこが変わったか」を示すためのハイライト状態。
///
/// [TimelineView] はこれを watch してイベントカードにリングを描画し、
/// 併せて [focusYearMonth] へ自動スクロールする。
@immutable
class ChatHighlight {
  /// ハイライト対象のイベントID
  final Set<String> eventIds;

  /// スクロール先の年月。null の場合はスクロールしない
  final YearMonth? focusYearMonth;

  const ChatHighlight({this.eventIds = const {}, this.focusYearMonth});
}

class ChatHighlightNotifier extends Notifier<ChatHighlight> {
  @override
  ChatHighlight build() => const ChatHighlight();

  /// [eventIds] をハイライトし、[focus] へスクロールを促す
  void show(Set<String> eventIds, YearMonth focus) {
    state = ChatHighlight(eventIds: eventIds, focusYearMonth: focus);
  }

  /// ハイライトのみ解除する（スクロール先の再トリガーはしない）
  void clear() {
    state = ChatHighlight(focusYearMonth: state.focusYearMonth);
  }
}

final chatHighlightProvider =
    NotifierProvider<ChatHighlightNotifier, ChatHighlight>(
      ChatHighlightNotifier.new,
    );
