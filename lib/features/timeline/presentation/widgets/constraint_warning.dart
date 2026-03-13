import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
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
    final bgColor = isWarning
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFEDE7F6);
    final borderColor = isWarning
        ? const Color(0xFFFFB74D)
        : AppTheme.primary.withValues(alpha: 0.4);
    final iconColor = isWarning
        ? const Color(0xFFE65100)
        : AppTheme.primary;
    final icon = isWarning ? Icons.warning_amber_rounded : Icons.info_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              constraint.message,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
