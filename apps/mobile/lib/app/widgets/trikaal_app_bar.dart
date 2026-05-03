import 'package:flutter/material.dart';

PreferredSizeWidget buildTrikaalAppBar(
  BuildContext context, {
  List<Widget>? actions,
  VoidCallback? onPremiumTap,
  VoidCallback? onQuickAddTap,
}) {
  List<Widget> defaultActions() {
    return <Widget>[
      IconButton(
        tooltip: 'Premium',
        icon: const Icon(Icons.auto_awesome_outlined),
        onPressed: onPremiumTap ??
            () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content:
                        Text('Premium features and plans are coming soon.'),
                  ),
                );
            },
      ),
      IconButton(
        tooltip: 'Quick Add',
        icon: const Icon(Icons.add_rounded),
        onPressed: onQuickAddTap ??
            () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Quick actions are coming soon.'),
                  ),
                );
            },
      ),
    ];
  }

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
    actions: actions ?? defaultActions(),
  );
}
