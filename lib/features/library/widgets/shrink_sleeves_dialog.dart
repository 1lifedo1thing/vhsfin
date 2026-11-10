import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/model/sleeve_shrink_status.dart';
import 'package:vhsfin/features/living_room/widgets/deck_panel.dart';

/// Check, confirm, and progress for shrinking server sleeves — props only;
/// the page owns the job.
class ShrinkSleevesDialog extends StatelessWidget {
  const ShrinkSleevesDialog({
    super.key,
    required this.status,
    required this.onShrink,
    required this.onClose,
  });

  final ValueListenable<SleeveShrinkStatus> status;
  final VoidCallback onShrink;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          type: MaterialType.transparency,
          child: DeckPanel(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: ValueListenableBuilder(
              valueListenable: status,
              builder: (context, status, _) => _body(status),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(SleeveShrinkStatus s) {
    final (title, lines, meter) = switch (s.phase) {
      SleeveShrinkPhase.idle || SleeveShrinkPhase.checking => (
        'SHRINK SLEEVES',
        [s.total == 0 ? 'CHECKING…' : 'CHECKING ${s.progress} / ${s.total}'],
        s.fraction,
      ),
      SleeveShrinkPhase.ready => (
        'SHRINK SLEEVES',
        [
          '${s.oversized} of ${s.sleeves} oversized',
          if (s.oversized > 0) formatBytes(s.oversizedBytes),
        ],
        null,
      ),
      SleeveShrinkPhase.running => (
        'SHRINKING SLEEVES',
        ['${s.progress} / ${s.total}'],
        s.fraction,
      ),
      SleeveShrinkPhase.done => (
        'SLEEVES SHRUNK',
        [
          '${s.shrunk} shrunk${s.failed > 0 ? ' · ${s.failed} skipped' : ''}',
          '${formatBytes(s.oversizedBytes)} → ${formatBytes(s.bytesAfter)}',
        ],
        1.0,
      ),
      SleeveShrinkPhase.adminOnly => (
        'SHRINK SLEEVES',
        ['Sign in as a server admin.'],
        null,
      ),
      SleeveShrinkPhase.failed => (
        'SHRINK SLEEVES',
        ["Couldn't reach the server."],
        null,
      ),
    };
    final showMeter =
        s.busy || s.phase == SleeveShrinkPhase.done || s.phase.isIdle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeckSheetHeader(title: title),
        const SizedBox(height: 14),
        if (showMeter) ...[_Meter(value: meter), const SizedBox(height: 10)],
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: TextStyle(
                color: VhsColors.ink.withValues(alpha: 0.75),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        const SizedBox(height: 14),
        ..._keys(s),
      ],
    );
  }

  List<Widget> _keys(SleeveShrinkStatus s) {
    if (s.busy || s.phase.isIdle) {
      return [
        DeckHardKey(
          label: s.phase == SleeveShrinkPhase.running
              ? 'CONTINUE IN BACKGROUND'
              : 'CLOSE',
          onPressed: onClose,
        ),
      ];
    }
    if (s.phase == SleeveShrinkPhase.ready && s.oversized > 0) {
      return [
        Row(
          children: [
            Expanded(
              child: DeckHardKey(label: 'CANCEL', onPressed: onClose),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DeckHardKey(
                label: 'SHRINK',
                tone: DeckKeyTone.record,
                onPressed: onShrink,
              ),
            ),
          ],
        ),
      ];
    }
    return [
      DeckHardKey(label: 'DONE', tone: DeckKeyTone.record, onPressed: onClose),
    ];
  }
}

extension on SleeveShrinkPhase {
  bool get isIdle => this == SleeveShrinkPhase.idle;
}

/// Tape-counter style meter set into the panel; null value is indeterminate.
class _Meter extends StatelessWidget {
  const _Meter({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: const Color(0xFF050607),
        border: Border.all(),
        boxShadow: const [
          BoxShadow(color: Color(0x14FFFFFF), offset: Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 8,
          backgroundColor: const Color(0xFF0C1415),
          color: VhsColors.accent,
        ),
      ),
    );
  }
}
