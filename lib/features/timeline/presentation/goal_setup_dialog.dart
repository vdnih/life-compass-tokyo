import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/goal_template_data.dart';
import '../domain/goal_template.dart';
import '../logic/goal_template_provider.dart';
import 'widgets/event_style.dart';

/// ゴール設定ダイアログ
///
/// ユーザーがゴールテンプレートを選択し、ゴール日を設定して
/// 関連イベントをタイムラインに一括追加するためのダイアログ。
class GoalSetupDialog extends ConsumerStatefulWidget {
  const GoalSetupDialog({super.key});

  @override
  ConsumerState<GoalSetupDialog> createState() => _GoalSetupDialogState();
}

class _GoalSetupDialogState extends ConsumerState<GoalSetupDialog> {
  GoalTemplate? _selectedTemplate;
  DateTime _goalDate = DateTime.now();
  bool _isApplying = false;

  List<GoalTemplate> get _templates => GoalTemplateRegistry.templates;

  /// 選択されたテンプレートのゴール日をもとにプレビューイベントを生成する
  List<_PreviewEvent> get _previewEvents {
    final template = _selectedTemplate;
    if (template == null) return [];

    final goalDateStr =
        '${_goalDate.year}-${_goalDate.month.toString().padLeft(2, '0')}';

    final events = <_PreviewEvent>[];

    // ゴールイベント自体
    events.add(_PreviewEvent(
      title: template.name,
      catalogId: template.goalCatalogId,
      date: goalDateStr,
      isGoal: true,
    ));

    // 関連イベント
    for (final te in template.relatedEvents) {
      final date = addMonthsToDate(goalDateStr, te.offsetMonthsFromGoal);
      events.add(_PreviewEvent(
        title: te.titleTemplate,
        catalogId: te.catalogId,
        date: date,
        isGoal: false,
        offsetMonths: te.offsetMonthsFromGoal,
      ));
    }

    // 日付順にソート
    events.sort((a, b) => a.date.compareTo(b.date));

    return events;
  }

  Future<void> _selectGoalDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _goalDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      helpText: 'ゴール年月を選択',
    );
    if (picked != null && picked != _goalDate) {
      setState(() {
        _goalDate = picked;
      });
    }
  }

  Future<void> _applyTemplate() async {
    final template = _selectedTemplate;
    if (template == null) return;

    setState(() => _isApplying = true);

    try {
      final goalDateStr =
          '${_goalDate.year}-${_goalDate.month.toString().padLeft(2, '0')}';
      await ref.read(goalTemplateProvider.notifier).applyTemplate(
            templateId: template.id,
            goalDate: goalDateStr,
            goalTitle: template.name,
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.grey[700],
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '目標を設定',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('テンプレートを選択'),
              ..._templates.map((template) => _TemplateCard(
                    template: template,
                    isSelected: _selectedTemplate?.id == template.id,
                    onTap: () {
                      setState(() {
                        _selectedTemplate = template;
                      });
                    },
                  )),
              if (_selectedTemplate != null) ...[
                const SizedBox(height: 16),
                _sectionLabel('ゴール日'),
                InkWell(
                  onTap: () => _selectGoalDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ゴール年月',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_goalDate.year}年${_goalDate.month}月',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionLabel('生成されるイベント'),
                ..._previewEvents.map((pe) => _PreviewEventTile(event: pe)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed:
              (_selectedTemplate != null && !_isApplying) ? _applyTemplate : null,
          child: _isApplying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('適用'),
        ),
      ],
    );
  }
}

/// テンプレート選択カード
class _TemplateCard extends StatelessWidget {
  final GoalTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primary : Colors.grey[700]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                catalogIcon(template.goalCatalogId),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// プレビューイベントのデータモデル（ダイアログ内限定）
class _PreviewEvent {
  final String title;
  final String catalogId;
  final String date;
  final bool isGoal;
  final int offsetMonths;

  const _PreviewEvent({
    required this.title,
    required this.catalogId,
    required this.date,
    required this.isGoal,
    this.offsetMonths = 0,
  });
}

/// プレビューイベントの行表示
class _PreviewEventTile extends StatelessWidget {
  final _PreviewEvent event;

  const _PreviewEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = catalogColor(event.catalogId);
    final dateStr = _formatDate(event.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: event.isGoal
              ? color.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: event.isGoal ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (event.isGoal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ゴール',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (!event.isGoal) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.link,
                        size: 11,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '関連',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    return '${parts[0]}年${int.parse(parts[1])}月';
  }
}
