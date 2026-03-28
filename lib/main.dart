import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore オフライン永続化（タブ間キャッシュ共有を有効化）
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    // Web: synchronizeTabs はデフォルトで有効
  );

  runApp(const ProviderScope(child: LifePlanApp()));
}

class LifePlanApp extends ConsumerWidget {
  const LifePlanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'わたしのライフプラン',
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
