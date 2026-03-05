import 'package:flutter/material.dart';

void showAddEventDialog(
  BuildContext context, {
  DateTime? initialDate,
  required void Function(
    String title,
    String startDateStr,
    String? endDateStr,
    bool isLifeEvent,
  )
  onSubmit,
}) {
  showDialog(
    context: context,
    builder:
        (context) => _AddEventDialog(
          initialDate: initialDate ?? DateTime.now(),
          onSubmit: onSubmit,
        ),
  );
}

class _AddEventDialog extends StatefulWidget {
  final DateTime initialDate;
  final void Function(
    String title,
    String startDateStr,
    String? endDateStr,
    bool isLifeEvent,
  )
  onSubmit;

  const _AddEventDialog({required this.initialDate, required this.onSubmit});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _titleController = TextEditingController();
  late DateTime _startDate;
  DateTime? _endDate;
  bool _hasEndDate = false;
  bool _isLifeEvent = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
    _endDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('イベントを追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'タイトル'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('期間を指定する'),
            value: _hasEndDate,
            onChanged: (value) {
              setState(() {
                _hasEndDate = value;
              });
            },
          ),
          if (_hasEndDate)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('終了年月'),
              subtitle: Text(
                '${_endDate?.year ?? _startDate.year}年${_endDate?.month ?? _startDate.month}月',
              ),
              trailing: const Icon(Icons.calendar_today),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text;
            if (title.isEmpty) return;

            String? endDateStr;
            if (_hasEndDate && _endDate != null) {
              endDateStr = _formatDate(_endDate!);
            }

            widget.onSubmit(title, _formatDate(_startDate), endDateStr, _isLifeEvent);
            Navigator.pop(context);
          },
          child: const Text('追加'),
        ),
      ],
    );
  }
}
