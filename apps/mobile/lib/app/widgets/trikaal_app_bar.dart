import 'package:flutter/material.dart';

PreferredSizeWidget buildTrikaalAppBar(
  BuildContext context, {
  VoidCallback? onPremiumTap,
  List<Widget>? actions,
}) {
  final mergedActions = <Widget>[
    if (onPremiumTap != null)
      IconButton(
        tooltip: 'Premium',
        icon: const Icon(Icons.auto_awesome_rounded),
        onPressed: onPremiumTap,
      ),
    ...?actions,
  ];

  return AppBar(
    automaticallyImplyLeading: false,
    leading: IconButton(
      tooltip: 'Notifications',
      icon: const Icon(Icons.notifications_none_rounded),
      onPressed: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications and home-screen widget controls are coming soon.',
              ),
            ),
          );
      },
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
  );
}
