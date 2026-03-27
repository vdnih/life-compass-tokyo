import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../logic/timeline_events_provider.dart';
import '../logic/constraint_checker_provider.dart';
import '../domain/life_event.dart';
import 'widgets/constraint_warning.dart';

/// イベント編集ダイアログ
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
  late DateTime _selectedDate;
  DateTime? _selectedEndDate;
  late bool _hasEndDate;
  late bool _isWork;
  late EventCategory _category;
  late EventStatus _status;

  List<EventCategory> get _availableCategories =>
      EventCategory.values.where((c) => c.isWork == _isWork).toList();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController =
        TextEditingController(text: widget.event.description);
    _selectedDate = widget.event.dateTime;
    _hasEndDate = widget.event.endDate != null;
    _selectedEndDate =
        widget.event.endDate != null ? widget.event.endDateTime : null;
    _isWork = widget.event.isWork;
    _category = widget.event.category;
    _status = widget.event.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: '開始年月を選択',
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime(2100),
      helpText: '終了年月を選択',
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
              _sectionLabel('種別'),
              SegmentedButton<bool>(
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
                segments: const [
                  ButtonSegment(value: true, label: Text('仕事')),
                  ButtonSegment(value: false, label: Text('プライベート')),
                ],
                selected: {_isWork},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _isWork = newSelection.first;
                    if (!_availableCategories.contains(_category)) {
                      _category = _availableCategories.first;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              _sectionLabel('カテゴリ'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableCategories.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat.label),
                    selected: selected,
                    selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? AppTheme.primary : null,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.primary.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                    onSelected: (value) {
                      if (value) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
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
              Builder(
                builder: (context) {
                  final eventsAsync = ref.watch(timelineEventsProvider);
                  if (!eventsAsync.hasValue) return const SizedBox.shrink();
                  final previewEvent = LifeEvent(
                    id: widget.event.id,
                    date:
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
                    title: _titleController.text.isEmpty
                        ? '(編集中)'
                        : _titleController.text,
                    description: '',
                    category: _category,
                  );
                  final others = eventsAsync.value!
                      .where((e) => e.id != widget.event.id)
                      .toList();
                  final allConstraints =
                      checkAllConstraints([...others, previewEvent]);
                  final relevant = allConstraints
                      .where((c) => c.targetEventTitle == previewEvent.title)
                      .toList();
                  if (relevant.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ConstraintWarningList(constraints: relevant),
                  );
                },
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
              final updated = LifeEvent(
                id: widget.event.id,
                date:
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
                endDate: endDateStr,
                title: _titleController.text,
                description: _descriptionController.text,
                category: _category,
                status: _status,
                goalId: widget.event.goalId,
                isGoal: widget.event.isGoal,
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
