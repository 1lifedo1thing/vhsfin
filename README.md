# VHSFin

Bare-bones Jellyfin client for kids. Living-room VCR up top (static when idle), pull a VHS spine off the shelf, watch it slide in and play with a CRT/VHS look. Tap the deck for clean fullscreen.

## Run

```bash
flutter pub get
flutter run -d chrome    # or macos / android / ios
```

## Flow

1. Open app → CRT shows static (standby).
2. **CONNECT** to Jellyfin, then **SHELVES** to pick which libraries appear (e.g. kids movies only).
3. Each library is a horizontal bookshelf of **spines**. Movies play on tap; TV shows expand an episode shelf underneath.
4. Insert animation → VHS-style playback in the bezel; **FULL** for clean fullscreen.

## Layout

```
lib/
├── data/repositories/     # Shared API clients (Jellyfin)
├── features/
│   ├── auth/              # Connect + session
│   ├── library/           # Shelves, cover art, collection picker
│   ├── living_room/       # VCR, bookshelf, spines, remote
│   └── playback/          # Clean fullscreen player
└── router/
```

Feature folders follow page / `state/` / `views/` / `widgets/` where it helps. Prefer specific props and callbacks on widgets; keep pages as thin coordinators.

## Cover art

- Spines are procedural (plastic color + vertical title from metadata).
- Best-effort **Internet Archive** VHS cover lookup (`advancedsearch` + `services/img/{id}`), cached in SharedPreferences.
- Falls back to Jellyfin primary art as a spine stripe.
- **VHSCollector** has no public API — skipped for now (would need scraping or a manual mapping).

## Scope (intentionally tiny)

- Auth, library picker, movie/series shelves, episode expand, stream playback
- No downloads, music, live TV, cast, or multi-server chrome

## License

MIT — see [LICENSE](LICENSE).
