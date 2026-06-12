import 'package:flutter/foundation.dart';

import '../../data/feed_repository.dart';
import '../../data/models/feed_post.dart';
import 'feed_interactions_store.dart';

class FeedController extends ChangeNotifier {
  FeedController({
    FeedRepository? repository,
    FeedInteractionsStore? interactions,
    this.pageSize = 8,
  })  : _repository = repository ?? DummyFeedRepository(),
        interactions = interactions ?? FeedInteractionsStore.shared {
    this.interactions.addListener(notifyListeners);
  }

  final FeedRepository _repository;

  /// The app-wide store by default; never disposed here — it outlives any
  /// single page so like/save state stays consistent across feed, post
  /// detail, and the profile saved tab.
  final FeedInteractionsStore interactions;
  final int pageSize;

  final List<FeedPost> _posts = <FeedPost>[];
  int _nextPage = 0;
  bool _initialLoading = false;
  bool _loadingMore = false;
  bool _disposed = false;
  String? _error;

  List<FeedPost> get posts => List<FeedPost>.unmodifiable(_posts);

  bool get initialLoading => _initialLoading;

  bool get loadingMore => _loadingMore;

  String? get error => _error;

  Future<void> loadInitial() async {
    _initialLoading = true;
    _error = null;
    notifyListeners();

    try {
      await interactions.load();
      final page = await _repository.fetchPage(page: 0, pageSize: pageSize);
      if (_disposed) {
        return;
      }
      _posts
        ..clear()
        ..addAll(page);
      _nextPage = 1;
    } catch (_) {
      _error = 'Could not load the feed. Please try again.';
    } finally {
      _initialLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_initialLoading || _loadingMore) {
      return;
    }
    _loadingMore = true;
    notifyListeners();

    try {
      final page = await _repository.fetchPage(
        page: _nextPage,
        pageSize: pageSize,
      );
      if (_disposed) {
        return;
      }
      _posts.addAll(page);
      _nextPage += 1;
      _error = null;
    } catch (_) {
      _error = 'Could not load more posts. Please try again.';
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Resolution order matters: loaded feed posts, then the saved copy (so a
  /// detail page opened from the profile shows exactly what was saved), then
  /// the repository for deep-linked ids.
  Future<FeedPost?> postById(String postId) async {
    for (final post in _posts) {
      if (post.id == postId) {
        return post;
      }
    }
    for (final post in interactions.savedPosts) {
      if (post.id == postId) {
        return post;
      }
    }
    return _repository.fetchPostById(postId);
  }

  @override
  void notifyListeners() {
    if (_disposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    interactions.removeListener(notifyListeners);
    super.dispose();
  }
}
