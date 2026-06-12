import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/feed/data/feed_interactions_repository.dart';
import 'package:trikaal_mobile/features/feed/data/feed_repository.dart';
import 'package:trikaal_mobile/features/feed/data/models/feed_post.dart';
import 'package:trikaal_mobile/features/feed/presentation/state/feed_controller.dart';
import 'package:trikaal_mobile/features/feed/presentation/state/feed_interactions_store.dart';

class _MemoryFeedInteractionsRepository implements FeedInteractionsRepository {
  FeedInteractions stored = const FeedInteractions.empty();
  int saveCalls = 0;

  @override
  Future<FeedInteractions> load() async => stored;

  @override
  Future<void> save(FeedInteractions interactions) async {
    stored = interactions;
    saveCalls += 1;
  }
}

class _FailingFeedRepository implements FeedRepository {
  @override
  Future<List<FeedPost>> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    throw StateError('boom');
  }

  @override
  Future<FeedPost?> fetchPostById(String postId) async {
    throw StateError('boom');
  }
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

FeedController _buildController({
  FeedRepository? repository,
  _MemoryFeedInteractionsRepository? interactionsRepository,
}) {
  return FeedController(
    repository: repository ??
        DummyFeedRepository(
          anchorTime: DateTime(2026, 6, 11, 12),
          simulatedLatency: Duration.zero,
        ),
    interactions: FeedInteractionsStore(
      repository:
          interactionsRepository ?? _MemoryFeedInteractionsRepository(),
    ),
    pageSize: 4,
  );
}

void main() {
  group('FeedController', () {
    test('loadInitial fills the first page', () async {
      final controller = _buildController();

      await controller.loadInitial();

      expect(controller.initialLoading, isFalse);
      expect(controller.error, isNull);
      expect(controller.posts, hasLength(4));
      expect(controller.interactions.loaded, isTrue);
      controller.dispose();
    });

    test('loadMore appends the next page', () async {
      final controller = _buildController();
      await controller.loadInitial();

      await controller.loadMore();

      expect(controller.posts, hasLength(8));
      expect(
        controller.posts.map((FeedPost post) => post.id).toSet(),
        hasLength(8),
      );
      controller.dispose();
    });

    test('load failure stores user-facing error', () async {
      final controller = _buildController(repository: _FailingFeedRepository());

      await controller.loadInitial();

      expect(controller.error, isNotNull);
      expect(controller.posts, isEmpty);
      expect(controller.initialLoading, isFalse);
      controller.dispose();
    });

    test('toggleLike bumps the visible count and persists', () async {
      final interactionsRepository = _MemoryFeedInteractionsRepository();
      final controller =
          _buildController(interactionsRepository: interactionsRepository);
      await controller.loadInitial();
      final post = controller.posts.first;
      final baseCount = controller.interactions.likeCountFor(post);

      await controller.interactions.toggleLike(post);

      expect(controller.interactions.isLiked(post.id), isTrue);
      expect(controller.interactions.likeCountFor(post), baseCount + 1);
      expect(interactionsRepository.stored.likedPostIds, contains(post.id));

      await controller.interactions.toggleLike(post);

      expect(controller.interactions.isLiked(post.id), isFalse);
      expect(controller.interactions.likeCountFor(post), baseCount);
      expect(
        interactionsRepository.stored.likedPostIds,
        isNot(contains(post.id)),
      );
      controller.dispose();
    });

    test('toggleSave stores newest first and unsaves on repeat', () async {
      final interactionsRepository = _MemoryFeedInteractionsRepository();
      final controller =
          _buildController(interactionsRepository: interactionsRepository);
      await controller.loadInitial();
      final first = controller.posts[0];
      final second = controller.posts[1];

      await controller.interactions.toggleSave(first);
      await controller.interactions.toggleSave(second);

      expect(
        controller.interactions.savedPosts
            .map((FeedPost post) => post.id)
            .toList(),
        <String>[second.id, first.id],
      );
      expect(interactionsRepository.stored.savedPosts, hasLength(2));

      await controller.interactions.toggleSave(second);

      expect(controller.interactions.isSaved(second.id), isFalse);
      expect(
        controller.interactions.savedPosts
            .map((FeedPost post) => post.id)
            .toList(),
        <String>[first.id],
      );
      controller.dispose();
    });

    test('loadMore failure keeps loaded posts and retries the same page',
        () async {
      final repository = _FailOnceFeedRepository(
        DummyFeedRepository(
          anchorTime: DateTime(2026, 6, 11, 12),
          simulatedLatency: Duration.zero,
        ),
      );
      // Page 0 fails once too, so retry loadInitial first.
      final controller = _buildController(repository: repository);

      await controller.loadInitial();
      expect(controller.error, isNotNull);
      expect(controller.posts, isEmpty);

      await controller.loadInitial();
      expect(controller.error, isNull);
      expect(controller.posts, hasLength(4));

      await controller.loadMore();
      expect(controller.error, 'Could not load more posts. Please try again.');
      expect(controller.posts, hasLength(4));

      await controller.loadMore();
      expect(controller.error, isNull);
      expect(controller.posts, hasLength(8));
      expect(
        controller.posts.map((FeedPost post) => post.id).toSet(),
        hasLength(8),
      );
      controller.dispose();
    });

    test('postById serves loaded posts and falls back to repository',
        () async {
      final controller = _buildController();
      await controller.loadInitial();

      final loaded = await controller.postById(controller.posts.first.id);
      expect(loaded!.id, controller.posts.first.id);

      final deep = await controller.postById('tk-999');
      expect(deep, isNotNull);
      expect(deep!.id, 'tk-999');
      controller.dispose();
    });
  });
}
