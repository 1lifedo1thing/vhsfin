enum TapeKind { movie, series, episode }

/// A playable or browsable "tape" — movie, series box, or episode.
class Tape {
  const Tape({
    required this.id,
    required this.title,
    required this.streamUrl,
    this.subtitle,
    this.imageUrl,
    this.boxImageUrl,
    this.duration,
    this.isDemo = false,
    this.kind = TapeKind.movie,
    this.seriesId,
    this.libraryId,
    this.libraryName,
    this.productionYear,
    this.episodeCount,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String streamUrl;
  final String? imageUrl;

  /// Jellyfin `Box` image (VHS sleeve scan), when the library already has one.
  final String? boxImageUrl;
  final Duration? duration;
  final bool isDemo;
  final TapeKind kind;
  final String? seriesId;
  final String? libraryId;
  final String? libraryName;
  final int? productionYear;
  final int? episodeCount;

  bool get isPlayable => kind != TapeKind.series;

  bool get hasBoxImage => boxImageUrl != null && boxImageUrl!.isNotEmpty;

  Tape copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? streamUrl,
    String? imageUrl,
    String? boxImageUrl,
    Duration? duration,
    bool? isDemo,
    TapeKind? kind,
    String? seriesId,
    String? libraryId,
    String? libraryName,
    int? productionYear,
    int? episodeCount,
  }) {
    return Tape(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      streamUrl: streamUrl ?? this.streamUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      boxImageUrl: boxImageUrl ?? this.boxImageUrl,
      duration: duration ?? this.duration,
      isDemo: isDemo ?? this.isDemo,
      kind: kind ?? this.kind,
      seriesId: seriesId ?? this.seriesId,
      libraryId: libraryId ?? this.libraryId,
      libraryName: libraryName ?? this.libraryName,
      productionYear: productionYear ?? this.productionYear,
      episodeCount: episodeCount ?? this.episodeCount,
    );
  }
}

/// Public samples used when Jellyfin isn't connected yet.
const demoTapes = <Tape>[
  Tape(
    id: 'demo-bbb',
    title: 'Big Buck Bunny',
    subtitle: 'Demo reel',
    streamUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    duration: Duration(minutes: 9, seconds: 56),
    isDemo: true,
  ),
  Tape(
    id: 'demo-elephants',
    title: 'Elephant Dream',
    subtitle: 'Demo reel',
    streamUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    duration: Duration(minutes: 10, seconds: 53),
    isDemo: true,
  ),
  Tape(
    id: 'demo-sintel',
    title: 'Sintel',
    subtitle: 'Demo reel',
    streamUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    duration: Duration(minutes: 14, seconds: 48),
    isDemo: true,
  ),
];
