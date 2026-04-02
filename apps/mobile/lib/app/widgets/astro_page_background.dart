import 'package:flutter/material.dart';

class AstroPageBackground extends StatelessWidget {
  const AstroPageBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFFFF8F1),
            Color(0xFFF8EEE2),
            Color(0xFFF6EAE1),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -70,
            right: -40,
            child: _Orb(
              diameter: 180,
              color: const Color(0x33E6A15B),
            ),
          ),
          Positioned(
            top: 140,
            left: -60,
            child: _Orb(
              diameter: 160,
              color: const Color(0x262D8E87),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withValues(alpha: 0.01),
            ],
          ),
        ),
      ),
    );
  }
}
