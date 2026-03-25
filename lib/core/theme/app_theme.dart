import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリ全体のデザインテーマ定義
///
/// カラーパレット: Subtraction Design — 白ベース、単一ダークネイビーアクセント
class AppTheme {
  AppTheme._();

  // ─── カラー定数 ───────────────────────────────────────────

  /// メインアクセント: ダークネイビー
  static const Color primary = Color(0xFF1E3A5F);

  /// サブアクセント: ミューテッドブルー（年齢ラベルなど補助要素に使用）
  static const Color secondary = Color(0xFF4A6FA5);

  /// 背景: 白（後方互換のため維持）
  static const Color background = Colors.white;

  /// 現在地マーカー: コーラルレッド
  static const Color nowMarker = Color(0xFFFF6B6B);

  // ─── テーマデータ ───────────────────────────────────────────

  /// ライトテーマ
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: Colors.white,
    );

    final base = GoogleFonts.notoSansJpTextTheme();

    final textTheme = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[800]),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[800]),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w400, color: Colors.black87),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w400, color: Colors.black87),
      bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w400, color: Colors.grey[700]),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: Colors.black87),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.grey[700]),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: Colors.grey[600]),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.grey[50],
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        color: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return Colors.white.withValues(alpha: 0.15);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.white.withValues(alpha: 0.8);
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
        floatingLabelStyle: const TextStyle(color: primary),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      chipTheme: ChipThemeData(
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return Colors.grey[300];
        }),
      ),
    );
  }
}
