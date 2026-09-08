# VHSFin

Bare-bones Jellyfin client for kids — living-room VCR up top (static when idle), pull a VHS spine off the shelf, watch it slide in and play with a CRT/VHS look. Tap the deck for clean fullscreen.

> **WIP / open-source ready:** usable core loop works; polish and edge cases are still evolving. Issues and PRs welcome.

Screenshots: drop a still or GIF at [`docs/screenshots/living-room.png`](docs/screenshots/) (or `.gif`) when you have a capture of the living room.

## Run

```bash
flutter pub get
flutter run -d chrome    # or macos / android / ios
```

Web release with Internet Archive proxy:

```bash
make web                 # build + serve on :8080
```

## Flow

1. Open app → CRT shows static (standby).
2. **CONNECT** to Jellyfin, then **SHELVES** to pick which libraries appear (e.g. kids movies only).
3. First time with titles on the shelves, a **VHS art grab** popup runs (progress bar + poster count).
4. Each library is a horizontal bookshelf of **spines**. Movies play on tap; TV shows expand an episode shelf underneath.
5. Insert animation → VHS-style playback in the bezel; **FULL** for clean fullscreen.
6. Hold **REW** for a CRT fast-rewind look; optional **Save on eject** remembers position per tape.

## Architecture sketch

```
lib/
├── data/repositories/     # Shared API clients (Jellyfin)
├── features/
│   ├── auth/              # Connect + session
│   ├── library/           # Shelves, cover art, collection picker, art onboarding
│   ├── living_room/       # VCR, bookshelf, spines, remote, experience prefs
│   └── playback/          # Clean fullscreen + shared deck player
└── router/
```

Feature folders follow **page / `state/` / `views/` / `widgets/`**:

- **Pages** coordinate Riverpod and pass props/callbacks.
- **Views & widgets** have **no Riverpod** — props and callbacks only.

See [CONTRIBUTORS.md](CONTRIBUTORS.md).

## Features (current)

- Jellyfin auth + multi-shelf collection picker
- Living-room VCR with insert/eject flight + SFX
- CRT glass overlay and fast-rewind visual
- VHS sleeve art lookup (Internet Archive), disk cache, wrong-sleeve reject
- First-time art-grab onboarding (progress + found count)
- Settings sheet (tune FAB): VHS-only (on by default), sort, save on eject, CRT look, collection / connect
- Selectable CRT bezels (Zenith, WEGA silver, bubble tube, aqua graphite)
- Desktop-friendly wide layouts (max widths, larger hit targets)

## Demo the art-grab onboarding

Without wiping the whole app:

1. Clear SharedPreferences key `vhsfin.art_onboarding_done.v1` (browser site data, or app prefs).
2. Reload with titles on the shelves — the art-grab popup runs again.
3. Or from a terminal: `make demo-onboarding` (prints the prefs key + steps).

Prefs key: `vhsfin.art_onboarding_done.v1`

## Cover art

- Spines are procedural (plastic color + vertical title from metadata).
- Best-effort **Internet Archive** VHS cover lookup, cached on disk / SharedPreferences.
- Falls back to Jellyfin primary art as a spine stripe.
- **VHSCollector** has no public API — skipped for now.

## Scope (intentionally tiny)

- Auth, library picker, movie/series shelves, episode expand, stream playback
- No downloads, music, live TV, cast, or multi-server chrome

## License

MIT — see [LICENSE](LICENSE).
