import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/timeline/presentation/timeline_screen.dart';

void main() {
  runApp(const ProviderScope(child: LifePlanApp()));
}

class LifePlanApp extends StatelessWidget {
  const LifePlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'わたしのライフプラン',
      theme: AppTheme.lightTheme,
      home: const TimelineScreen(),
    );
  }
}
