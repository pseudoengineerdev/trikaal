import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_report_models.dart';
import 'package:trikaal_mobile/features/feed/data/feed_interactions_repository.dart';
import 'package:trikaal_mobile/features/feed/data/feed_repository.dart';
import 'package:trikaal_mobile/features/feed/data/models/feed_post.dart';
import 'package:trikaal_mobile/features/feed/presentation/state/feed_controller.dart';
import 'package:trikaal_mobile/features/feed/presentation/state/feed_interactions_store.dart';
import 'package:trikaal_mobile/features/feed/presentation/widgets/feed_post_card.dart';
import 'package:trikaal_mobile/features/profile/presentation/profile_page.dart';

import '../../../helpers/sample_report.dart';

class _MemoryFeedInteractionsRepository implements FeedInteractionsRepository {
  _MemoryFeedInteractionsRepository([FeedInteractions? initial])
      : stored = initial ?? const FeedInteractions.empty();

  FeedInteractions stored;

  @override
  Future<FeedInteractions> load() async => stored;

  @override
  Future<void> save(FeedInteractions interactions) async {
    stored = interactions;
  }
}

FeedPost _savedPost(String id, String text) {
  return FeedPost(
    id: id,
    source: FeedPostSource.trikaal,
    authorName: 'Trikaal',
    authorHandle: '@trikaal',
    postedAt: DateTime(2026, 6, 1, 9),
    text: text,
    baseLikeCount: 250,
  );
}

BirthInputState _stateWithReport() {
  final birthInputState = BirthInputState(
    firstName: 'Sahil',
    dateOfBirth: '1999-07-04',
    timeOfBirth: '12:22',
    placeOfBirth: 'Mumbai',
  );
  birthInputState.markReportComputed(
    ComputeReportResponse.fromJson(sampleReportJson()),
  );
  return birthInputState;
}

FeedController _controllerWith(FeedInteractions interactions) {
  return FeedController(
    repository: DummyFeedRepository(
      anchorTime: DateTime(2026, 6, 11, 12),
      simulatedLatency: Duration.zero,
    ),
    interactions: FeedInteractionsStore(
      repository: _MemoryFeedInteractionsRepository(interactions),
    ),
  );
}

void main() {
  group('ProfilePage saved tab', () {
    testWidgets('switches tabs and shows the empty saved state',
        (WidgetTester tester) async {
      final birthInputState = _stateWithReport();
      addTearDown(birthInputState.dispose);
      final controller = _controllerWith(const FeedInteractions.empty());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            birthInputState: birthInputState,
            feedController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chart tab is the default.
      expect(find.text('☉ SUN'), findsOneWidget);

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(
        find.text('Posts you save from the Feed will appear here.'),
        findsOneWidget,
      );
      expect(find.text('Open Feed'), findsOneWidget);
      expect(find.text('☉ SUN'), findsNothing);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings are coming soon.'), findsOneWidget);

      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();
      expect(find.text('☉ SUN'), findsOneWidget);
    });

    testWidgets('renders saved posts and unsaves on bookmark tap',
        (WidgetTester tester) async {
      final birthInputState = _stateWithReport();
      addTearDown(birthInputState.dispose);
      final controller = _controllerWith(
        FeedInteractions(
          likedPostIds: <String>{'tk-2'},
          savedPosts: <FeedPost>[
            _savedPost('tk-2', 'Saved wisdom about Shani.'),
            _savedPost('tk-5', 'Saved note about nakshatras.'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            birthInputState: birthInputState,
            feedController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.byType(FeedPostCard), findsNWidgets(2));
      expect(find.text('Saved wisdom about Shani.'), findsOneWidget);
      expect(find.text('Saved note about nakshatras.'), findsOneWidget);
      // Liked save shows base count + 1.
      expect(find.text('251'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bookmark_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Saved wisdom about Shani.'), findsNothing);
      expect(find.text('Saved note about nakshatras.'), findsOneWidget);
      expect(find.text('Removed from your saved posts.'), findsOneWidget);
      expect(controller.interactions.savedPosts, hasLength(1));
    });
  });
}
