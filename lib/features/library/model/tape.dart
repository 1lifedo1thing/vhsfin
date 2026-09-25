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
    this.seriesTitle,
    this.seasonNumber,
    this.libraryId,
    this.libraryName,
    this.productionYear,
    this.episodeCount,
    this.overview,
    this.genres = const [],
    this.communityRating,
    this.officialRating,
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

  /// Parent series name — used for season-level sleeve lookup on episodes.
  final String? seriesTitle;

  /// Jellyfin season index (`ParentIndexNumber`) when [kind] is episode.
  final int? seasonNumber;
  final String? libraryId;
  final String? libraryName;
  final int? productionYear;
  final int? episodeCount;
  final String? overview;
  final List<String> genres;
  final double? communityRating;
  final String? officialRating;

  bool get isPlayable => kind != TapeKind.series;

  bool get hasBoxImage => boxImageUrl != null && boxImageUrl!.isNotEmpty;

  /// Family providers key on [id] so shelf + preview share spine art.
  @override
  bool operator ==(Object other) => other is Tape && other.id == id;

  @override
  int get hashCode => id.hashCode;

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
    String? seriesTitle,
    int? seasonNumber,
    String? libraryId,
    String? libraryName,
    int? productionYear,
    int? episodeCount,
    String? overview,
    List<String>? genres,
    double? communityRating,
    String? officialRating,
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
      seriesTitle: seriesTitle ?? this.seriesTitle,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      libraryId: libraryId ?? this.libraryId,
      libraryName: libraryName ?? this.libraryName,
      productionYear: productionYear ?? this.productionYear,
      episodeCount: episodeCount ?? this.episodeCount,
      overview: overview ?? this.overview,
      genres: genres ?? this.genres,
      communityRating: communityRating ?? this.communityRating,
      officialRating: officialRating ?? this.officialRating,
    );
  }
}

/// Build-time switch: `--dart-define=VHSFIN_DEMO=true` fills the shelves with
/// open-licensed sample films when no Jellyfin server is connected. Used for
/// local design work and screenshots without an account.
const vhsfinDemoMode = bool.fromEnvironment('VHSFIN_DEMO');

const _gtv =
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample';

Tape _demo(
  String id,
  String title,
  String file,
  int year,
  Duration duration,
  List<String> genres,
  String overview,
) => Tape(
  id: 'demo-$id',
  title: title,
  subtitle: 'Open movie',
  streamUrl: '$_gtv/$file',
  duration: duration,
  productionYear: year,
  genres: genres,
  overview: overview,
  libraryName: 'Demo shelf',
  isDemo: true,
);

/// Public, openly licensed samples for [vhsfinDemoMode].
final demoTapes = <Tape>[
  _demo(
    'bbb',
    'Big Buck Bunny',
    'BigBuckBunny.mp4',
    2008,
    const Duration(minutes: 9, seconds: 56),
    ['Animation', 'Comedy'],
    'A gentle giant rabbit takes a stand against three bullying rodents.',
  ),
  _demo(
    'elephants',
    'Elephants Dream',
    'ElephantsDream.mp4',
    2006,
    const Duration(minutes: 10, seconds: 53),
    ['Animation', 'Sci-Fi'],
    'Two strangers wander an endless machine that answers to neither of them.',
  ),
  _demo(
    'sintel',
    'Sintel',
    'Sintel.mp4',
    2010,
    const Duration(minutes: 14, seconds: 48),
    ['Animation', 'Fantasy'],
    'A lone warrior searches the frozen north for the baby dragon she raised.',
  ),
  _demo(
    'tears',
    'Tears of Steel',
    'TearsOfSteel.mp4',
    2012,
    const Duration(minutes: 12, seconds: 14),
    ['Sci-Fi', 'Action'],
    'A band of scientists restage a breakup in Amsterdam to save the world.',
  ),
  for (final (id, title, file) in const [
    ('blazes', 'For Bigger Blazes', 'ForBiggerBlazes.mp4'),
    ('escapes', 'For Bigger Escapes', 'ForBiggerEscapes.mp4'),
    ('fun', 'For Bigger Fun', 'ForBiggerFun.mp4'),
    ('joyrides', 'For Bigger Joyrides', 'ForBiggerJoyrides.mp4'),
    ('meltdowns', 'For Bigger Meltdowns', 'ForBiggerMeltdowns.mp4'),
  ])
    _demo(id, title, file, 2013, const Duration(seconds: 15), [
      'Short',
    ], 'A fifteen-second sample reel.'),
  _demo(
    'bullrun',
    'We Are Going on Bullrun',
    'WeAreGoingOnBullrun.mp4',
    2013,
    const Duration(seconds: 47),
    ['Documentary'],
    'A road-rally sample reel.',
  ),
];
