/// A playable "tape" — one Jellyfin item (or demo stand-in).
class Tape {
  const Tape({
    required this.id,
    required this.title,
    required this.streamUrl,
    this.subtitle,
    this.imageUrl,
    this.duration,
    this.isDemo = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String streamUrl;
  final String? imageUrl;
  final Duration? duration;
  final bool isDemo;

  Tape copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? streamUrl,
    String? imageUrl,
    Duration? duration,
    bool? isDemo,
  }) {
    return Tape(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      streamUrl: streamUrl ?? this.streamUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
      isDemo: isDemo ?? this.isDemo,
    );
  }
}

/// Public sample used when Jellyfin isn't connected yet.
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
