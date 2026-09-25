import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vhsfin/features/living_room/widgets/cabinet_material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/data/vhs_image_cache.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/widgets/crt_loading_indicator.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';

/// Jellyfin Box sleeves already on the [Tape] — no network lookup required.
Map<String, VhsSpineArt?> immediateBoxSpineArts(Iterable<Tape> tapes) {
  return {
    for (final tape in tapes)
      if (tape.hasBoxImage)
        tape.id: VhsSpineArt(
          imageUrl: tape.boxImageUrl!,
          centerWidthFraction: VhsCoverResolver.wraparoundSpineFraction,
        ),
  };
}

/// Bookshelf content — props only; page owns Riverpod.
class BookshelfView extends StatelessWidget {
  const BookshelfView({
    super.key,
    required this.shelves,
    required this.loadedId,
    required this.loadedSeriesId,
    required this.vhsOnly,
    required this.flightAnchors,
    required this.flyingTapeId,
    required this.flightSourceKey,
    required this.resolveSpineArt,
    required this.onTapeTap,
    this.embedded = false,
    this.onConnectPrompt,
  });

  /// When true, sits inside the wooden entertainment center.
  final bool embedded;
  final List<Shelf> shelves;
  final String? loadedId;
  final String? loadedSeriesId;
  final bool vhsOnly;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final void Function(Tape tape, String instanceKey) onTapeTap;
  final VoidCallback? onConnectPrompt;

  @override
  Widget build(BuildContext context) {
    if (shelves.isEmpty) {
      return const Text('No tapes on these shelves yet.');
    }
    return Column(
      children: [
        for (var i = 0; i < shelves.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _ShelfBlock(
            shelf: shelves[i],
            loadedId: loadedId,
            loadedSeriesId: loadedSeriesId,
            embedded: embedded,
            showTitle: !embedded || shelves.length > 1,
            vhsOnly: vhsOnly,
            flightAnchors: flightAnchors,
            flyingTapeId: flyingTapeId,
            flightSourceKey: flightSourceKey,
            resolveSpineArt: resolveSpineArt,
            onTapeTap: onTapeTap,
            onConnectPrompt: onConnectPrompt,
          ),
        ],
      ],
    );
  }
}

class _ShelfBlock extends StatelessWidget {
  const _ShelfBlock({
    required this.shelf,
    required this.loadedId,
    required this.loadedSeriesId,
    required this.embedded,
    required this.showTitle,
    required this.vhsOnly,
    required this.flightAnchors,
    required this.flyingTapeId,
    required this.flightSourceKey,
    required this.resolveSpineArt,
    required this.onTapeTap,
    this.onConnectPrompt,
  });

  final Shelf shelf;
  final String? loadedId;
  final String? loadedSeriesId;
  final bool embedded;
  final bool showTitle;
  final bool vhsOnly;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final void Function(Tape tape, String instanceKey) onTapeTap;
  final VoidCallback? onConnectPrompt;

