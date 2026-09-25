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

/// Wikimedia Commons 480p transcodes of the Blender Foundation open movies
/// (CC BY). VP9/WebM plays in every current browser and in media_kit.
const _commons = 'https://upload.wikimedia.org/wikipedia/commons/transcoded';

Tape _demo(
  String id,
  String title,
  String path,
  int year,
  Duration duration,
  List<String> genres,
  String overview,
) => Tape(
  id: 'demo-$id',
  title: title,
  subtitle: 'Blender open movie',
  streamUrl: '$_commons/$path.480p.vp9.webm',
  duration: duration,
  productionYear: year,
  genres: genres,
  overview: overview,
  libraryName: 'Demo shelf',
  isDemo: true,
);

/// Public, openly licensed films for [vhsfinDemoMode].
final demoTapes = <Tape>[
  _demo(
    'bbb',
    'Big Buck Bunny',
    'c/c0/Big_Buck_Bunny_4K.webm/Big_Buck_Bunny_4K.webm',
    2008,
    const Duration(minutes: 9, seconds: 56),
    ['Animation', 'Comedy'],
    'A gentle giant rabbit takes a stand against three bullying rodents.',
  ),
  _demo(
    'elephants',
    'Elephants Dream',
    'a/a2/Elephants_Dream_%282006%29.webm/Elephants_Dream_%282006%29.webm',
    2006,
    const Duration(minutes: 10, seconds: 54),
    ['Animation', 'Sci-Fi'],
    'Two strangers wander an endless machine that answers to neither of them.',
  ),
  _demo(
    'sintel',
    'Sintel',
    'f/f1/Sintel_movie_4K.webm/Sintel_movie_4K.webm',
    2010,
    const Duration(minutes: 14, seconds: 48),
    ['Animation', 'Fantasy'],
    'A lone warrior searches the frozen north for the baby dragon she raised.',
  ),
  _demo(
    'tears',
    'Tears of Steel',
    'c/cb/Tears_of_Steel_1080p.webm/Tears_of_Steel_1080p.webm',
    2012,
    const Duration(minutes: 12, seconds: 14),
    ['Sci-Fi', 'Action'],
    'A band of scientists restage a breakup in Amsterdam to save the world.',
  ),
  _demo(
    'cosmos',
    'Cosmos Laundromat',
    '3/36/Cosmos_Laundromat_-_First_Cycle_-_Official_Blender_Foundation_release.webm/'
        'Cosmos_Laundromat_-_First_Cycle_-_Official_Blender_Foundation_release.webm',
    2015,
    const Duration(minutes: 12, seconds: 10),
    ['Animation', 'Comedy'],
    'A fed-up sheep meets a salesman who offers him a lifetime of lives.',
  ),
  _demo(
    'caminandes',
    'Caminandes: Llama Drama',
    'd/d0/Caminandes-_Llama_Drama_-_Short_Movie.ogv/'
        'Caminandes-_Llama_Drama_-_Short_Movie.ogv',
    2013,
    const Duration(minutes: 1, seconds: 30),
    ['Animation', 'Short'],
    'Koro the llama wants to get to the other side of a fenced road.',
  ),
  _demo(
    'spring',
    'Spring',
    'a/a5/Spring_-_Blender_Open_Movie.webm/Spring_-_Blender_Open_Movie.webm',
    2019,
    const Duration(minutes: 7, seconds: 44),
    ['Animation', 'Fantasy'],
    'A shepherd girl and her dog face ancient spirits to keep the seasons turning.',
  ),
];
