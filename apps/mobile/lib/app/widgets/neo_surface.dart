import 'package:flutter/material.dart';

class NeoSurface extends StatelessWidget {
  const NeoSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.radius = 18,
    this.borderColor,
    this.backgroundColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = backgroundColor ?? colorScheme.surface;
    final effectiveBorderColor =
        borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(Colors.white.withValues(alpha: 0.06), baseColor),
            Color.alphaBlend(Colors.black.withValues(alpha: 0.13), baseColor),
          ],
        ),
        border: Border.all(color: effectiveBorderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            offset: const Offset(9, 9),
            blurRadius: 16,
            spreadRadius: -7,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            offset: const Offset(-7, -7),
            blurRadius: 14,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
