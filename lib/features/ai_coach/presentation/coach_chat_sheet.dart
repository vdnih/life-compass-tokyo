import 'package:flutter/material.dart';
import 'coach_chat_panel.dart';

/// spike/ai-chat-ux: モバイル用ボトムシート型チャット。
///
/// - 折りたたみ時（[_collapsedSize]）: 入力欄1行のみ。タイムラインがほぼ全画面
/// - 送信直後（[_sentSize]）: 自動的にここまで縮み、タイムラインの変化を見せる
/// - 展開時（[_expandedSize]）: 会話履歴が読める高さ
///
/// Google マップのボトムシートに倣う。PDR-006 の Split-View はスマホ幅では
/// 両方読めなくなるため採らない（詳細は実装計画・spike PR 説明を参照）。
class CoachChatSheet extends StatefulWidget {
  const CoachChatSheet({super.key});

  @override
  State<CoachChatSheet> createState() => _CoachChatSheetState();
}

class _CoachChatSheetState extends State<CoachChatSheet> {
  static const double _collapsedSize = 0.12;
  static const double _sentSize = 0.30;
  static const double _expandedSize = 0.60;

  final _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  /// 送信直後にシートを縮める。「AI がタイムラインを書き換える瞬間」を見せるため、
  /// 応答を待たずに縮める（[CoachChatPanel.onSent] から呼ばれる）。
  void _shrinkAfterSend() {
    if (!_sheetController.isAttached) return;
    _sheetController.animateTo(
      _sentSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _collapsedSize,
      minChildSize: _collapsedSize,
      maxChildSize: _expandedSize,
      snap: true,
      snapSizes: const [_collapsedSize, _sentSize],
      builder: (context, scrollController) {
        return Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CoachChatPanel(
                  scrollController: scrollController,
                  onSent: _shrinkAfterSend,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
