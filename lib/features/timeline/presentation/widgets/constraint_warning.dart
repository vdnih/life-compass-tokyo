import 'package:flutter/material.dart';
import '../../domain/constraint_result.dart';

/// 制約チェック結果の警告/情報メッセージを表示するウィジェット
class ConstraintWarningList extends StatelessWidget {
  final List<ConstraintResult> constraints;

  const ConstraintWarningList({super.key, required this.constraints});

  @override
  Widget build(BuildContext context) {
    if (constraints.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: constraints
          .map((c) => _ConstraintWarningCard(constraint: c))
          .toList(),
    );
  }
}

class _ConstraintWarningCard extends StatelessWidget {
  final ConstraintResult constraint;

  const _ConstraintWarningCard({required this.constraint});

  @override
  Widget build(BuildContext context) {
    final isWarning = constraint.severity == ConstraintSeverity.warning;
    final bgColor =
        isWarning ? Colors.amber.shade50 : Colors.lightBlue.shade50;
    final iconColor =
        isWarning ? Colors.amber.shade700 : Colors.lightBlue.shade700;
    final icon = isWarning ? Icons.warning_amber_rounded : Icons.info_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              constraint.message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
