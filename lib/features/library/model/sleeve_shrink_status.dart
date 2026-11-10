import 'package:flutter/foundation.dart';

enum SleeveShrinkPhase { idle, checking, running, done, adminOnly, failed }

@immutable
class SleeveShrinkStatus {
  const SleeveShrinkStatus({
    this.phase = SleeveShrinkPhase.idle,
    this.checked = 0,
    this.total = 0,
    this.shrunk = 0,
  });

  final SleeveShrinkPhase phase;
  final int checked;
  final int total;
  final int shrunk;

  bool get busy =>
      phase == SleeveShrinkPhase.checking || phase == SleeveShrinkPhase.running;
}
