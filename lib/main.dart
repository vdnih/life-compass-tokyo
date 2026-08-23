import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/branding/app_branding.dart';
import 'core/firebase/emulator_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // kDebugMode（flutter run）は常にローカルエミュレータに繋ぐ。エスケープハッチは
  // 設けない（ADR-024）。本番データが必要な場合は `flutter run --release` を使う。
  if (kDebugMode) {
    await connectToEmulators();
  }
  runApp(const ProviderScope(child: LifePlanApp()));
}

class LifePlanApp extends StatelessWidget {
  const LifePlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppBranding.appName,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      locale: const Locale('ja', 'JP'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP')],
    );
  }
}
