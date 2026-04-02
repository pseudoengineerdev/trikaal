import 'package:flutter/material.dart';

enum AppDockItem { home, charts, profile, premium, menu }

class UniversalDockScaffold extends StatelessWidget {
  const UniversalDockScaffold({
    required this.body,
    required this.activeItem,
    required this.onItemSelected,
    this.appBar,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final AppDockItem activeItem;
  final ValueChanged<AppDockItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: appBar,
      body: body,
      bottomNavigationBar: UniversalCurvedDockBar(
        activeItem: activeItem,
        onItemSelected: onItemSelected,
      ),
    );
  }
}

class UniversalCurvedDockBar extends StatelessWidget {
  const UniversalCurvedDockBar({
    required this.activeItem,
    required this.onItemSelected,
    super.key,
  });

  final AppDockItem activeItem;
  final ValueChanged<AppDockItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isProfileActive = activeItem == AppDockItem.profile;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 92,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: <Widget>[
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipPath(
                  clipper: const _CurvedDockClipper(),
                  child: Container(
                    height: 72,
                    color: colorScheme.surface.withValues(alpha: 0.98),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _DockIcon(
                          icon: Icons.home_rounded,
                          isActive: activeItem == AppDockItem.home,
                          onTap: () => onItemSelected(AppDockItem.home),
                        ),
                        _DockIcon(
                          icon: Icons.grid_view_rounded,
                          isActive: activeItem == AppDockItem.charts,
                          onTap: () => onItemSelected(AppDockItem.charts),
                        ),
                        const SizedBox(width: 56),
                        _DockIcon(
                          icon: Icons.auto_awesome_outlined,
                          isActive: activeItem == AppDockItem.premium,
                          onTap: () => onItemSelected(AppDockItem.premium),
                        ),
                        _DockIcon(
                          icon: Icons.menu_rounded,
                          isActive: activeItem == AppDockItem.menu,
                          onTap: () => onItemSelected(AppDockItem.menu),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 2,
              child: Material(
                color: isProfileActive
                    ? colorScheme.primary
                    : colorScheme.primary.withValues(alpha: 0.92),
                shape: const CircleBorder(
                  side: BorderSide(
                    color: Color(0x1FFFFFFF),
                    width: 1.2,
                  ),
                ),
                elevation: 8,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onItemSelected(AppDockItem.profile),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.person_rounded,
                      size: 22,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedDockClipper extends CustomClipper<Path> {
  const _CurvedDockClipper();

  @override
  Path getClip(Size size) {
    const cornerRadius = 32.0;
    const notchRadius = 30.0;
    const notchDepth = 30.0;
    const notchSideInset = 8.0;

    final width = size.width;
    final centerX = width / 2;
    final notchStartX = centerX - notchRadius - notchSideInset;
    final notchEndX = centerX + notchRadius + notchSideInset;

    final path = Path()
      ..moveTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..lineTo(notchStartX, 0)
      ..cubicTo(
        centerX - notchRadius,
        0,
        centerX - notchRadius + 4,
        notchDepth,
        centerX,
        notchDepth,
      )
      ..cubicTo(
        centerX + notchRadius - 4,
        notchDepth,
        centerX + notchRadius,
        0,
        notchEndX,
        0,
      )
      ..lineTo(width - cornerRadius, 0)
      ..quadraticBezierTo(width, 0, width, cornerRadius)
      ..lineTo(width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Navigation',
    );
  }
}
