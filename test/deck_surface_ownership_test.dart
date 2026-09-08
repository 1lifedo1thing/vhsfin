import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

void main() {
  test('fullscreen handoff: release before claim; epoch bumps per claim', () {
    final surface = DeckSurfaceLedger();
    expect(surface.owner, DeckSurfaceOwner.crt);
    expect(surface.epoch, 0);

    // Enter fullscreen — CRT drops before another Video mounts.
    surface.release();
    expect(surface.owner, DeckSurfaceOwner.none);
    expect(surface.epoch, 0);

    surface.claim(DeckSurfaceOwner.fullscreen);
    expect(surface.owner, DeckSurfaceOwner.fullscreen);
    expect(surface.epoch, 1);

    // Leave fullscreen — living room reclaims after push completes.
    surface.release();
    expect(surface.owner, DeckSurfaceOwner.none);

    surface.claim(DeckSurfaceOwner.crt);
    expect(surface.owner, DeckSurfaceOwner.crt);
    expect(surface.epoch, 2);
  });

  test('release while already none is a no-op', () {
    final surface = DeckSurfaceLedger()..release();
    surface.release();
    expect(surface.owner, DeckSurfaceOwner.none);
    expect(surface.epoch, 0);
  });
}
