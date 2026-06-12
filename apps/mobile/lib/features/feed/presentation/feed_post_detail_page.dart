import 'package:flutter/material.dart';

import '../../../app/widgets/astro_page_background.dart';
import '../data/models/feed_post.dart';
import '../share/feed_sharing.dart';
import 'state/feed_controller.dart';
import 'widgets/feed_post_card.dart';

/// Single-post view. Opened from the feed (sharing the feed's controller so
/// like/save state stays in sync) and from shared deep links, where it loads
/// the post by id on its own.
class FeedPostDetailPage extends StatefulWidget {
  const FeedPostDetailPage({
    required this.postId,
    this.controller,
    super.key,
  });

  final String postId;
  final FeedController? controller;

  @override
  State<FeedPostDetailPage> createState() => _FeedPostDetailPageState();
}

class _FeedPostDetailPageState extends State<FeedPostDetailPage> {
  late final FeedController _controller;
  FeedPost? _post;
  bool _loading = true;

  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? FeedController();
    _loadPost();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPost() async {
    await _controller.interactions.load();
    final post = await _controller.postById(widget.postId);
    if (!mounted) {
      return;
    }
    setState(() {
      _post = post;
      _loading = false;
    });
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
          'Post',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: AstroPageBackground(
        child: SafeArea(
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final post = _post;
    if (post == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.search_off_rounded, size: 40),
              const SizedBox(height: 10),
              const Text(
                'This post is no longer available.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final interactions = _controller.interactions;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: FeedPostCard(
            post: post,
            isLiked: interactions.isLiked(post.id),
            likeCount: interactions.likeCountFor(post),
            isSaved: interactions.isSaved(post.id),
            onToggleLike: () => interactions.toggleLike(post),
            onToggleSave: () => _toggleSave(post),
            onShare: () => shareFeedPostWithFeedback(context, post),
          ),
        );
      },
    );
  }
}
