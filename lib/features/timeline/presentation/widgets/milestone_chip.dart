import 'package:flutter/material.dart';
import '../../domain/life_event.dart';

/// 親イベントの直下に表示するマイルストーンチップ
///
/// `kind == EventKind.milestone` のイベントを小さなチップとして表示する。
/// タップで削除確認ダイアログを表示する。
class MilestoneChip extends StatelessWidget {
  /// 表示するマイルストーンイベント
  final LifeEvent milestone;

  /// 親イベントのカラー（背景色に使用）
  final Color parentColor;

  /// 削除確認後に呼ばれるコールバック
  final VoidCallback onDelete;

  const MilestoneChip({
    super.key,
    required this.milestone,
    required this.parentColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDeleteConfirmation(context),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: parentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: parentColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          milestone.title,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: parentColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('マイルストーンを削除'),
        content: Text('"${milestone.title}" を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
