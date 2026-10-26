import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF0D0B10);
  static const surface = Color(0xFF19151D);
  static const ivory = Color(0xFFF1E7D8);
  static const muted = Color(0xFFBEB0BB);
  static const accent = Color(0xFFD79B9F);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF742E43),
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      onPrimary: background,
      surface: surface,
      onSurface: ivory,
      error: const Color(0xFFFFB4AB),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ivory,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF100E14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        labelStyle: const TextStyle(color: muted),
        helperStyle: const TextStyle(color: muted, height: 1.5),
        prefixIconColor: muted,
        suffixIconColor: accent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF51434F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF742E43),
          foregroundColor: ivory,
          disabledBackgroundColor: const Color(0xFF46303B),
          disabledForegroundColor: muted,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: ivory),
    );
  }
}
