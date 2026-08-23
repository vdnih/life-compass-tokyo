import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/platform/url_launcher_service.dart';
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

class _ConstraintWarningCard extends ConsumerWidget {
  final ConstraintResult constraint;

  const _ConstraintWarningCard({required this.constraint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWarning = constraint.severity == ConstraintSeverity.warning;
    final bgColor = isWarning
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFEBF0F8);
    final borderColor = isWarning
        ? const Color(0xFFFFB74D)
        : AppTheme.primary.withValues(alpha: 0.4);
    final iconColor = isWarning
        ? const Color(0xFFE65100)
        : AppTheme.primary;
    final icon = isWarning ? Icons.warning_amber_rounded : Icons.info_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: Container(color: borderColor),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (constraint.scopeLabel != null) ...[
                        _ScopeBadge(
                          label: constraint.scopeLabel!,
                          color: iconColor,
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        constraint.message,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (constraint.sourceLabel != null) ...[
                        const SizedBox(height: 4),
                        _SourceLine(
                          label: constraint.sourceLabel!,
                          url: constraint.sourceUrl,
                          color: iconColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 実施主体（国/東京都）を示す小さなバッジ（PDR-009）。
class _ScopeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ScopeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 出典行。[url] があればタップで公式ページを開く（PDR-009）。
class _SourceLine extends ConsumerWidget {
  final String label;
  final String? url;
  final Color color;

  const _SourceLine({required this.label, required this.url, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyle = TextStyle(
      fontSize: 11,
      color: color.withValues(alpha: 0.8),
    );

    if (url == null) {
      return Text(label, style: textStyle);
    }

    return InkWell(
      onTap: () => ref.read(urlLauncherProvider).open(url!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: textStyle.copyWith(decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.open_in_new, size: 11, color: color.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}
