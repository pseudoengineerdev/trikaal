import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/app/home_shell_page.dart';
import 'package:trikaal_mobile/app/navigation/app_routes.dart';
import 'package:trikaal_mobile/features/feed/presentation/feed_page.dart';
import 'package:trikaal_mobile/features/feed/presentation/feed_post_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('feedPostIdFromRouteName', () {
    test('parses warm path-only deep link names', () {
      expect(feedPostIdFromRouteName('/post/tk-7'), 'tk-7');
      expect(feedPostIdFromRouteName('/post/tk-123'), 'tk-123');
    });

    test('parses full trikaal:// links delivered on cold start', () {
      expect(feedPostIdFromRouteName('trikaal://feed/post/tk-7'), 'tk-7');
    });

    test('rejects unrelated routes', () {
      expect(feedPostIdFromRouteName('/'), isNull);
      expect(feedPostIdFromRouteName('/post'), isNull);
      expect(feedPostIdFromRouteName('/post/'), isNull);
      expect(feedPostIdFromRouteName('/other/tk-7'), isNull);
      expect(feedPostIdFromRouteName('/post/tk-7/extra'), isNull);
    });
  });

  group('isFeedListRouteName', () {
    test('accepts the feed list segment', () {
      expect(isFeedListRouteName('/post'), isTrue);
      expect(isFeedListRouteName('/feed'), isTrue);
      expect(isFeedListRouteName('trikaal://feed/post'), isTrue);
    });

    test('rejects other routes', () {
      expect(isFeedListRouteName('/'), isFalse);
      expect(isFeedListRouteName('/post/tk-7'), isFalse);
      expect(isFeedListRouteName('/settings'), isFalse);
    });
  });

  group('onGenerateAppRoute', () {
    test('builds routes for home and feed deep links, nothing else', () {
      final homeRoute = onGenerateAppRoute(const RouteSettings(name: '/'));
      expect(homeRoute, isA<MaterialPageRoute<void>>());

      final detailRoute =
          onGenerateAppRoute(const RouteSettings(name: '/post/tk-3'));
      expect(detailRoute, isA<MaterialPageRoute<void>>());
      expect(detailRoute!.settings.name, '/post/tk-3');

      final listRoute = onGenerateAppRoute(const RouteSettings(name: '/post'));
      expect(listRoute, isA<MaterialPageRoute<void>>());

      expect(onGenerateAppRoute(const RouteSettings(name: '/unknown')), isNull);
      expect(onGenerateAppRoute(const RouteSettings()), isNull);
    });
  });

  group('generateAppInitialRoutes', () {
    test('plain launch yields just the home route', () {
      final routes = generateAppInitialRoutes('/');
      expect(routes, hasLength(1));
    });

    test('full deep-link URL yields home, feed, then the post', () {
      final routes = generateAppInitialRoutes('trikaal://feed/post/tk-3');
      expect(routes, hasLength(3));
      expect(routes[1].settings.name, '/post');
      expect(routes[2].settings.name, '/post/tk-3');
    });

    test('feed-only link yields home then the feed', () {
      final routes = generateAppInitialRoutes('trikaal://feed/post');
      expect(routes, hasLength(2));
      expect(routes[1].settings.name, '/post');
    });
  });

  group('route builders end to end', () {
    testWidgets('warm pushNamed renders the post detail page',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: onGenerateAppRoute,
          home: const Scaffold(body: Text('root')),
        ),
      );

      navigatorKey.currentState!.pushNamed('/post/tk-3');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(FeedPostDetailPage), findsOneWidget);
      // The dummy repository resolves tk-3 to a real post, not the
      // not-found state.
      expect(find.text('This post is no longer available.'), findsNothing);
    });

    testWidgets('cold-start deep link stacks home, feed, and post',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: onGenerateAppRoute,
          onGenerateInitialRoutes: generateAppInitialRoutes,
          initialRoute: 'trikaal://feed/post/tk-3',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(FeedPostDetailPage), findsOneWidget);

      // Back pops to the feed, then to the home shell.
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(FeedPage), findsOneWidget);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(HomeShellPage), findsOneWidget);
    });
  });
}
