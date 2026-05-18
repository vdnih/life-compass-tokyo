import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 年と月をドロップダウンで選択するダイアログを表示し、選択された [DateTime] を返す。
/// キャンセル時は null を返す。
Future<DateTime?> showYearMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) {
  final first = firstDate ?? DateTime(1900);
  final last = lastDate ?? DateTime(2100);

  final clamped = initialDate.isBefore(first)
      ? first
      : initialDate.isAfter(last)
          ? last
          : initialDate;

  return showDialog<DateTime>(
    context: context,
    builder: (context) => _YearMonthPickerDialog(
      initialDate: clamped,
      firstDate: first,
      lastDate: last,
      title: title ?? '年月を選択',
    ),
  );
}

class _YearMonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const _YearMonthPickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  @override
  State<_YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  List<int> get _availableMonths {
    final startMonth =
        _selectedYear == widget.firstDate.year ? widget.firstDate.month : 1;
    final endMonth =
        _selectedYear == widget.lastDate.year ? widget.lastDate.month : 12;
    return List.generate(endMonth - startMonth + 1, (i) => startMonth + i);
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (i) => widget.firstDate.year + i,
    );
    final months = _availableMonths;
    final clampedMonth =
        months.contains(_selectedMonth) ? _selectedMonth : months.first;

    return AlertDialog(
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: 2,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '年',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  isExpanded: true,
                  items: years
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text('$y年'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    final avail = _availableMonthsFor(value);
                    setState(() {
                      _selectedYear = value;
                      _selectedMonth = avail.contains(_selectedMonth)
                          ? _selectedMonth
                          : avail.first;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '月',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: clampedMonth,
                  isExpanded: true,
                  items: months
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m月'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedMonth = value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
          ),
          onPressed: () => Navigator.pop(
            context,
            DateTime(_selectedYear, clampedMonth),
          ),
          child: const Text('決定'),
        ),
      ],
    );
  }

  List<int> _availableMonthsFor(int year) {
    final startMonth =
        year == widget.firstDate.year ? widget.firstDate.month : 1;
    final endMonth =
        year == widget.lastDate.year ? widget.lastDate.month : 12;
    return List.generate(endMonth - startMonth + 1, (i) => startMonth + i);
  }
}
