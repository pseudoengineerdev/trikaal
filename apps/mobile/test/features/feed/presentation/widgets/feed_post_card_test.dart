import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/feed/data/models/feed_post.dart';
import 'package:trikaal_mobile/features/feed/presentation/widgets/feed_formats.dart';
import 'package:trikaal_mobile/features/feed/presentation/widgets/feed_post_card.dart';

FeedPost _post() {
  return FeedPost(
    id: 'tk-1',
    source: FeedPostSource.twitter,
    authorName: 'Trikaal',
    authorHandle: '@trikaal',
    postedAt: DateTime.now().subtract(const Duration(hours: 5)),
    text: 'Lagna is the body, Moon is the mind, Sun is the soul.',
    baseLikeCount: 1280,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: child,
      ),
    ),
  );
}

void main() {
  group('FeedPostCard', () {
    testWidgets('renders author, text, source, and like count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          FeedPostCard(
            post: _post(),
            isLiked: false,
            likeCount: 1280,
            isSaved: false,
            onToggleLike: () {},
            onToggleSave: () {},
            onShare: () {},
          ),
        ),
      );

      expect(find.text('Trikaal'), findsOneWidget);
      expect(find.textContaining('@trikaal'), findsOneWidget);
      expect(
        find.text('Lagna is the body, Moon is the mind, Sun is the soul.'),
        findsOneWidget,
      );
      expect(find.text('X'), findsOneWidget);
      expect(find.text('1.3K'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('shows filled icons when liked and saved',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          FeedPostCard(
            post: _post(),
            isLiked: true,
            likeCount: 1281,
            isSaved: true,
            onToggleLike: () {},
            onToggleSave: () {},
            onShare: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets('invokes the action callbacks', (WidgetTester tester) async {
      var likes = 0;
      var saves = 0;
      var shares = 0;
      var opens = 0;

      await tester.pumpWidget(
        _wrap(
          FeedPostCard(
            post: _post(),
            isLiked: false,
            likeCount: 1280,
            isSaved: false,
            onToggleLike: () => likes++,
            onToggleSave: () => saves++,
            onShare: () => shares++,
            onOpen: () => opens++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.tap(find.byIcon(Icons.share_rounded));
      await tester.tap(find.text(
        'Lagna is the body, Moon is the mind, Sun is the soul.',
      ));

      expect(likes, 1);
      expect(saves, 1);
      expect(shares, 1);
      expect(opens, 1);
    });
  });

  group('formatFeedCount', () {
    test('formats compact counts', () {
      expect(formatFeedCount(0), '0');
      expect(formatFeedCount(968), '968');
      expect(formatFeedCount(1000), '1K');
      expect(formatFeedCount(1240), '1.2K');
      expect(formatFeedCount(1500000), '1.5M');
    });
  });

  group('formatFeedTimestamp', () {
    final now = DateTime(2026, 6, 11, 12);

    test('formats relative times', () {
      expect(
        formatFeedTimestamp(now.subtract(const Duration(seconds: 30)),
            now: now),
        'now',
      );
      expect(
        formatFeedTimestamp(now.subtract(const Duration(minutes: 12)),
            now: now),
        '12m',
      );
      expect(
        formatFeedTimestamp(now.subtract(const Duration(hours: 5)), now: now),
        '5h',
      );
      expect(
        formatFeedTimestamp(now.subtract(const Duration(days: 3)), now: now),
        '3d',
      );
    });

    test('falls back to dates past a week', () {
      expect(
        formatFeedTimestamp(DateTime(2026, 3, 8), now: now),
        'Mar 8',
      );
      expect(
        formatFeedTimestamp(DateTime(2025, 12, 20), now: now),
        'Dec 20, 2025',
      );
    });
  });
}
