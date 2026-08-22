import 'package:flutter/material.dart';
import '../../catalog/presentation/catalog_panel.dart';
import '../../timeline/presentation/widgets/template_set_panel.dart';
import 'coach_chat_panel.dart';
import 'widgets/panel_tab_bar.dart';

/// spike/ai-chat-ux: モバイル用ボトムシート型の「チャット / カタログ / テンプレート」。
///
/// - 折りたたみ時（[_collapsedSize]）: ハンドル + タブ行のみ。タイムラインがほぼ全画面
/// - 送信直後（[_sentSize]）: 自動的にここまで縮み、タイムラインの変化を見せる
/// - 展開時（[_expandedSize]）: 会話履歴・カタログ・テンプレート一覧が読める高さ
///
/// Google マップのボトムシートに倣う。PDR-006 の Split-View はスマホ幅では
/// 両方読めなくなるため採らない（詳細は実装計画・spike PR 説明を参照）。
///
/// デスクトップの `_DesktopCoachPanel`（`timeline_screen.dart`）と対称の3タブ構成。
class CoachChatSheet extends StatefulWidget {
  /// ドラッグでリサイズできるハンドル行の [Key]（テストが座標推定ではなく
  /// キー経由で参照するため）。
  static const dragHandleKey = Key('coach-chat-sheet-drag-handle');

  /// 折りたたみ時のシート高さ（body 高さに対する分数）。
  ///
  /// `timeline_screen.dart` のモバイル分岐が、この折りたたみ状態のシートに
  /// タイムライン本体・FABが隠れないよう底上げする padding を計算するのに使う
  /// （両者が食い違うとシートが FAB を覆ってタップできなくなる）。
  static const double collapsedSizeFraction = 0.20;

  const CoachChatSheet({super.key});

  @override
  State<CoachChatSheet> createState() => _CoachChatSheetState();
}

class _CoachChatSheetState extends State<CoachChatSheet> {
  static const double _collapsedSize = CoachChatSheet.collapsedSizeFraction;
  static const double _sentSize = 0.30;
  static const double _expandedSize = 0.60;

  final _sheetController = DraggableScrollableController();

  int _tabIndex = 0;

  static const _tabs = [
    PanelTabItem(label: 'チャット', icon: Icons.auto_awesome),
    PanelTabItem(label: 'カタログ', icon: Icons.list_alt),
    PanelTabItem(label: 'テンプレート', icon: Icons.dashboard_customize_outlined),
  ];

  /// ハンドルドラッグ開始時点のシートサイズ（分数）。
  double? _dragStartSize;

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

  // ---- ハンドルドラッグでの高さ変更 ----
  //
  // DraggableScrollableSheet はビルダーが返すツリーの中で「実際にアタッチされた
  // ScrollController を持つスクロール可能ウィジェット」からしかリサイズ操作を
  // 受け取らない。ハンドル（見た目上の 36x4 のピル）自体にはジェスチャ処理が
  // 無く、リサイズできるのは CoachChatPanel 内の ListView だけだった
  // （かつ折りたたみ時は帯が数十pxしか無くほぼ操作不能）。
  // ここではハンドル行に GestureDetector を追加し、DraggableScrollableController
  // を直接操作することで、タブ行がある状態でも常に高さを変えられるようにする。

  void _handleDragStart(DragStartDetails details) {
    if (!_sheetController.isAttached) return;
    _dragStartSize = _sheetController.size;
  }

  void _handleDragUpdate(DragUpdateDetails details, double viewportHeight) {
    final startSize = _dragStartSize;
    if (startSize == null || !_sheetController.isAttached) return;
    if (viewportHeight <= 0) return;
    final deltaFraction = -details.primaryDelta! / viewportHeight;
    final newSize = (_sheetController.size + deltaFraction).clamp(
      _collapsedSize,
      _expandedSize,
    );
    _sheetController.jumpTo(newSize);
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragStartSize = null;
    if (!_sheetController.isAttached) return;
    const anchors = [_collapsedSize, _sentSize, _expandedSize];
    final current = _sheetController.size;
    final nearest = anchors.reduce(
      (a, b) => (current - a).abs() <= (current - b).abs() ? a : b,
    );
    _sheetController.animateTo(
      nearest,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;

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
              GestureDetector(
                key: CoachChatSheet.dragHandleKey,
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _handleDragStart,
                onVerticalDragUpdate: (details) =>
                    _handleDragUpdate(details, viewportHeight),
                onVerticalDragEnd: _handleDragEnd,
                child: SizedBox(
                  height: 24,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              PanelTabBar(
                items: _tabs,
                selectedIndex: _tabIndex,
                onSelected: (index) => setState(() => _tabIndex = index),
              ),
              const Divider(height: 1),
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    CoachChatPanel(
                      scrollController: scrollController,
                      onSent: _shrinkAfterSend,
                    ),
                    const CatalogPanel(),
                    const TemplateSetPanel(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
