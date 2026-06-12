import 'models/feed_post.dart';

abstract class FeedRepository {
  Future<List<FeedPost>> fetchPage({required int page, required int pageSize});

  Future<FeedPost?> fetchPostById(String postId);
}

class _FeedPostTemplate {
  const _FeedPostTemplate({
    required this.text,
    required this.source,
    this.imageAsset,
  });

  final String text;
  final FeedPostSource source;
  final String? imageAsset;
}

/// Local placeholder feed until Trikaal's own publishing backend (or an
/// Instagram / X sync) is wired in. Posts are generated deterministically
/// from their index so any page — and any post id arriving through a shared
/// link — resolves to the same content.
class DummyFeedRepository implements FeedRepository {
  DummyFeedRepository({
    DateTime? anchorTime,
    Duration simulatedLatency = const Duration(milliseconds: 400),
  })  : _anchorTime = anchorTime ?? DateTime.now(),
        _simulatedLatency = simulatedLatency;

  static const String _idPrefix = 'tk-';
  static const String authorName = 'Trikaal';
  static const String authorHandle = '@trikaal';

  final DateTime _anchorTime;
  final Duration _simulatedLatency;

  static const List<_FeedPostTemplate> _templates = <_FeedPostTemplate>[
    _FeedPostTemplate(
      source: FeedPostSource.trikaal,
      text:
          'Your Sun sign is the headline, but your Moon nakshatra is the '
          'story. Vedic astrology reads the Moon first because the mind '
          'moves with it — check where Chandra sits in your chart before '
          'judging your day. 🌙\n\n#VedicAstrology #Nakshatra #MoonSign',
      imageAsset: 'assets/feature_cards/birth_chart_bg.png',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.instagram,
      text:
          'Shani does not punish. Shani teaches. The houses Saturn touches '
          'in your chart are where life asks for patience, structure, and '
          'honest work — and where the most durable rewards wait. 🪐\n\n'
          '#Shani #Saturn #Jyotish',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.twitter,
      text:
          'Rahu shows what you crave. Ketu shows what you already mastered '
          'in a past chapter. The axis between them is the tug-of-war your '
          'whole chart is trying to resolve.\n\n#RahuKetu #VedicAstrology',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.trikaal,
      text:
          'Budha vakri (Mercury retrograde) is not the apocalypse — it is a '
          'review period. Re-read the contract, re-send the message, '
          're-think the plan. The prefix is "re" for a reason. ☿',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.instagram,
      text:
          'A strong Guru (Jupiter) in the 5th house blesses learning, '
          'children, and the courage to create. Find your Guru\'s house in '
          'the Trikaal birth chart and see which part of life it expands. ✨'
          '\n\n#Guru #Jupiter #BirthChart',
      imageAsset: 'assets/feature_cards/hindu_calendar_bg.png',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.twitter,
      text:
          'Ekadashi reminder: the 11th tithi is for lightening the load — '
          'lighter food, lighter thoughts, lighter grudges. Your Hindu '
          'calendar inside Trikaal tracks every tithi for your city. 🗓️',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.trikaal,
      text:
          'Mangal energy check: Mars in your chart shows how you fight, '
          'and what is worth fighting for. Misplaced, it burns. Directed, '
          'it builds. Where is your Mangal? ♂️\n\n#Mangal #Mars #Jyotish',
      imageAsset: 'assets/feature_cards/mangal_dosh_bg.png',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.instagram,
      text:
          'Nakshatra spotlight: Ashwini — the celestial healers. Quick to '
          'start, quick to help, quick to leave when the spark fades. If '
          'your Moon rides Ashwini, speed is your medicine and your trap. 🐎',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.twitter,
      text:
          'Lagna is the body, Moon is the mind, Sun is the soul. Reading '
          'only your Sun sign is reading one page of a three-page letter.\n\n'
          '#Lagna #VedicAstrology #SignTrio',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.trikaal,
      text:
          'Shukra (Venus) rules what you find beautiful — and what finds '
          'you beautiful. Compatibility is not one number; it is the '
          'conversation between two charts. See yours in Soulmate. 💞\n\n'
          '#Shukra #Venus #Compatibility',
      imageAsset: 'assets/feature_cards/soulmate_bg.png',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.instagram,
      text:
          'Your Mahadasha sets the chapter; the Antardasha writes the '
          'paragraph. If life suddenly changed tone, check which dasha '
          'lord took the pen. 📖\n\n#Dasha #Vimshottari #Jyotish',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.twitter,
      text:
          'Kaal Sarpa is one of the most feared — and most misunderstood — '
          'yogas. Having all grahas between Rahu and Ketu is intensity, '
          'not doom. Intensity, well-channelled, is achievement.',
      imageAsset: 'assets/feature_cards/kaal_sarpa_dosh_bg.png',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.trikaal,
      text:
          'Pancha Pakshi: five birds, five activities, one of them ruling '
          'every moment of your day. The ancients timed journeys, deals, '
          'and rest by it. Trikaal computes your bird live. 🦚\n\n'
          '#PanchaPakshi #Muhurta',
      imageAsset: 'assets/feature_cards/pancha_pakshi_bg.png',
    ),
    _FeedPostTemplate(
      source: FeedPostSource.instagram,
      text:
          'Purnima nights amplify the Moon — and every Moon-ruled corner '
          'of your chart. Notice what swells in you on a full Moon; that '
          'is Chandra showing you where your tides live. 🌕\n\n'
          '#Purnima #FullMoon #Chandra',
    ),
  ];

  static String idForIndex(int index) => '$_idPrefix$index';

  static int? _indexFromId(String postId) {
    if (!postId.startsWith(_idPrefix)) {
      return null;
    }
    final index = int.tryParse(postId.substring(_idPrefix.length));
    if (index == null || index < 0) {
      return null;
    }
    return index;
  }

  FeedPost _buildPost(int index) {
    final template = _templates[index % _templates.length];
    // Spread posts back in time so the feed reads like a real timeline.
    final postedAt = _anchorTime.subtract(
      Duration(hours: 7 * index + (index * index) % 5, minutes: (index * 17) % 60),
    );
    final baseLikeCount = 96 + ((index * 137) % 23) * 67 + (index % 7) * 13;
    return FeedPost(
      id: idForIndex(index),
      source: template.source,
      authorName: authorName,
      authorHandle: authorHandle,
      postedAt: postedAt,
      text: template.text,
      baseLikeCount: baseLikeCount,
      imageAsset: template.imageAsset,
    );
  }

  @override
  Future<List<FeedPost>> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    if (_simulatedLatency > Duration.zero) {
      await Future<void>.delayed(_simulatedLatency);
    }
    final start = page * pageSize;
    return List<FeedPost>.generate(
      pageSize,
      (int offset) => _buildPost(start + offset),
    );
  }

  @override
  Future<FeedPost?> fetchPostById(String postId) async {
    if (_simulatedLatency > Duration.zero) {
      await Future<void>.delayed(_simulatedLatency);
    }
    final index = _indexFromId(postId);
    if (index == null) {
      return null;
    }
    return _buildPost(index);
  }
}
