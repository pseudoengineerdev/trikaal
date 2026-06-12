import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/features/feed/data/feed_interactions_repository.dart';
import 'package:trikaal_mobile/features/feed/data/models/feed_post.dart';

FeedPost _post(String id) {
  return FeedPost(
    id: id,
    source: FeedPostSource.trikaal,
    authorName: 'Trikaal',
    authorHandle: '@trikaal',
    postedAt: DateTime(2026, 6, 1, 9, 30),
    text: 'Moon first, always.',
    baseLikeCount: 120,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesFeedInteractionsRepository', () {
    test('returns empty interactions when nothing stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = SharedPreferencesFeedInteractionsRepository();

      final interactions = await repository.load();

      expect(interactions.likedPostIds, isEmpty);
      expect(interactions.savedPosts, isEmpty);
    });

    test('round-trips likes and saved posts', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = SharedPreferencesFeedInteractionsRepository();

      await repository.save(
        FeedInteractions(
          likedPostIds: <String>{'tk-1', 'tk-4'},
          savedPosts: <FeedPost>[_post('tk-4'), _post('tk-2')],
        ),
      );

      final reloaded = await SharedPreferencesFeedInteractionsRepository().load();

      expect(reloaded.likedPostIds, <String>{'tk-1', 'tk-4'});
      expect(
        reloaded.savedPosts.map((FeedPost post) => post.id).toList(),
        <String>['tk-4', 'tk-2'],
      );
      expect(reloaded.savedPosts.first.text, 'Moon first, always.');
      expect(reloaded.savedPosts.first.baseLikeCount, 120);
    });

    test('ignores malformed stored payloads', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'trikaal_feed_interactions_v1': 'not-json',
      });
      final repository = SharedPreferencesFeedInteractionsRepository();

      final interactions = await repository.load();

      expect(interactions.likedPostIds, isEmpty);
      expect(interactions.savedPosts, isEmpty);
    });
  });
}
