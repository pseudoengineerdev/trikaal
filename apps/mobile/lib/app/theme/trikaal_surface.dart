import 'package:flutter/material.dart';

abstract final class TrikaalSurface {
  static const double cardFillAlpha = 0.22;
  static const double cardBorderAlpha = 0.42;
  static const double disabledFillAlpha = 0.14;
  static const double disabledBorderAlpha = 0.26;

  static Color fill({double alpha = cardFillAlpha}) {
    return Colors.black.withValues(alpha: alpha);
  }

  static BorderSide border(
    ColorScheme colorScheme, {
    double alpha = cardBorderAlpha,
  }) {
    return BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: alpha));
  }

  static RoundedRectangleBorder shape({
    required ColorScheme colorScheme,
    double radius = 18,
    double borderAlpha = cardBorderAlpha,
  }) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border(colorScheme, alpha: borderAlpha),
    );
  }

  static BoxDecoration decoration({
    required ColorScheme colorScheme,
    double radius = 18,
    double fillAlpha = cardFillAlpha,
    double borderAlpha = cardBorderAlpha,
    DecorationImage? image,
  }) {
    return BoxDecoration(
      color: fill(alpha: fillAlpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: borderAlpha),
      ),
      image: image,
    );
  }
}
