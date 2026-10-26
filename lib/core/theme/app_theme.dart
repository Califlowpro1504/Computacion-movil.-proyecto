import 'package:flutter/material.dart';

/// Shared palette inspired by the dark barber/marketplace reference.
class AppTheme {
  static const background = Color(0xFF080F14);
  static const surface = Color(0xFF111F29);
  static const elevated = Color(0xFF192B36);
  static const border = Color(0xFF31434E);
  static const ivory = Color(0xFFF5F0E7);
  static const muted = Color(0xFFB0BDC5);
  static const accent = Color(0xFFE8B85E);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      onPrimary: background,
      secondary: accent,
      surface: surface,
      onSurface: ivory,
      onSurfaceVariant: muted,
      outline: border,
      error: const Color(0xFFFFB4AB),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.apply(bodyColor: ivory, displayColor: ivory),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ivory,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: ivory, fontSize: 17, fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(color: border),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: const TextStyle(color: muted),
        helperStyle: const TextStyle(color: muted, height: 1.5),
        errorMaxLines: 3,
        prefixIconColor: accent,
        suffixIconColor: muted,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          disabledBackgroundColor: elevated,
          disabledForegroundColor: muted,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: elevated,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          color: states.contains(WidgetState.selected) ? accent : muted,
          fontSize: 12,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? accent : muted,
        )),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
    );
  }
}
