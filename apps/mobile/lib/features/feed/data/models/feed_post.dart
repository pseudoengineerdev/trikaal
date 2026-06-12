enum FeedPostSource { trikaal, instagram, twitter }

FeedPostSource feedPostSourceFromName(String? rawName) {
  for (final source in FeedPostSource.values) {
    if (source.name == rawName) {
      return source;
    }
  }
  return FeedPostSource.trikaal;
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.source,
    required this.authorName,
    required this.authorHandle,
    required this.postedAt,
    required this.text,
    required this.baseLikeCount,
    this.imageAsset,
  });

  final String id;
  final FeedPostSource source;
  final String authorName;
  final String authorHandle;
  final DateTime postedAt;
  final String text;
  final int baseLikeCount;
  final String? imageAsset;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'source': source.name,
      'authorName': authorName,
      'authorHandle': authorHandle,
      'postedAt': postedAt.toIso8601String(),
      'text': text,
      'baseLikeCount': baseLikeCount,
      if (imageAsset != null) 'imageAsset': imageAsset,
    };
  }

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: (json['id'] ?? '').toString(),
      source: feedPostSourceFromName(json['source']?.toString()),
      authorName: (json['authorName'] ?? '').toString(),
      authorHandle: (json['authorHandle'] ?? '').toString(),
      postedAt: DateTime.tryParse((json['postedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      text: (json['text'] ?? '').toString(),
      baseLikeCount: switch (json['baseLikeCount']) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
      imageAsset: json['imageAsset']?.toString(),
    );
  }
}
