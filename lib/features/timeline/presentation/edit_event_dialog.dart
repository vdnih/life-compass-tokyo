import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/year_month_picker.dart';
import '../../catalog/data/predefined_catalog_registry.dart';
import '../logic/timeline_events_provider.dart';
import '../domain/life_event.dart';

/// イベント編集ダイアログ（Wave 4 予算フィールド追加）
///
/// Wave 3 でカタログD&D方式への本格書き換えを予定。
/// TODO(Wave3): カタログ選択UIを実装
class EditEventDialog extends ConsumerStatefulWidget {
  final LifeEvent event;

  const EditEventDialog({super.key, required this.event});

  @override
  ConsumerState<EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends ConsumerState<EditEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetController;
  late DateTime _selectedDate;
  DateTime? _selectedEndDate;
  late bool _hasEndDate;
  late EventStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController =
        TextEditingController(text: widget.event.description);
    _budgetController = TextEditingController(
      text: widget.event.budgetYen != null
          ? widget.event.budgetYen.toString()
          : '',
    );
    _selectedDate = widget.event.dateTime;
    _hasEndDate = widget.event.endDate != null;
    _selectedEndDate =
        widget.event.endDate != null ? widget.event.endDateTime : null;
    _status = widget.event.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showYearMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      title: '開始年月を選択',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        if (_hasEndDate &&
            _selectedEndDate != null &&
            _selectedEndDate!.isBefore(picked)) {
          _selectedEndDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showYearMonthPicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime(2100),
      title: '終了年月を選択',
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
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

  /// カタログの defaultBudgetYen を取得してプレースホルダー文字列を生成する
  String _budgetPlaceholder() {
    final catalog =
        PredefinedCatalogRegistry.findById(widget.event.catalogId);
    if (catalog != null && catalog.defaultBudgetYen != null) {
      return '目安: ¥${catalog.defaultBudgetYen}円';
    }
    return '例: 300000';
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
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'イベントを編集',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('ステータス'),
              SegmentedButton<EventStatus>(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primary;
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return AppTheme.primary;
                  }),
                  side: WidgetStateProperty.all(
                    BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                segments: EventStatus.values.map((s) {
                  return ButtonSegment(value: s, label: Text(s.label));
                }).toList(),
                selected: {_status},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _status = newSelection.first;
                  });
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  prefixIcon: Icon(Icons.title, size: 18),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '詳細',
                  prefixIcon: Icon(Icons.notes, size: 18),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: '予算（円）',
                  hintText: _budgetPlaceholder(),
                  prefixIcon: const Icon(Icons.currency_yen, size: 18),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final parsed = int.tryParse(value);
                    if (parsed == null) {
                      return '数値を入力してください';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectDate(context),
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
                      Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '開始年月',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_selectedDate.year}年${_selectedDate.month}月',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('期間を指定する',
                    style: TextStyle(fontSize: 14)),
                activeThumbColor: AppTheme.primary,
                value: _hasEndDate,
                onChanged: (bool value) {
                  setState(() {
                    _hasEndDate = value;
                    if (value && _selectedEndDate == null) {
                      _selectedEndDate = _selectedDate;
                    }
                  });
                },
              ),
              if (_hasEndDate)
                InkWell(
                  onTap: () => _selectEndDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '終了年月',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_selectedEndDate?.year ?? _selectedDate.year}年${_selectedEndDate?.month ?? _selectedDate.month}月',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              String? endDateStr;
              if (_hasEndDate && _selectedEndDate != null) {
                endDateStr =
                    '${_selectedEndDate!.year}-${_selectedEndDate!.month.toString().padLeft(2, '0')}';
              }
              final budgetText = _budgetController.text.trim();
              final budgetYen =
                  budgetText.isNotEmpty ? int.tryParse(budgetText) : null;

              final updated = LifeEvent(
                id: widget.event.id,
                date:
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
                endDate: endDateStr,
                title: _titleController.text,
                description: _descriptionController.text,
                catalogId: widget.event.catalogId,
                status: _status,
                goalId: widget.event.goalId,
                isGoal: widget.event.isGoal,
                parentEventId: widget.event.parentEventId,
                kind: widget.event.kind,
                budgetYen: budgetYen,
              );
              ref
                  .read(timelineEventsProvider.notifier)
                  .updateEvent(updated);
              Navigator.pop(context);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
