import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/logic/auth_provider.dart';
import '../../auth/presentation/sign_in_dialog.dart';
import 'chat_controller.dart';

/// spike/ai-chat-ux: メッセージ一覧 + 入力欄。
///
/// デスクトップの左パネルタブ、モバイルのボトムシート両方から共用する。
/// [scrollController] を渡すと `DraggableScrollableSheet` のビルダーが提供する
/// コントローラをメッセージリストに使い、シートのドラッグと一体化させる。
class CoachChatPanel extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  /// 送信を開始した直後（応答を待たず）に呼ばれる。
  /// モバイルのボトムシートはこれをきっかけに自動で縮む。
  final VoidCallback? onSent;

  const CoachChatPanel({super.key, this.scrollController, this.onSent});

  @override
  ConsumerState<CoachChatPanel> createState() => _CoachChatPanelState();
}

class _CoachChatPanelState extends ConsumerState<CoachChatPanel> {
  final _textController = TextEditingController();
  ScrollController? _ownedScrollController;
  bool _isSending = false;

  ScrollController get _listScrollController =>
      widget.scrollController ??
      (_ownedScrollController ??= ScrollController());

  @override
  void dispose() {
    _textController.dispose();
    _ownedScrollController?.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text;
    if (text.trim().isEmpty || _isSending) return;

    // 手動でのイベント配置とは非対称にあえてログイン必須にする。
    // 手動配置はコストがかからず「試せる」ことに価値があるためゲストに開放したが
    // （#74）、AI呼び出しは Gemini API のコストが発生するため、
    // 無制限に使われては困る。
    //
    // authPendingProvider を先に見るのは、authStateProvider.value == null が
    // 「未認証」と「未解決（AsyncLoading）」の両方を意味するため（ADR-020）。
    // 未解決の間に判定すると、ログイン済みユーザーにも初回フレームで
    // サインインダイアログが出てしまう。
    if (ref.read(authPendingProvider)) return;
    if (ref.read(authStateProvider).value == null) {
      showDialog<void>(context: context, builder: (_) => const SignInDialog());
      return;
    }

    _textController.clear();
    widget.onSent?.call();
    setState(() => _isSending = true);

    final result = await ref.read(chatControllerProvider.notifier).send(text);

    if (!mounted) return;
    setState(() => _isSending = false);
    _scrollToBottom();

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.addedCount}件追加しました'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: () =>
                ref.read(chatControllerProvider.notifier).undoLast(result),
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listScrollController.hasClients) return;
      _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);

    return Material(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _listScrollController,
              padding: const EdgeInsets.all(12),
              itemCount: state.messages.length,
              itemBuilder: (context, index) =>
                  _MessageBubble(message: state.messages[index]),
            ),
          ),
          _buildInputRow(),
        ],
      ),
    );
  }

  // spike/ai-chat-ux: モバイルのボトムシート折りたたみ時（入力欄1行 ≒ 64px）に
  // 収まる必要があるため、IconButton のデフォルト最小タップ領域（48x48）を明示的に
  // 縮める。これを外すと折りたたみ高さでオーバーフローする。
  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '「子どもがほしい」など',
                hintStyle: TextStyle(fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          IconButton(
            tooltip: '送信',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: AppTheme.primary, size: 20),
            onPressed: _isSending ? null : _handleSend,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
