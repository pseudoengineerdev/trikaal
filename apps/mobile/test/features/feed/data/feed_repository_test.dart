import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/feed/data/feed_repository.dart';
import 'package:trikaal_mobile/features/feed/data/models/feed_post.dart';

void main() {
  group('DummyFeedRepository', () {
    DummyFeedRepository buildRepository() {
      return DummyFeedRepository(
        anchorTime: DateTime(2026, 6, 11, 12),
        simulatedLatency: Duration.zero,
      );
    }

    test('fetchPage returns sequential unique posts', () async {
      final repository = buildRepository();

      final firstPage = await repository.fetchPage(page: 0, pageSize: 8);
      final secondPage = await repository.fetchPage(page: 1, pageSize: 8);

      expect(firstPage, hasLength(8));
      expect(secondPage, hasLength(8));

      final ids = <String>{
        ...firstPage.map((FeedPost post) => post.id),
        ...secondPage.map((FeedPost post) => post.id),
      };
      expect(ids, hasLength(16));
      expect(firstPage.first.id, 'tk-0');
      expect(secondPage.first.id, 'tk-8');
    });

    test('fetchPage is deterministic across calls', () async {
      final repository = buildRepository();

      final once = await repository.fetchPage(page: 3, pageSize: 5);
      final twice = await repository.fetchPage(page: 3, pageSize: 5);

      for (var i = 0; i < once.length; i++) {
        expect(once[i].id, twice[i].id);
        expect(once[i].text, twice[i].text);
        expect(once[i].baseLikeCount, twice[i].baseLikeCount);
        expect(once[i].postedAt, twice[i].postedAt);
      }
    });

    test('fetchPostById matches the post served in a page', () async {
      final repository = buildRepository();

      final page = await repository.fetchPage(page: 2, pageSize: 4);
      final target = page[1];
      final fetched = await repository.fetchPostById(target.id);

      expect(fetched, isNotNull);
      expect(fetched!.id, target.id);
      expect(fetched.text, target.text);
      expect(fetched.baseLikeCount, target.baseLikeCount);
      expect(fetched.source, target.source);
    });

    test('fetchPostById rejects unknown ids', () async {
      final repository = buildRepository();

      expect(await repository.fetchPostById('unknown-9'), isNull);
      expect(await repository.fetchPostById('tk-abc'), isNull);
      expect(await repository.fetchPostById('tk--4'), isNull);
    });

    test('feed is effectively infinite', () async {
      final repository = buildRepository();

      final deepPage = await repository.fetchPage(page: 5000, pageSize: 10);

      expect(deepPage, hasLength(10));
      expect(deepPage.first.id, 'tk-50000');
      expect(deepPage.first.text, isNotEmpty);
    });

    test('timeline runs backwards in time', () async {
      final repository = buildRepository();

      final page = await repository.fetchPage(page: 0, pageSize: 6);
      for (var i = 1; i < page.length; i++) {
        expect(page[i].postedAt.isBefore(page[i - 1].postedAt), isTrue);
      }
    });
  });
}
