import 'package:flutter/material.dart';

PreferredSizeWidget buildTrikaalAppBar(
  BuildContext context, {
  List<Widget>? actions,
}) {
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
    actions: actions,
  );
}
