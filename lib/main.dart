import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const TimelineScreen(),
    );
  }
}
