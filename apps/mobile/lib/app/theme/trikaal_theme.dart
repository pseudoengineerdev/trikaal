import 'package:flutter/material.dart';

abstract final class TrikaalTheme {
  static const Color _darkAmethyst = Color(0xFF10002B);
  static const Color _deepAmethyst = Color(0xFF240046);
  static const Color _indigoInk = Color(0xFF3C096C);
  static const Color _indigoVelvet = Color(0xFF5A189A);
  static const Color _royalViolet = Color(0xFF7B2CBF);
  static const Color _lavenderPurple = Color(0xFF9D4EDD);
  static const Color _mauveMagic = Color(0xFFC77DFF);
  static const Color _mauve = Color(0xFFE0AAFF);

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _indigoVelvet,
      onPrimary: Colors.white,
      primaryContainer: _mauveMagic,
      onPrimaryContainer: _deepAmethyst,
      secondary: _royalViolet,
      onSecondary: Colors.white,
      secondaryContainer: _mauve,
      onSecondaryContainer: _deepAmethyst,
      tertiary: _indigoInk,
      onTertiary: Colors.white,
      tertiaryContainer: _lavenderPurple,
      onTertiaryContainer: _darkAmethyst,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      surface: _mauve,
      onSurface: _darkAmethyst,
      surfaceContainerHighest: _mauveMagic,
      onSurfaceVariant: _indigoInk,
      outline: _lavenderPurple,
      outlineVariant: _lavenderPurple,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _darkAmethyst,
      onInverseSurface: _mauve,
      inversePrimary: _mauveMagic,
      surfaceTint: _indigoVelvet,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _mauve,
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _darkAmethyst,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _darkAmethyst,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _darkAmethyst,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _darkAmethyst,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontFamily: 'Georgia',
        color: _darkAmethyst,
        height: 1.35,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontFamily: 'Georgia',
        color: _darkAmethyst,
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
        foregroundColor: _darkAmethyst,
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
        fillColor: const Color(0xFFF3D7FF),
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
