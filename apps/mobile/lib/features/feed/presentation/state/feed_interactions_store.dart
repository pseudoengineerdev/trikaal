import 'package:flutter/foundation.dart';

import '../../data/feed_interactions_repository.dart';
import '../../data/models/feed_post.dart';

/// Like/save state shared by the feed, post detail, and profile saved tab.
/// Backed by local persistence so interactions survive restarts.
class FeedInteractionsStore extends ChangeNotifier {
  FeedInteractionsStore({FeedInteractionsRepository? repository})
      : _repository =
            repository ?? SharedPreferencesFeedInteractionsRepository();

  /// Single app-wide instance. Every page must observe the same in-memory
  /// state: separate instances would only sync through disk at load time,
  /// so a save made in the feed would never reach an already-open profile,
  /// and whole-snapshot persistence would let one instance clobber
  /// another's writes.
  static final FeedInteractionsStore shared = FeedInteractionsStore();

  final FeedInteractionsRepository _repository;
  Set<String> _likedPostIds = <String>{};
  List<FeedPost> _savedPosts = <FeedPost>[];
  bool _loaded = false;
  bool _disposed = false;
  Future<void>? _pendingLoad;

  bool get loaded => _loaded;

  List<FeedPost> get savedPosts => List<FeedPost>.unmodifiable(_savedPosts);

  bool isLiked(String postId) => _likedPostIds.contains(postId);

  bool isSaved(String postId) =>
      _savedPosts.any((FeedPost post) => post.id == postId);

  /// Base count comes with the post; the local like adds one on top, the
  /// same way social clients render optimistic likes.
  int likeCountFor(FeedPost post) =>
      post.baseLikeCount + (isLiked(post.id) ? 1 : 0);

  /// Idempotent: once hydrated from disk, the in-memory state is the source
  /// of truth and repeated calls are no-ops.
  Future<void> load() {
    return _pendingLoad ??= _loadFromRepository();
  }

  Future<void> _loadFromRepository() async {
    final interactions = await _repository.load();
    if (_disposed) {
      return;
    }
    _likedPostIds = Set<String>.from(interactions.likedPostIds);
    _savedPosts = List<FeedPost>.from(interactions.savedPosts);
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleLike(FeedPost post) async {
    if (!_likedPostIds.remove(post.id)) {
      _likedPostIds.add(post.id);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> toggleSave(FeedPost post) async {
    final existingIndex =
        _savedPosts.indexWhere((FeedPost saved) => saved.id == post.id);
    if (existingIndex >= 0) {
      _savedPosts.removeAt(existingIndex);
    } else {
      _savedPosts.insert(0, post);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() {
    return _repository.save(
      FeedInteractions(
        likedPostIds: Set<String>.from(_likedPostIds),
        savedPosts: List<FeedPost>.from(_savedPosts),
      ),
    );
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
    super.dispose();
  }
}
