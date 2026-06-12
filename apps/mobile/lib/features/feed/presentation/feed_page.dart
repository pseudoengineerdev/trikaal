import 'package:flutter/material.dart';

import '../../../app/widgets/astro_page_background.dart';
import '../data/models/feed_post.dart';
import '../share/feed_sharing.dart';
import 'feed_post_detail_page.dart';
import 'state/feed_controller.dart';
import 'widgets/feed_post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({this.controller, super.key});

  /// Injectable for tests; the page creates and owns one by default.
  final FeedController? controller;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const double _loadMoreThreshold = 600;

  late final FeedController _controller;
  final ScrollController _scrollController = ScrollController();

  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? FeedController();
    _controller.loadInitial();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      _controller.loadMore();
    }
  }

  void _openPost(FeedPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return FeedPostDetailPage(
            postId: post.id,
            controller: _controller,
          );
        },
      ),
    );
  }

  void _toggleSave(FeedPost post) {
    final wasSaved = _controller.interactions.isSaved(post.id);
    _controller.interactions.toggleSave(post);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasSaved
                ? 'Removed from your saved posts.'
                : 'Saved. Find it in your profile under Saved.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Feed',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: AstroPageBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              final posts = _controller.posts;

              if (posts.isEmpty) {
                if (_controller.initialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.error != null) {
                  return _FeedErrorState(
                    message: _controller.error!,
                    onRetry: _controller.loadInitial,
                  );
                }
              }

              return RefreshIndicator(
                onRefresh: _controller.loadInitial,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: posts.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index >= posts.length) {
                      return _FeedFooter(
                        error: _controller.error,
                        onRetry: _controller.loadMore,
                      );
                    }
                    final post = posts[index];
                    final interactions = _controller.interactions;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FeedPostCard(
                        post: post,
                        isLiked: interactions.isLiked(post.id),
                        likeCount: interactions.likeCountFor(post),
                        isSaved: interactions.isSaved(post.id),
                        onToggleLike: () => interactions.toggleLike(post),
                        onToggleSave: () => _toggleSave(post),
                        onShare: () => shareFeedPostWithFeedback(context, post),
                        onOpen: () => _openPost(post),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: <Widget>[
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }
}

class _FeedErrorState extends StatelessWidget {
  const _FeedErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
