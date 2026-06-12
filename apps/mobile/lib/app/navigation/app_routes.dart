import 'package:flutter/material.dart';

import '../../features/feed/presentation/feed_page.dart';
import '../../features/feed/presentation/feed_post_detail_page.dart';
import '../home_shell_page.dart';

/// Extracts a feed post id from a route name. Warm deep links arrive as a
/// path-only name ('/post/tk-3' — the framework strips scheme and host),
/// while Android cold starts deliver the full 'trikaal://feed/post/tk-3'
/// link as the initial route; both shapes parse here.
String? feedPostIdFromRouteName(String routeName) {
  final uri = Uri.tryParse(routeName);
  if (uri == null) {
    return null;
  }
  final segments = uri.pathSegments;
  if (segments.length == 2 && segments[0] == 'post' && segments[1].isNotEmpty) {
    return segments[1];
  }
  return null;
}

bool isFeedListRouteName(String routeName) {
  final uri = Uri.tryParse(routeName);
  if (uri == null) {
    return false;
  }
  final segments = uri.pathSegments;
  return segments.length == 1 && (segments[0] == 'post' || segments[0] == 'feed');
}

Route<dynamic>? onGenerateAppRoute(RouteSettings settings) {
  final name = settings.name;
  if (name == null) {
    return null;
  }

  if (name == Navigator.defaultRouteName) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => const HomeShellPage(),
    );
  }

  final postId = feedPostIdFromRouteName(name);
  if (postId != null) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => FeedPostDetailPage(postId: postId),
    );
  }

  if (isFeedListRouteName(name)) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => const FeedPage(),
    );
  }

  return null;
}

/// Builds the cold-start stack. Navigator's default initial-route chaining
/// only handles names that start with '/', but a deep-linked launch hands us
/// the full trikaal:// URL — so the stack is assembled here explicitly:
/// home, then the feed, then the shared post on top.
List<Route<dynamic>> generateAppInitialRoutes(String initialRoute) {
  final routes = <Route<dynamic>>[
    onGenerateAppRoute(
      const RouteSettings(name: Navigator.defaultRouteName),
    )!,
  ];

  final postId = feedPostIdFromRouteName(initialRoute);
  if (postId != null) {
    routes
      ..add(onGenerateAppRoute(const RouteSettings(name: '/post'))!)
      ..add(onGenerateAppRoute(RouteSettings(name: '/post/$postId'))!);
  } else if (isFeedListRouteName(initialRoute)) {
    routes.add(onGenerateAppRoute(const RouteSettings(name: '/post'))!);
  }

  return routes;
}
