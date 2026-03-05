import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/timeline_events_provider.dart';
import '../domain/career_event.dart';

class AddEventDialog extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final bool initialIsLifeEvent;

  const AddEventDialog({
    super.key,
    this.initialDate,
    this.initialIsLifeEvent = false,
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
  late bool _isLifeEvent;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedEndDate = widget.initialDate ?? DateTime.now();
    _isLifeEvent = widget.initialIsLifeEvent;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('イベントを追加'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('種別'),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('仕事')),
                  ButtonSegment(value: true, label: Text('プライベート')),
                ],
                selected: {_isLifeEvent},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _isLifeEvent = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  hintText: '例: 昇進、引越しなど',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '詳細',
                  hintText: 'イベントの詳細を入力',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('開始年月'),
                subtitle: Text('${_selectedDate.year}年${_selectedDate.month}月'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('期間を指定する'),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('終了年月'),
                  subtitle: Text(
                    '${_selectedEndDate?.year ?? _selectedDate.year}年${_selectedEndDate?.month ?? _selectedDate.month}月',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectEndDate(context),
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
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              String? endDateStr;
              if (_hasEndDate && _selectedEndDate != null) {
                endDateStr =
                    '${_selectedEndDate!.year}-${_selectedEndDate!.month.toString().padLeft(2, '0')}';
              }
              final newEvent = CareerEvent(
                date:
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
                endDate: endDateStr,
                title: _titleController.text,
                description: _descriptionController.text,
                isLifeEvent: _isLifeEvent,
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
