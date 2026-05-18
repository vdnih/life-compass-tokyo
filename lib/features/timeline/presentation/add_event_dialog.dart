import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../catalog/data/predefined_catalog_registry.dart';
import '../../catalog/domain/predefined_life_event.dart';
import 'catalog_picker_field.dart';
import '../logic/timeline_events_provider.dart';
import '../domain/life_event.dart';

/// UUID生成ユーティリティ
const _uuid = Uuid();

/// イベント追加ダイアログ
///
/// 仕事/プライベートのレーン区分を選択し、カタログからカテゴリを選んで
/// ライフイベントをタイムラインに追加する。
class AddEventDialog extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final bool initialIsWork;

  const AddEventDialog({
    super.key,
    this.initialDate,
    this.initialIsWork = true,
  });

  @override
  ConsumerState<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  DateTime? _selectedEndDate;
  bool _hasEndDate = false;
  EventStatus _status = EventStatus.recorded;

  late bool _isWork;
  late String _selectedCatalogId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedEndDate = widget.initialDate ?? DateTime.now();
    _isWork = widget.initialIsWork;
    _selectedCatalogId = _isWork ? 'joining-company' : 'marriage-registration';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<PredefinedLifeEvent> get _catalogItems {
    if (_isWork) {
      return PredefinedCatalogRegistry.all
          .where((e) => e.group == LifeEventGroup.career)
          .toList();
    } else {
      return PredefinedCatalogRegistry.all
          .where((e) => e.group != LifeEventGroup.career)
          .toList();
    }
  }

  void _onLaneChanged(bool isWork) {
    setState(() {
      _isWork = isWork;
      final items = isWork
          ? PredefinedCatalogRegistry.all
              .where((e) => e.group == LifeEventGroup.career)
              .toList()
          : PredefinedCatalogRegistry.all
              .where((e) => e.group != LifeEventGroup.career)
              .toList();
      _selectedCatalogId = items.isNotEmpty ? items.first.id : '';
    });
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
    final catalogItems = _catalogItems;
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
              Icons.add_circle_outline,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'イベントを追加',
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
              _sectionLabel('レーン'),
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
                  _onLaneChanged(newSelection.first);
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              _sectionLabel('カテゴリ'),
              CatalogPickerField(
                selectedCatalogId: _selectedCatalogId,
                availableItems: catalogItems,
                onChanged: (id) => setState(() => _selectedCatalogId = id),
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
                  hintText: '例: 昇進、引越しなど',
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
                  hintText: 'イベントの詳細を入力',
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
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '期間を指定する',
                  style: TextStyle(fontSize: 14),
                ),
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
              final newEvent = LifeEvent(
                id: _uuid.v4(),
                date:
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
                endDate: endDateStr,
                title: _titleController.text,
                description: _descriptionController.text,
                catalogId: _selectedCatalogId,
                status: _status,
              );
              ref.read(timelineEventsProvider.notifier).addEvent(newEvent);
              Navigator.pop(context);
            }
          },
          child: const Text('追加'),
        ),
      ],
    );
  }
}