  /// Pack at upright spine thickness + a hair of air between tapes.
  static const _spineGap = 2.0;
  static const _spineSlotWidth = VhsSpine.nominalWidth + _spineGap;
  // Room for upright spines + lean slack inside the bay.
  static const _rowHeight = 192.0;
  static const _lipHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              shelf.title,
              style: vhsBrandStyle(size: 13).copyWith(letterSpacing: 2),
            ),
          ),
        if (shelf.items.isEmpty)
          _shelfBay(
            child: _EmptyShelfPrompt(
              shelfId: shelf.id,
              vhsOnly: vhsOnly,
              onConnectPrompt: onConnectPrompt,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Inner cavity width after horizontal padding.
              const padH = 20.0;
              final inner = (constraints.maxWidth - padH).clamp(1.0, 4000.0);
              final perRow = (inner / _spineSlotWidth).floor().clamp(1, 100);
              final rows = <List<Tape>>[];
              for (var i = 0; i < shelf.items.length; i += perRow) {
                final end = (i + perRow < shelf.items.length)
                    ? i + perRow
                    : shelf.items.length;
                rows.add(shelf.items.sublist(i, end));
              }

              return _ShelfArtReveal(
                tapes: shelf.items,
                resolveSpineArt: resolveSpineArt,
                builder: (arts) => Column(
                  children: [
                    for (var r = 0; r < rows.length; r++) ...[
                      if (r > 0) const SizedBox(height: 10),
                      _shelfBay(
                        row: r,
                        child: _ShelfTapeRow(
                          shelfId: shelf.id,
                          rowIndex: r,
                          tapes: rows[r],
                          arts: arts,
                          loadedId: loadedId,
                          loadedSeriesId: loadedSeriesId,
                          gap: _spineGap,
                          flightAnchors: flightAnchors,
                          flyingTapeId: flyingTapeId,
                          flightSourceKey: flightSourceKey,
                          onTap: onTapeTap,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  /// Cavity + lip as one unit so spine bases sit on the wood edge.
  Widget _shelfBay({required Widget child, int row = 0}) {
    // Different wood for each bay and its lip; stable across rebuilds.
    final seed = (shelf.id.hashCode + row * 7919) & 0x7fffffff;
    Alignment grain(int salt) => Alignment(
      ((seed >> salt) % 200) / 100 - 1,
      ((seed >> (salt + 5)) % 200) / 100 - 1,
    );
    return SizedBox(
      height: _rowHeight + _lipHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: _lipHeight,
            child: CabinetPanel(
              recessed: true,
              grain: grain(0),
              child: Padding(
                // No bottom pad — spines rest on the cavity floor / lip seam.
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                child: child,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _lipHeight,
            child: CabinetLedge(height: _lipHeight, grain: grain(3)),
          ),
        ],
      ),
    );
  }
}

/// Intentional empty bay — readable copy over ghost tape silhouettes.
class _EmptyShelfPrompt extends StatelessWidget {
  const _EmptyShelfPrompt({
    required this.shelfId,
    required this.vhsOnly,
    this.onConnectPrompt,
  });

  final String shelfId;
  final bool vhsOnly;
  final VoidCallback? onConnectPrompt;

  @override
  Widget build(BuildContext context) {
    final isConnect = shelfId == 'connect';
    final title = isConnect
        ? 'Connect to load your tapes'
        : shelfId == 'empty'
        ? 'Make room for your favorites'
        : vhsOnly
        ? 'No VHS titles on this shelf'
        : 'Empty shelf';
    final subtitle = isConnect
        ? 'Tap to connect your Jellyfin server'
        : shelfId == 'empty'
        ? 'Tap to choose your shelves'
        : vhsOnly
        ? 'Turn off VHS-only in Settings to see all your titles.'
        : null;

    final content = Stack(
      alignment: Alignment.center,
      children: [
        const Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          height: 148,
          child: _GhostSpineRow(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: VhsColors.ink.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: vhsBrandStyle(size: 15).copyWith(
                      color: VhsColors.ink.withValues(alpha: 0.92),
                      letterSpacing: 1.4,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: VhsColors.accent.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if ((!isConnect && shelfId != 'empty') || onConnectPrompt == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onConnectPrompt,
        borderRadius: BorderRadius.circular(4),
        hoverColor: VhsColors.accent.withValues(alpha: 0.06),
        splashColor: VhsColors.accent.withValues(alpha: 0.12),
        child: content,
      ),
    );
  }
}

/// Faint empty spine silhouettes so a vacant bay still reads as a shelf.
class _GhostSpineRow extends StatelessWidget {
  const _GhostSpineRow();

  static const _widths = <double>[
    18,
    16,
    20,
    15,
    18,
    17,
    19,
    16,
    18,
    15,
    20,
    17,
    16,
    18,
    19,
    15,
    17,
    18,
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _widths.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              flex: (_widths[i] * 10).round(),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 118 + (i % 3) * 6.0,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.035),
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Holds the shelf at opacity 0 until every tape's sleeve bytes are warmed,
/// then fades the whole bay in together.
class _ShelfArtReveal extends StatefulWidget {
  const _ShelfArtReveal({
    required this.tapes,
    required this.resolveSpineArt,
    required this.builder,
  });

  final List<Tape> tapes;
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final Widget Function(Map<String, VhsSpineArt?> arts) builder;

  @override
  State<_ShelfArtReveal> createState() => _ShelfArtRevealState();
}

class _ShelfArtRevealState extends State<_ShelfArtReveal> {
  static const _fade = Duration(milliseconds: 520);
  static const _budget = Duration(seconds: 12);

  var _visible = false;
  String? _warmKey;
  int _warmGen = 0;
  Timer? _budgetTimer;
  Map<String, VhsSpineArt?> _arts = const {};

  @override
  void initState() {
    super.initState();
    _scheduleWarm();
  }

  @override
  void dispose() {
    _budgetTimer?.cancel();
    _warmGen++;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ShelfArtReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tapeKey(oldWidget.tapes) != _tapeKey(widget.tapes)) {
      // Sync before the follow-up build so we never paint one frame of the
      // previous (or next) shelf at full opacity.
      _visible = false;
      _budgetTimer?.cancel();
      _budgetTimer = null;
      _scheduleWarm();
    }
  }

  String _tapeKey(List<Tape> tapes) => tapes.map((t) => t.id).join('|');

  void _scheduleWarm() {
    final key = _tapeKey(widget.tapes);
    _warmKey = key;
    final gen = ++_warmGen;
    // Seed known Jellyfin Box sleeves while the bay stays hidden, so a budget
    // timeout still fades in real spines together — not a procedural stampede.
    _arts = immediateBoxSpineArts(widget.tapes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _warmGen) return;
      _warm(key, gen);
    });
  }

  Future<void> _warm(String key, int gen) async {
    try {
      await Future.any<void>([
        _prefetch(widget.tapes, gen: gen, key: key),
        _budgetGate(),
      ]);
    } catch (_) {
      // Still reveal — procedural spines / errors shouldn't trap the bay.
    } finally {
      _budgetTimer?.cancel();
      _budgetTimer = null;
    }
    if (!mounted || gen != _warmGen || _warmKey != key) return;
    // One opacity fade for the whole bay — never drip-feed spine swaps.
    setState(() => _visible = true);
  }

  Future<void> _budgetGate() {
    _budgetTimer?.cancel();
    final gate = Completer<void>();
    _budgetTimer = Timer(_budget, gate.complete);
    return gate.future;
  }

  Future<void> _prefetch(
    List<Tape> tapes, {
    required int gen,
    required String key,
  }) async {
    if (tapes.isEmpty) return;

    final arts = await Future.wait(tapes.map(widget.resolveSpineArt));
    if (!mounted || gen != _warmGen || _warmKey != key || _visible) return;

    final byId = <String, VhsSpineArt?>{
      // Keep Box seeds if a resolve returns null (e.g. reject suppress).
      ...immediateBoxSpineArts(tapes),
    };
    final urls = <String>{};
    for (var i = 0; i < tapes.length; i++) {
      final art = arts[i] ?? byId[tapes[i].id];
      byId[tapes[i].id] = art;
      if (art != null) {
        urls.add(art.imageUrl);
        final front = art.frontImageUrl;
        if (front != null && front.isNotEmpty) urls.add(front);
      } else {
        final poster = tapes[i].imageUrl;
        if (poster != null && poster.isNotEmpty) urls.add(poster);
      }
    }

    if (urls.isNotEmpty) {
      // Warm bytes before committing arts so the fade-in isn't a drip of
      // CachedNetworkImage placeholders. If the budget wins first, we keep the
      // Box seed snapshot and ignore this result.
      await Future.wait(
        urls.map((url) async {
          try {
            await VhsImageCache.warm(url, context: context);
          } catch (error) {
            debugPrint('vhs-art warm miss $url: $error');
          }
        }),
      );
    }

    if (!mounted || gen != _warmGen || _warmKey != key || _visible) return;
    // Commit only while still hidden — the reveal setState paints once.
    _arts = byId;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: _fade,
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !_visible,
            child: widget.builder(_arts),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _visible,
            child: AnimatedOpacity(
              opacity: _visible ? 0 : 1,
              duration: _fade,
              curve: Curves.easeOutCubic,
              child: const ColoredBox(
                color: Color(0x66000000),
                child: CrtLoadingIndicator(
                  compact: true,
                  style: CrtLoadStyle.tape,
                  message: 'LOADING VHS ART',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Packed left-aligned spines; trailing tape bookends left when space remains.
class _ShelfTapeRow extends StatelessWidget {
  const _ShelfTapeRow({
    required this.shelfId,
    required this.rowIndex,
    required this.tapes,
    required this.arts,
    required this.loadedId,
    required this.loadedSeriesId,
    required this.flightAnchors,
    required this.flyingTapeId,
    required this.flightSourceKey,
    required this.onTap,
    this.gap = 2,
  });

  final String shelfId;
  final int rowIndex;
  final List<Tape> tapes;
  final Map<String, VhsSpineArt?> arts;
  final String? loadedId;
  final String? loadedSeriesId;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final void Function(Tape tape, String instanceKey) onTap;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var used = tapes.isEmpty ? 0.0 : (tapes.length - 1) * gap;
        for (final tape in tapes) {
          final selected =
              tape.kind == TapeKind.series && tape.id == loadedSeriesId;
          used += selected ? 34.0 : VhsSpine.nominalWidth;
        }
        final leftover = constraints.maxWidth - used;
        const baseHeight = VhsSpine.nominalHeight;
        final tips = VhsSpine.tipsForRow(
          ids: tapes.map((t) => t.id).toList(),
          leftover: leftover,
          height: baseHeight,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < tapes.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              () {
                final instanceKey = TapeFlightAnchors.instanceKey(
                  shelfId: shelfId,
                  row: rowIndex,
                  index: i,
                  tapeId: tapes[i].id,
                );
                final isSource = flightSourceKey == instanceKey;
                final loadedIntoDeck = tapes[i].id == loadedId;
                return RepaintBoundary(
                  child: KeyedSubtree(
                    // GlobalKey only on the tapped instance — duplicates stay put.
                    key: isSource
                        ? flightAnchors.spineKeyFor(instanceKey)
                        : ValueKey(instanceKey),
                    child: VhsSpine(
                      tape: tapes[i],
                      art: arts[tapes[i].id],
                      height: baseHeight,
                      selected:
                          tapes[i].kind == TapeKind.series &&
                          tapes[i].id == loadedSeriesId,
                      tipRadians: tips[i],
                      ghosted:
                          loadedIntoDeck ||
                          flyingTapeId == tapes[i].id && isSource,
                      onTap: () => onTap(tapes[i], instanceKey),
                    ),
                  ),
                );
              }(),
            ],
          ],
        );
      },
    );
  }
}
