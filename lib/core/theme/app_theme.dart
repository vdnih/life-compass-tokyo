import 'package:flutter/material.dart';

/// アプリ全体のデザインテーマ定義
///
/// カラーパレット: Indigo & Rose — 20〜40代女性向けの洗練・モダンなトーン
class AppTheme {
  AppTheme._();

  // ─── カラー定数 ───────────────────────────────────────────

  /// メインアクセント: ディープインディゴ
  static const Color primary = Color(0xFF6B4FA0);

  /// サブアクセント: ダスティローズ
  static const Color secondary = Color(0xFFD4698F);

  /// 背景: 薄ラベンダー
  static const Color background = Color(0xFFF7F4FF);

  /// 仕事レーン背景
  static const Color workLaneBackground = Color(0xFFEEEAFF);

  /// プライベートレーン背景
  static const Color personalLaneBackground = Color(0xFFFFF0F5);

  /// 仕事サイドバー背景
  static const Color workSidebarBackground = Color(0xFFE8E0F8);

  /// プライベートサイドバー背景
  static const Color personalSidebarBackground = Color(0xFFFFE4EF);

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

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        elevation: 3,
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
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: primary.withValues(alpha: 0.8)),
        floatingLabelStyle: const TextStyle(color: primary),
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
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
