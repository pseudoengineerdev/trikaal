import 'package:flutter/material.dart';

import '../../../../app/theme/trikaal_surface.dart';
import '../../data/models/feed_post.dart';
import 'feed_formats.dart';

const Color _likedHeartColor = Color(0xFFFF6B8A);

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    required this.post,
    required this.isLiked,
    required this.likeCount,
    required this.isSaved,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onShare,
    this.onOpen,
    super.key,
  });

  final FeedPost post;
  final bool isLiked;
  final int likeCount;
  final bool isSaved;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: TrikaalSurface.decoration(colorScheme: colorScheme),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PostHeader(post: post),
                const SizedBox(height: 12),
                Text(
                  post.text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.4),
                ),
                if (post.imageAsset != null) ...<Widget>[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.asset(
                        post.imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  colorScheme.primaryContainer,
                                  colorScheme.tertiaryContainer,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.auto_awesome_rounded, size: 36),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    _PostAction(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isLiked ? _likedHeartColor : null,
                      label: formatFeedCount(likeCount),
                      tooltip: isLiked ? 'Unlike' : 'Like',
                      onPressed: onToggleLike,
                    ),
                    const SizedBox(width: 8),
                    _PostAction(
                      icon: Icons.share_rounded,
                      tooltip: 'Share',
                      onPressed: onShare,
                    ),
                    const Spacer(),
                    _PostAction(
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      iconColor:
                          isSaved ? Theme.of(context).colorScheme.primary : null,
                      tooltip: isSaved ? 'Remove from saved' : 'Save',
                      onPressed: onToggleSave,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                colorScheme.primary,
                colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 20,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                post.authorName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                '${post.authorHandle} · '
                '${formatFeedTimestamp(post.postedAt)}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _SourceChip(source: post.source),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final FeedPostSource source;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (String label, IconData icon) = switch (source) {
      FeedPostSource.instagram => ('Instagram', Icons.camera_alt_rounded),
      FeedPostSource.twitter => ('X', Icons.tag_rounded),
      FeedPostSource.trikaal => ('Trikaal', Icons.auto_awesome_rounded),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 12,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
    this.label,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 22,
                color: iconColor ?? colorScheme.onSurfaceVariant,
              ),
              if (label != null) ...<Widget>[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
