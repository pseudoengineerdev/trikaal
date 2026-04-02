import 'package:flutter/material.dart';

abstract final class TrikaalTheme {
  static const Color _saffron = Color(0xFF9A531B);
  static const Color _teal = Color(0xFF2B6A67);
  static const Color _ink = Color(0xFF2B2018);
  static const Color _sand = Color(0xFFF9F3EC);

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _saffron,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFDDBE),
      onPrimaryContainer: Color(0xFF381A05),
      secondary: _teal,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFBDECE7),
      onSecondaryContainer: Color(0xFF07211F),
      tertiary: Color(0xFF6B5D36),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF4E3AC),
      onTertiaryContainer: Color(0xFF201B06),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      surface: Color(0xFFFFFBF8),
      onSurface: _ink,
      surfaceContainerHighest: Color(0xFFF2E5D7),
      onSurfaceVariant: Color(0xFF65574A),
      outline: Color(0xFF9E8E80),
      outlineVariant: Color(0xFFD9C7B8),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF3A2D23),
      onInverseSurface: Color(0xFFFFEDE1),
      inversePrimary: Color(0xFFFFB77E),
      surfaceTint: _saffron,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _sand,
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontFamily: 'Georgia',
        color: _ink,
        height: 1.35,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontFamily: 'Georgia',
        color: _ink,
        height: 1.35,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.titleMedium?.copyWith(
            fontSize: 19,
            color: colorScheme.onPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelLarge?.copyWith(fontSize: 13),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 24);
          }
          return const IconThemeData(size: 22);
        }),
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
        height: 70,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
