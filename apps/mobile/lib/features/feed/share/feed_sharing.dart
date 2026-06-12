import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/feed_post.dart';

typedef FeedShareLauncher = Future<void> Function(String text, String subject);

enum FeedShareOutcome { shared, copiedToClipboard, failed }

/// Custom-scheme link that reopens the app on the shared post (see the
/// trikaal:// intent filter / URL type registered on each platform). Once a
/// public web domain exists, switch to verified https app links so the link
/// also resolves for people without the app installed.
String feedPostShareLink(String postId) => 'trikaal://feed/post/$postId';

String feedPostShareText(FeedPost post) {
  const int excerptLimit = 140;
  final collapsed = post.text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final excerpt = collapsed.length <= excerptLimit
      ? collapsed
      : '${collapsed.substring(0, excerptLimit).trimRight()}…';
  return '$excerpt\n\nRead the full post on Trikaal:\n'
      '${feedPostShareLink(post.id)}';
}

/// Opens the system share sheet. If the platform side is unavailable (e.g. a
/// stale build that predates the share plugin) the share text is copied to
/// the clipboard instead, so the user still walks away with the link.
Future<FeedShareOutcome> shareFeedPost(
  FeedPost post, {
  FeedShareLauncher? launcher,
}) async {
  final shareText = feedPostShareText(post);
  try {
    final effectiveLauncher = launcher ?? _shareWithSystemSheet;
    await effectiveLauncher(shareText, 'A post from Trikaal');
    return FeedShareOutcome.shared;
  } catch (_) {
    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      return FeedShareOutcome.copiedToClipboard;
    } catch (_) {
      return FeedShareOutcome.failed;
    }
  }
}

/// Share entry point for UI code: shares the post and surfaces fallback
/// outcomes through a snackbar.
Future<void> shareFeedPostWithFeedback(
  BuildContext context,
  FeedPost post, {
  FeedShareLauncher? launcher,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final outcome = await shareFeedPost(post, launcher: launcher);
  switch (outcome) {
    case FeedShareOutcome.shared:
      return;
    case FeedShareOutcome.copiedToClipboard:
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Sharing is unavailable right now — the post link was copied '
              'to your clipboard instead.',
            ),
          ),
        );
    case FeedShareOutcome.failed:
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not share the post. Please try again.'),
          ),
        );
  }
}

Future<void> _shareWithSystemSheet(String text, String subject) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: subject));
}
