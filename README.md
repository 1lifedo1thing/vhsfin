# VHSFin

Bare-bones Jellyfin client for kids — living-room VCR up top (static when idle), pull a VHS spine off the shelf, watch it slide in and play with a CRT/VHS look. Tap the deck for clean fullscreen.

> **WIP:** usable core loop works; polish and edge cases are still evolving. Issues and PRs welcome.

There is no store build yet. Run or install **from source** with Flutter. Web hosting is something you do yourself (LAN or next to Jellyfin) — a public HTTPS site will not talk to `http://192.168.x.x` Jellyfin.

Screenshots: drop a still or GIF at [`docs/screenshots/living-room.png`](docs/screenshots/) (or `.gif`) when you have a capture of the living room.

## Requirements

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (this repo needs Dart **^3.13.2**, so a current **stable** Flutter). Then:

```bash
git clone <this-repo>
cd vhsfin
flutter pub get
flutter doctor
flutter devices
```

| Target | You also need |
| --- | --- |
| **Android** | Android Studio (or SDK + platform tools), USB debugging or an emulator |
| **iOS** | macOS, Xcode, a simulator — or a device with signing set up in Xcode |
| **Web** | Chrome. Python 3 only if you use `make web` (release build + cover-art proxy) |
| **macOS** | Xcode command-line tools |

## Run from source

```bash
flutter run -d chrome     # web (dev)
flutter run -d android    # USB device or emulator
flutter run -d ios        # simulator or device
flutter run -d macos
```

If several devices are attached, `flutter devices` then `flutter run -d <id>`.

On **Android**, HTTP Jellyfin URLs work (`usesCleartextTraffic` is on). On **iOS**, Apple often blocks cleartext HTTP — use an `https://` Jellyfin URL if Connect fails.

## Build artifacts

```bash
flutter build apk         # Android APK → build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle   # Play Store AAB (when you have a Play account)
flutter build ios         # iOS (Mac; open Xcode to sign / run on a device)
flutter build web         # static web → build/web (no cover-art proxy)
```

The Android **release** APK is still signed with the **debug** keystore so `flutter build apk` works without extra setup. Replace that before a Play listing.

### Web you can actually use (self-hosted)

`flutter run -d chrome` is fine for hacking. For a living-room browser on the LAN, use the Python server so VHSCollector lookups work (they have no CORS):

```bash
make web                  # flutter build web --release, then serve on :8080
```

Open `http://localhost:8080` (or the machine’s LAN IP). Serve it over **HTTP to HTTP** (or put it on the same origin as Jellyfin). Do not expect a public HTTPS host to reach a home HTTP Jellyfin.

Ctrl-C stops the server; `make stop` if it is still around. `make help` lists the other targets.

## Tests

```bash
flutter analyze
flutter test
```

CI runs those on every pull request and every push to `main`. It does **not** build APKs (that needs your signing key).

## First-run flow

1. Open app → CRT shows static (standby).
2. **CONNECT** to Jellyfin, then **SHELVES** to pick which libraries appear (e.g. kids movies only).
3. First time with titles on the shelves, a **VHS art grab** popup runs (progress bar + poster count).
4. Each library is a horizontal bookshelf of **spines**. Movies play on tap; TV shows expand an episode shelf underneath.
5. Insert animation → VHS-style playback in the bezel; **FULL** for clean fullscreen.
6. Hold **REW** for a CRT fast-rewind look; optional **Save on eject** remembers position per tape.

## Features (current)

- Jellyfin auth + multi-shelf collection picker
- Living-room VCR with insert/eject flight + SFX
- CRT glass overlay and fast-rewind visual
- VHS sleeve art lookup (Internet Archive + best-effort VHSCollector), disk cache, wrong-sleeve reject
- First-time art-grab onboarding (progress + found count)
- Settings sheet (tune FAB): VHS-only (on by default), sort, save on eject, CRT look, collection / connect
- Selectable CRT bezels (Zenith, WEGA silver, bubble tube, aqua graphite)
- Desktop-friendly wide layouts (max widths, larger hit targets)

### Replay art-grab onboarding

Clear SharedPreferences key `vhsfin.art_onboarding_done.v1` (browser site data, or app prefs) and reload with titles on the shelves. `make demo-onboarding` prints the same key and steps.

## Cover art

- Spines are procedural (plastic color + vertical title from metadata).
- Best-effort **Internet Archive** search, then **VHSCollector** HTML pages when they match. Cached on disk / SharedPreferences. There is no VHSCollector API.
- Falls back to Jellyfin primary art as a spine stripe.
- On web, VHSCollector needs the `make web` proxy (`/vc/lookup`). Native apps talk to the site from the device.

## Scope (intentionally tiny)

- Auth, library picker, movie/series shelves, episode expand, stream playback
- No downloads, music, live TV, cast, or multi-server chrome

Layout and contribution rules: [CONTRIBUTORS.md](CONTRIBUTORS.md).

## License

MIT — see [LICENSE](LICENSE).
