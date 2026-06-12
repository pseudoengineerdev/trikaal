import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/feed/data/models/feed_post.dart';
import 'package:trikaal_mobile/features/feed/share/feed_sharing.dart';

FeedPost _post({required String id, required String text}) {
  return FeedPost(
    id: id,
    source: FeedPostSource.instagram,
    authorName: 'Trikaal',
    authorHandle: '@trikaal',
    postedAt: DateTime(2026, 6, 1),
    text: text,
    baseLikeCount: 10,
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('feedPostShareLink', () {
    test('builds the deep link for a post', () {
      expect(feedPostShareLink('tk-12'), 'trikaal://feed/post/tk-12');
    });
  });

  group('feedPostShareText', () {
    test('includes excerpt and link', () {
      final text = feedPostShareText(
        _post(id: 'tk-5', text: 'Shani teaches.\n\n#Shani'),
      );

      expect(text, contains('Shani teaches. #Shani'));
      expect(text, contains('trikaal://feed/post/tk-5'));
    });

    test('truncates long posts', () {
      final longText = List<String>.filled(60, 'nakshatra').join(' ');
      final text = feedPostShareText(_post(id: 'tk-6', text: longText));

      expect(text, contains('…'));
      expect(text.split('\n').first.length, lessThanOrEqualTo(145));
      expect(text, contains('trikaal://feed/post/tk-6'));
    });
  });

  group('shareFeedPost', () {
    tearDown(() {
      binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('routes through the provided launcher', () async {
      String? sharedText;
      String? sharedSubject;

      final outcome = await shareFeedPost(
        _post(id: 'tk-9', text: 'Guru expands what it touches.'),
        launcher: (String text, String subject) async {
          sharedText = text;
          sharedSubject = subject;
        },
      );

      expect(outcome, FeedShareOutcome.shared);
      expect(sharedText, contains('trikaal://feed/post/tk-9'));
      expect(sharedSubject, 'A post from Trikaal');
    });

    test('falls back to the clipboard when the launcher fails', () async {
      final clipboardCalls = <MethodCall>[];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          clipboardCalls.add(call);
          return null;
        },
      );

      final outcome = await shareFeedPost(
        _post(id: 'tk-9', text: 'Guru expands what it touches.'),
        launcher: (String text, String subject) async {
          throw MissingPluginException('no native side');
        },
      );

      expect(outcome, FeedShareOutcome.copiedToClipboard);
      expect(clipboardCalls, hasLength(1));
      expect(clipboardCalls.single.method, 'Clipboard.setData');
      final arguments = clipboardCalls.single.arguments as Map<dynamic, dynamic>;
      expect(arguments['text'], contains('trikaal://feed/post/tk-9'));
    });

    test('reports failure when the clipboard is also unavailable', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          throw PlatformException(code: 'unavailable');
        },
      );

      final outcome = await shareFeedPost(
        _post(id: 'tk-9', text: 'Guru expands what it touches.'),
        launcher: (String text, String subject) async {
          throw MissingPluginException('no native side');
        },
      );

      expect(outcome, FeedShareOutcome.failed);
    });
  });
}
