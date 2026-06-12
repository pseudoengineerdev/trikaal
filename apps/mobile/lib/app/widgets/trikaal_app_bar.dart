import 'package:flutter/material.dart';

/// The primary Trikaal app bar shared by every screen: notifications and
/// current-location on the left, the Trikaal logo in the center, and
/// calendar + premium shortcuts on the right.
///
/// Screens that need an extra header row below it (the home screen's
/// Today/Feed tabs) pass it via [bottom]; every other screen renders only
/// this primary bar.
PreferredSizeWidget buildTrikaalAppBar(
  BuildContext context, {
  VoidCallback? onNotificationsTap,
  VoidCallback? onCurrentLocationTap,
  String? currentLocationLabel,
  VoidCallback? onCalendarTap,
  VoidCallback? onPremiumTap,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  final mergedActions = <Widget>[
    if (onCalendarTap != null)
      IconButton(
        tooltip: 'Hindu calendar',
        icon: const Icon(Icons.calendar_month_rounded),
        onPressed: onCalendarTap,
      ),
    if (onPremiumTap != null)
      IconButton(
        tooltip: 'Premium',
        icon: const Icon(Icons.auto_awesome_rounded),
        onPressed: onPremiumTap,
      ),
    ...?actions,
  ];

  void handleNotificationsTap() {
    if (onNotificationsTap != null) {
      onNotificationsTap();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications and home-screen widget controls are coming soon.',
          ),
        ),
      );
  }

  final leadingIcons = <Widget>[
    IconButton(
      tooltip: 'Notifications',
      icon: const Icon(Icons.notifications_none_rounded),
      onPressed: handleNotificationsTap,
    ),
    if (onCurrentLocationTap != null)
      IconButton(
        tooltip: currentLocationLabel == null
            ? 'Set current location'
            : 'Current location: $currentLocationLabel',
        icon: const Icon(Icons.location_on_rounded),
        onPressed: onCurrentLocationTap,
      ),
  ];

  return AppBar(
    automaticallyImplyLeading: false,
    leadingWidth: leadingIcons.length * 48.0,
    leading: Row(
      mainAxisSize: MainAxisSize.min,
      children: leadingIcons,
    ),
    centerTitle: true,
    title: Text(
      'Trikaal',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'Samarkan',
            fontSize: 40,
            fontWeight: FontWeight.w500,
          ),
    ),
    actions: mergedActions.isEmpty ? null : mergedActions,
    bottom: bottom,
  );
}
