# VHSFin

Bare-bones Jellyfin client for kids. Living-room VCR up top (static when idle), pick a tape, watch it slide in and play with a CRT/VHS look. Tap the deck for clean fullscreen.

Built from scratch in Flutter (web / Android / iOS / macOS) instead of forking Moonfin — Moonfin is a full premium client; stripping it would fight the kids-only vision.

## Run

```bash
cd vhsfin
flutter pub get
flutter run -d chrome    # or macos / android / ios
```

## Flow

1. Open app → CRT shows static (standby).
2. Pick a cassette from the shelf → insert animation → VHS-style playback in the bezel (`fancy_overlay` CRT effect; ntsc-rs-inspired look).
3. Tap the VCR / **FULL** / **CLEAN** → normal fullscreen player.
4. **CONNECT** → Jellyfin server + kids user. Until then, demo tapes stream from public samples.

## Scope (intentionally tiny)

- Auth + movie/episode list + direct stream URL
- VCR living room + insert motion + VHS overlay + clean player
- No downloads, music, live TV, cast, theming engine, or multi-server chrome

## Next

- Filter to a dedicated kids library / parental ratings
- Parent PIN on Connect / Sign out
- Optional deeper ntsc-rs-style shader pass on top of `VhsOverlay`
