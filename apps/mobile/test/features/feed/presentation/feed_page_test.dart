import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/feed/data/feed_interactions_repository.dart';
import 'package:trikaal_mobile/features/feed/data/feed_repository.dart';
import 'package:trikaal_mobile/features/feed/data/models/feed_post.dart';
import 'package:trikaal_mobile/features/feed/presentation/feed_page.dart';
import 'package:trikaal_mobile/features/feed/presentation/state/feed_controller.dart';
import 'package:trikaal_mobile/features/feed/presentation/state/feed_interactions_store.dart';
import 'package:trikaal_mobile/features/feed/presentation/widgets/feed_post_card.dart';

class _MemoryFeedInteractionsRepository implements FeedInteractionsRepository {
  FeedInteractions stored = const FeedInteractions.empty();

  @override
  Future<FeedInteractions> load() async => stored;

  @override
  Future<void> save(FeedInteractions interactions) async {
    stored = interactions;
  }
}

class _CountingFeedRepository implements FeedRepository {
  int pageFetches = 0;

  @override
  Future<List<FeedPost>> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    pageFetches += 1;
    final start = page * pageSize;
    return List<FeedPost>.generate(pageSize, (int offset) {
      final index = start + offset;
      return FeedPost(
        id: 'tk-$index',
        source: FeedPostSource.trikaal,
        authorName: 'Trikaal',
        authorHandle: '@trikaal',
        postedAt: DateTime(2026, 6, 1).subtract(Duration(hours: index)),
        text: 'Post number $index about the Moon.',
        baseLikeCount: 100 + index,
      );
    });
  }

  @override
  Future<FeedPost?> fetchPostById(String postId) async => null;
}

/// Fails the first fetch of each page number, succeeds on retry.
class _FailOnceFeedRepository implements FeedRepository {
  _FailOnceFeedRepository(this._inner);

  final FeedRepository _inner;
  final Set<int> _failedPages = <int>{};

  @override
  Future<List<FeedPost>> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    if (_failedPages.add(page)) {
      throw StateError('transient failure for page $page');
    }
    return _inner.fetchPage(page: page, pageSize: pageSize);
  }

  @override
  Future<FeedPost?> fetchPostById(String postId) => _inner.fetchPostById(postId);
}

void main() {
  group('FeedPage', () {
    testWidgets('renders the first page and loads more on scroll',
        (WidgetTester tester) async {
      final repository = _CountingFeedRepository();
      final controller = FeedController(
        repository: repository,
        interactions: FeedInteractionsStore(
          repository: _MemoryFeedInteractionsRepository(),
        ),
        pageSize: 6,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(home: FeedPage(controller: controller)),
      );
      // The infinite-feed footer spinner never settles, so pump bounded
      // frames instead of pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Post number 0 about the Moon.'), findsOneWidget);
      expect(repository.pageFetches, greaterThanOrEqualTo(1));
      final fetchesAfterFirstBuild = repository.pageFetches;

      await tester.fling(
        find.byType(ListView),
        const Offset(0, -3000),
        2500,
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(repository.pageFetches, greaterThan(fetchesAfterFirstBuild));
      expect(controller.posts.length, greaterThan(6));
    });

    testWidgets('initial load failure shows the retry state and recovers',
        (WidgetTester tester) async {
      final controller = FeedController(
        repository: _FailOnceFeedRepository(_CountingFeedRepository()),
        interactions: FeedInteractionsStore(
          repository: _MemoryFeedInteractionsRepository(),
        ),
        pageSize: 3,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(home: FeedPage(controller: controller)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('Could not load the feed. Please try again.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Post number 0 about the Moon.'), findsOneWidget);
      expect(
        find.text('Could not load the feed. Please try again.'),
        findsNothing,
      );
    });

    testWidgets('like tap updates the visible count',
        (WidgetTester tester) async {
      final controller = FeedController(
        repository: _CountingFeedRepository(),
        interactions: FeedInteractionsStore(
          repository: _MemoryFeedInteractionsRepository(),
        ),
        pageSize: 3,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(home: FeedPage(controller: controller)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final firstCard = find.byType(FeedPostCard).first;
      expect(
        find.descendant(of: firstCard, matching: find.text('100')),
        findsOneWidget,
      );

      await tester.tap(
        find
            .descendant(
              of: firstCard,
              matching: find.byIcon(Icons.favorite_border_rounded),
            )
            .first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.descendant(
          of: find.byType(FeedPostCard).first,
          matching: find.text('101'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FeedPostCard).first,
          matching: find.byIcon(Icons.favorite_rounded),
        ),
        findsOneWidget,
      );
    });
  });
}
