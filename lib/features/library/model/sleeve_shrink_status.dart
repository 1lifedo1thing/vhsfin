import 'package:flutter/foundation.dart';

enum SleeveShrinkPhase {
  idle,
  checking,
  ready,
  running,
  done,
  adminOnly,
  failed,
}

@immutable
class SleeveShrinkStatus {
  const SleeveShrinkStatus({
    this.phase = SleeveShrinkPhase.idle,
    this.progress = 0,
    this.total = 0,
    this.sleeves = 0,
    this.oversized = 0,
    this.oversizedBytes = 0,
    this.shrunk = 0,
    this.failed = 0,
    this.bytesAfter = 0,
  });

  final SleeveShrinkPhase phase;

  /// Items checked (checking) or oversized sleeves processed (running).
  final int progress;
  final int total;

  /// Box images on the server.
  final int sleeves;
  final int oversized;
  final int oversizedBytes;
  final int shrunk;
  final int failed;

  /// Stored size of the oversized sleeves so far: new size if shrunk,
  /// original if skipped.
  final int bytesAfter;

  bool get busy =>
      phase == SleeveShrinkPhase.checking || phase == SleeveShrinkPhase.running;

  double? get fraction => total == 0 ? null : progress / total;

  SleeveShrinkStatus copyWith({
    SleeveShrinkPhase? phase,
    int? progress,
    int? total,
    int? sleeves,
    int? oversized,
    int? oversizedBytes,
    int? shrunk,
    int? failed,
    int? bytesAfter,
  }) => SleeveShrinkStatus(
    phase: phase ?? this.phase,
    progress: progress ?? this.progress,
    total: total ?? this.total,
    sleeves: sleeves ?? this.sleeves,
    oversized: oversized ?? this.oversized,
    oversizedBytes: oversizedBytes ?? this.oversizedBytes,
    shrunk: shrunk ?? this.shrunk,
    failed: failed ?? this.failed,
    bytesAfter: bytesAfter ?? this.bytesAfter,
  );
}

/// "175.3 MB" / "820 KB".
String formatBytes(int bytes) => bytes >= 1000000
    ? '${(bytes / 1000000).toStringAsFixed(1)} MB'
    : '${(bytes / 1000).round()} KB';
