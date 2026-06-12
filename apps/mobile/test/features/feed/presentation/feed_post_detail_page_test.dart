import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/feed/data/feed_interactions_repository.dart';
import 'package:trikaal_mobile/features/feed/data/feed_repository.dart';
import 'package:trikaal_mobile/features/feed/data/models/feed_post.dart';
import 'package:trikaal_mobile/features/feed/presentation/feed_post_detail_page.dart';
import 'package:trikaal_mobile/features/feed/presentation/state/feed_controller.dart';
import 'package:trikaal_mobile/features/feed/presentation/state/feed_interactions_store.dart';
import 'package:trikaal_mobile/features/feed/presentation/widgets/feed_post_card.dart';

class _MemoryFeedInteractionsRepository implements FeedInteractionsRepository {
  _MemoryFeedInteractionsRepository([FeedInteractions? initial])
      : stored = initial ?? const FeedInteractions.empty();

  FeedInteractions stored;

  @override
  Future<FeedInteractions> load() async => stored;

  @override
  Future<void> save(FeedInteractions interactions) async {
    stored = interactions;
  }
}

FeedController _buildController({FeedInteractions? interactions}) {
  return FeedController(
    repository: DummyFeedRepository(
      anchorTime: DateTime(2026, 6, 11, 12),
      simulatedLatency: Duration.zero,
    ),
    interactions: FeedInteractionsStore(
      repository: _MemoryFeedInteractionsRepository(interactions),
    ),
  );
}

void main() {
  group('FeedPostDetailPage', () {
    testWidgets('loads a post by id, the deep-link path',
        (WidgetTester tester) async {
      final controller = _buildController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: FeedPostDetailPage(postId: 'tk-2', controller: controller),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(FeedPostCard), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
      final expectedPost = await controller.postById('tk-2');
      expect(find.textContaining(expectedPost!.text.split('\n').first),
          findsOneWidget);
    });

    testWidgets('shows the not-found state for unknown ids',
        (WidgetTester tester) async {
      final controller = _buildController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: FeedPostDetailPage(
            postId: 'does-not-exist',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This post is no longer available.'), findsOneWidget);
      expect(find.text('Go back'), findsOneWidget);
      expect(find.byType(FeedPostCard), findsNothing);
    });

    testWidgets('like toggle on the detail page updates the count',
        (WidgetTester tester) async {
      final controller = _buildController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: FeedPostDetailPage(postId: 'tk-0', controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final post = await controller.postById('tk-0');
      final baseCount = post!.baseLikeCount;
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      // The tall post card pushes the action row below the test viewport.
      await tester.ensureVisible(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(controller.interactions.likeCountFor(post), baseCount + 1);
    });

    testWidgets('prefers the saved copy of a post over the repository',
        (WidgetTester tester) async {
      final savedCopy = FeedPost(
        id: 'tk-1',
        source: FeedPostSource.trikaal,
        authorName: 'Trikaal',
        authorHandle: '@trikaal',
        postedAt: DateTime(2026, 5, 20, 8),
        text: 'The exact text that was saved.',
        baseLikeCount: 77,
      );
      final controller = _buildController(
        interactions: FeedInteractions(
          likedPostIds: const <String>{},
          savedPosts: <FeedPost>[savedCopy],
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: FeedPostDetailPage(postId: 'tk-1', controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('The exact text that was saved.'), findsOneWidget);
      expect(find.text('77'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });
  });
}
