import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../catalog/domain/predefined_life_event.dart';

extension LifeEventGroupX on LifeEventGroup {
  IconData get icon {
    switch (this) {
      case LifeEventGroup.marriage:
        return Icons.favorite_border;
      case LifeEventGroup.childbirth:
        return Icons.child_care_outlined;
      case LifeEventGroup.career:
        return Icons.work_outline;
      case LifeEventGroup.lifestyle:
        return Icons.home_outlined;
      case LifeEventGroup.travel:
        return Icons.flight_outlined;
      case LifeEventGroup.learning:
        return Icons.school_outlined;
      case LifeEventGroup.money:
        return Icons.savings_outlined;
    }
  }
}

/// カタログアイテムを選択するピッカーフィールド。
///
/// タップすると検索付きグループ別BottomSheetが開く。
class CatalogPickerField extends StatelessWidget {
  final String selectedCatalogId;
  final List<PredefinedLifeEvent> availableItems;
  final ValueChanged<String> onChanged;

  const CatalogPickerField({
    super.key,
    required this.selectedCatalogId,
    required this.availableItems,
    required this.onChanged,
  });

  PredefinedLifeEvent get _selectedItem {
    final matches = availableItems.where((e) => e.id == selectedCatalogId);
    return matches.isEmpty ? availableItems.first : matches.first;
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CatalogPickerSheet(
        items: availableItems,
        selectedCatalogId: selectedCatalogId,
        onSelected: (id) {
          Navigator.pop(context);
          onChanged(id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _selectedItem;
    return InkWell(
      onTap: () => _openSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: item.color, width: 3),
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: item.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.group.label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}

class _CatalogPickerSheet extends StatefulWidget {
  final List<PredefinedLifeEvent> items;
  final String selectedCatalogId;
  final ValueChanged<String> onSelected;

  const _CatalogPickerSheet({
    required this.items,
    required this.selectedCatalogId,
    required this.onSelected,
  });

  @override
  State<_CatalogPickerSheet> createState() => _CatalogPickerSheetState();
}

class _CatalogPickerSheetState extends State<_CatalogPickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() {
        setState(() => _query = _searchController.text);
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PredefinedLifeEvent> get _filtered {
    if (_query.trim().isEmpty) return widget.items;
    final q = _query.trim().toLowerCase();
    return widget.items
        .where((e) =>
            e.label.toLowerCase().contains(q) ||
            e.group.label.contains(q))
        .toList();
  }

  Map<LifeEventGroup, List<PredefinedLifeEvent>> get _groupedFiltered {
    final result = <LifeEventGroup, List<PredefinedLifeEvent>>{};
    for (final group in LifeEventGroup.values) {
      final items = _filtered.where((e) => e.group == group).toList();
      if (items.isNotEmpty) result[group] = items;
    }
    return result;
  }

  PredefinedLifeEvent? get _currentItem {
    final matches = widget.items.where((e) => e.id == widget.selectedCatalogId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.65, 0.92],
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const _DragHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      const Text(
                        'カテゴリを選択',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.items.length}件',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '検索',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                              onPressed: _searchController.clear,
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  child: _query.trim().isNotEmpty
                      ? _buildFlatList(scrollController)
                      : _buildGroupedList(scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlatList(ScrollController sc) {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(
          '該当なし',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      );
    }
    return ListView.builder(
      controller: sc,
      itemCount: items.length,
      itemBuilder: (_, i) => _ItemRow(
        item: items[i],
        isSelected: widget.selectedCatalogId == items[i].id,
        onTap: () => widget.onSelected(items[i].id),
        showGroupLabel: true,
      ),
    );
  }

  Widget _buildGroupedList(ScrollController sc) {
    final grouped = _groupedFiltered;
    final currentItem = _currentItem;
    return ListView(
      controller: sc,
      children: grouped.entries.map((entry) {
        final group = entry.key;
        final items = entry.value;
        return ExpansionTile(
          key: PageStorageKey(group),
          initiallyExpanded: currentItem?.group == group,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          leading: Icon(group.icon, size: 18, color: AppTheme.primary),
          title: Text(
            group.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${items.length}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
          children: items
              .map((item) => _ItemRow(
                    item: item,
                    isSelected: widget.selectedCatalogId == item.id,
                    onTap: () => widget.onSelected(item.id),
                    showGroupLabel: false,
                  ))
              .toList(),
        );
      }).toList(),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final PredefinedLifeEvent item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showGroupLabel;

  const _ItemRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.showGroupLabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? item.color.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 16, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showGroupLabel)
                    Text(
                      item.group.label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
