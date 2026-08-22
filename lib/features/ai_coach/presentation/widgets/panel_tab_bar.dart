import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// [PanelTabBar] の1タブ分の見た目情報。
class PanelTabItem {
  final String label;
  final IconData icon;

  const PanelTabItem({required this.label, required this.icon});
}

/// デスクトップ左パネル・モバイルのボトムシートで共用するタブ切り替えバー。
///
/// `_DesktopCoachPanel`（`timeline_screen.dart`）と `CoachChatSheet`
/// （`coach_chat_sheet.dart`）の両方が「チャット/カタログ/テンプレート」の
/// 同じ見た目のタブを必要とするため切り出した。
class PanelTabBar extends StatelessWidget {
  final List<PanelTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const PanelTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(child: _buildTabButton(items[i], i)),
        ],
      ),
    );
  }

  Widget _buildTabButton(PanelTabItem item, int index) {
    final selected = selectedIndex == index;
    return InkWell(
      onTap: () => onSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 16,
              color: selected ? AppTheme.primary : Colors.grey.shade500,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.primary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 常時マウントしたまま表示だけ切り替えるタブコンテンツのラッパー。
///
/// `IndexedStack` は非選択タブの子を `debugVisitOnstageChildren` で除外するため、
/// `find.byType(CatalogPanel)`（デフォルト `skipOffstage: true`）を使う既存の
/// D&D テストが非選択時に見つけられなくなる。`Positioned.fill` + `IgnorePointer` +
/// `Opacity` で両方を「onstage」のまま重ねることでこれを避ける。
Widget buildPanelTabContent({required bool visible, required Widget child}) {
  return Positioned.fill(
    child: IgnorePointer(
      ignoring: !visible,
      child: Opacity(opacity: visible ? 1 : 0, child: child),
    ),
  );
}
