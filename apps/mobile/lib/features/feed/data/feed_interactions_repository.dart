import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/feed_post.dart';

class FeedInteractions {
  const FeedInteractions({
    required this.likedPostIds,
    required this.savedPosts,
  });

  const FeedInteractions.empty()
      : likedPostIds = const <String>{},
        savedPosts = const <FeedPost>[];

  final Set<String> likedPostIds;

  /// Saved posts are stored whole so the profile page can render them
  /// without refetching the feed. Newest save first.
  final List<FeedPost> savedPosts;
}

abstract class FeedInteractionsRepository {
  Future<FeedInteractions> load();

  Future<void> save(FeedInteractions interactions);
}

class SharedPreferencesFeedInteractionsRepository
    implements FeedInteractionsRepository {
  SharedPreferencesFeedInteractionsRepository({
    Future<SharedPreferences> Function()? prefsLoader,
  }) : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  static const String _storageKey = 'trikaal_feed_interactions_v1';
  final Future<SharedPreferences> Function() _prefsLoader;
  bool _useMemoryFallback = false;
  FeedInteractions _memoryFallback = const FeedInteractions.empty();

  @override
  Future<FeedInteractions> load() async {
    if (_useMemoryFallback) {
      return _memoryFallback;
    }

    try {
      final prefs = await _prefsLoader();
      final rawValue = prefs.getString(_storageKey);
      if (rawValue == null || rawValue.trim().isEmpty) {
        return const FeedInteractions.empty();
      }
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) {
        return const FeedInteractions.empty();
      }

      final likedPostIds = <String>{};
      final rawLiked = decoded['likedPostIds'];
      if (rawLiked is List) {
        for (final entry in rawLiked) {
          final id = entry?.toString() ?? '';
          if (id.isNotEmpty) {
            likedPostIds.add(id);
          }
        }
      }

      final savedPosts = <FeedPost>[];
      final rawSaved = decoded['savedPosts'];
      if (rawSaved is List) {
        for (final entry in rawSaved) {
          if (entry is! Map) {
            continue;
          }
          final map = entry.map(
            (dynamic key, dynamic value) => MapEntry(key.toString(), value),
          );
          final post = FeedPost.fromJson(map);
          if (post.id.isEmpty) {
            continue;
          }
          savedPosts.add(post);
        }
      }

      return FeedInteractions(
        likedPostIds: likedPostIds,
        savedPosts: savedPosts,
      );
    } catch (_) {
      _useMemoryFallback = true;
      return _memoryFallback;
    }
  }

  @override
  Future<void> save(FeedInteractions interactions) async {
    _memoryFallback = interactions;
    if (_useMemoryFallback) {
      return;
    }

    try {
      final prefs = await _prefsLoader();
      final payload = <String, dynamic>{
        'likedPostIds': interactions.likedPostIds.toList(growable: false),
        'savedPosts': interactions.savedPosts
            .map((FeedPost post) => post.toJson())
            .toList(growable: false),
      };
      final didSave = await prefs.setString(_storageKey, jsonEncode(payload));
      if (!didSave) {
        _useMemoryFallback = true;
      }
    } catch (_) {
      _useMemoryFallback = true;
    }
  }
}
