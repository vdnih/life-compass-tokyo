import 'package:flutter/material.dart';
import '../../data/goal_template_data.dart';
import '../../domain/goal_template.dart';
import '../../logic/goal_template_provider.dart';
import 'event_style.dart';

/// イベントセット（旧「目標を設定」機能）のドラッグ元一覧パネル。
///
/// 「ゴール日を入力して逆算プレビュー」というモーダルフローは使いづらいという
/// フィードバックを受け、[CatalogPanel] の単発イベントと同じ操作感
/// （[LongPressDraggable] でタイムラインへ直接ドロップ）に作り替えたもの。
/// ドロップした月がテンプレートの「ゴール日」として扱われ、関連イベント一式が
/// 確認モーダル無しで即座に生成される（ドロップ処理は
/// `timeline_view.dart` の `_buildDropTarget` 内 `data is GoalTemplate` 分岐）。
///
/// 逆算の計算エンジン自体（[GoalTemplateRegistry] のデータ、
/// [GoalTemplateNotifier.applyTemplate]）は変更していない。
class TemplateSetPanel extends StatelessWidget {
  const TemplateSetPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: GoalTemplateRegistry.templates.length,
        itemBuilder: (context, index) {
          return _TemplateSetTile(
            template: GoalTemplateRegistry.templates[index],
          );
        },
      ),
    );
  }
}

/// ドラッグ可能なテンプレート（イベントセット）タイル
///
/// カタログの単発イベントと違い、タップでの単体プレビュー（[AddEventDialog] 相当）は
/// 持たない。ドラッグしてタイムラインへドロップすることでのみ適用される。
class _TemplateSetTile extends StatelessWidget {
  final GoalTemplate template;

  const _TemplateSetTile({required this.template});

  int get _eventCount => template.relatedEvents.length + 1;

  @override
  Widget build(BuildContext context) {
    final color = catalogColor(template.goalCatalogId);
    final icon = catalogIcon(template.goalCatalogId);

    return Listener(
      onPointerPanZoomStart: (_) {},
      child: LongPressDraggable<GoalTemplate>(
        data: template,
        delay: const Duration(milliseconds: 400),
        // catalog_panel.dart の _CatalogItemTile と同じ理由でポインタ基準にする。
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: Transform.scale(
              scale: 0.85,
              child: _buildCard(color: color, icon: icon, opacity: 1.0),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.4,
          child: _buildRow(color: color, icon: icon),
        ),
        child: _buildRow(color: color, icon: icon),
      ),
    );
  }

  Widget _buildRow({required Color color, required IconData icon}) {
    // 背景色を明示して行全体を不透明にする（LongPressDraggable は
    // HitTestBehavior.deferToChild のため、Row の余白部分が不透明でないと
    // 長押しがそこで何もヒットせずタイムライン側に抜けてしまう。実際に
    // Column(crossAxisAlignment: start) だけだと Text の実測幅しか
    // ヒットテスト対象にならず、行の大半でドラッグが始まらなかった）。
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  template.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  template.description,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$_eventCount件',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Color color,
    required IconData icon,
    required double opacity,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${template.name}（$_eventCount件）',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
