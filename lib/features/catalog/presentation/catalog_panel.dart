import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../timeline/logic/timeline_events_provider.dart';
import '../domain/predefined_life_event.dart';
import '../logic/catalog_provider.dart';

/// カタログパネル（左サイドバー）
///
/// グループ別折りたたみリストと検索フィールドを持つ。
/// 各カタログ項目は [LongPressDraggable<PredefinedLifeEvent>] でラップされている。
/// パネル幅は外部から制約（SizedBox.width = 200）する。
class CatalogPanel extends ConsumerWidget {
  const CatalogPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogByGroup = ref.watch(catalogByGroupProvider);
    final searchQuery = ref.watch(catalogSearchQueryProvider);
    final filteredCatalog = ref.watch(catalogSearchProvider);
    final eventsAsync = ref.watch(timelineEventsProvider);
    final placedCatalogIds = eventsAsync.maybeWhen(
      data: (events) => events.map((e) => e.catalogId).toSet(),
      orElse: () => <String>{},
    );

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // 検索フィールド
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '検索',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
                prefixIcon:
                    Icon(Icons.search, size: 16, color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (value) {
                ref.read(catalogSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          // グループ一覧
          Expanded(
            child: searchQuery.isNotEmpty
                ? _buildSearchResults(filteredCatalog, placedCatalogIds)
                : _buildGroupList(
                    context, catalogByGroup, placedCatalogIds, ref),
          ),
        ],
      ),
    );
  }

  /// 検索結果リスト（グループ分けなし）
  Widget _buildSearchResults(
    List<PredefinedLifeEvent> results,
    Set<String> placedCatalogIds,
  ) {
    if (results.isEmpty) {
      return Center(
        child: Text(
          '該当なし',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _CatalogItemTile(
          item: item,
          isPlaced: placedCatalogIds.contains(item.id),
        );
      },
    );
  }

  /// グループ別折りたたみリスト
  Widget _buildGroupList(
    BuildContext context,
    Map<LifeEventGroup, List<PredefinedLifeEvent>> catalogByGroup,
    Set<String> placedCatalogIds,
    WidgetRef ref,
  ) {
    // デフォルト展開グループ
    const defaultExpandedGroups = {
      LifeEventGroup.marriage,
      LifeEventGroup.childbirth,
    };

    return ListView(
      children: LifeEventGroup.values.map((group) {
        final items = catalogByGroup[group] ?? [];
        return _CatalogGroupSection(
          group: group,
          items: items,
          placedCatalogIds: placedCatalogIds,
          initiallyExpanded: defaultExpandedGroups.contains(group),
        );
      }).toList(),
    );
  }
}

/// グループ別折りたたみセクション
class _CatalogGroupSection extends StatelessWidget {
  final LifeEventGroup group;
  final List<PredefinedLifeEvent> items;
  final Set<String> placedCatalogIds;
  final bool initiallyExpanded;

  const _CatalogGroupSection({
    required this.group,
    required this.items,
    required this.placedCatalogIds,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final groupIcon = _groupIcon(group);
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: EdgeInsets.zero,
      leading: Icon(groupIcon, size: 16, color: AppTheme.primary),
      title: Text(
        group.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
      children: items.map((item) {
        return _CatalogItemTile(
          item: item,
          isPlaced: placedCatalogIds.contains(item.id),
        );
      }).toList(),
    );
  }

  IconData _groupIcon(LifeEventGroup group) {
    switch (group) {
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

/// ドラッグ可能なカタログアイテムタイル
class _CatalogItemTile extends StatelessWidget {
  final PredefinedLifeEvent item;
  final bool isPlaced;

  const _CatalogItemTile({
    required this.item,
    required this.isPlaced,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<PredefinedLifeEvent>(
      data: item,
      delay: const Duration(milliseconds: 400),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 0.85,
          child: _buildItemCard(opacity: 1.0),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildItemRow(),
      ),
      child: _buildItemRow(),
    );
  }

  Widget _buildItemRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(item.icon, size: 14, color: item.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPlaced)
            Icon(
              Icons.check_circle,
              size: 12,
              color: Colors.green.shade400,
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard({required double opacity}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 160,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: item.color.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 14, color: item.color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: item.color,
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
