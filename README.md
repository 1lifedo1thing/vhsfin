<p align="center">
  <img src="assets/icons/app_icon_1024.png" width="120" height="120" alt="VHSFin TV icon">
</p>
<h1 align="center">VHSFin</h1>
<p align="center"><strong>Movie night, rewound.</strong><br>A small Jellyfin client with a VHS player interface.</p>
<p align="center">
  <a href="LICENSE"><img alt="License: GPL-3.0" src="https://img.shields.io/badge/license-GPL--3.0-6FE0E6?style=flat-square&labelColor=111417"></a>
  <img alt="Built with Flutter" src="https://img.shields.io/badge/built_with-Flutter-E6ECEE?style=flat-square&labelColor=111417">
  <img alt="Status: early access" src="https://img.shields.io/badge/status-early_access-E0483E?style=flat-square&labelColor=111417">
</p>
<p align="center"><a href="#get-started">Get started</a> · <a href="#what-it-does">Take a look</a> · <a href="#self-host-the-web-app">Self-host</a> · <a href="CONTRIBUTING.md">Contribute</a> · <a href="https://vhsfin.markdid.dev">Website</a></p>

![Movie-night artwork: a glowing CRT, a VHS deck, and a shelf of tapes](docs/movie-night.jpg)

VHSFin is a small, family-friendly client for a Jellyfin server. It presents movies and shows as tapes on a shelf, with a simple player interface inspired by a living-room VCR.

Pick a tape, let it slide into the deck, and press play.

The artwork above is project artwork; the screenshots below show the app. VHSFin is an independent project by [MarkDid](https://markdid.dev), not an official Jellyfin client. It includes no media, subscriptions, ads, analytics, or hosted service.

## What it does

| VHS-style interface | Useful details |
| --- | --- |
| VHS spines on flat charcoal or walnut shelves | Choose libraries and folders for each shelf |
| A 3D cassette that flies from the shelf into the deck, with mechanical sounds | Movies, series, and an episode picker |
| Six photographic TV cabinets | Change the shelf and TV in Settings |
| CRT glass and scanlines | A clean fullscreen player |
| A remote with rewind and fast-forward | Optional saved positions when you eject a tape |
| VHS sleeve art where available | Jellyfin artwork and procedural fallbacks |

<p align="center">
  <img src="docs/screenshots/connect.png" width="360" alt="VHSFin welcome screen with server and account fields">
  <img src="docs/screenshots/living-room.png" width="360" alt="VHSFin living room: a CRT TV above a walnut shelf of VHS tapes">
</p>

## Get started

App Store and Google Play releases are on the way from [MarkDid](https://markdid.dev). Until then, VHSFin installs from source. Bring a running Jellyfin server and an existing account.

1. Download or clone this repository and open its folder.
2. Install [Flutter](https://docs.flutter.dev/get-started/install) with Dart **3.13.2 or later, below 4.0** (see `pubspec.yaml`).
3. Fetch dependencies and choose a device:

```sh
flutter pub get
flutter doctor
flutter devices
flutter run -d chrome
```

For Android, iOS, or macOS, use the device ID printed by `flutter devices`:

```sh
flutter run -d <device-id>
```

| Platform | Development requirements |
| --- | --- |
| Android | Android SDK and an emulator or a device with USB debugging |
| Web | A supported browser; Chrome for Flutter development |
| iOS | macOS, Xcode, and a simulator or a signed device build |
| macOS | macOS and Xcode |

### Set up movie night

1. Tap the empty shelf to **connect**. Enter the server’s base address, username, and password. Passwordless Jellyfin accounts are supported.
2. **Choose shelves.** Check a library, or open it to select a folder. Tap **Done** to return to the living room. Shelf selections are saved separately for each server and account.
3. Let VHSFin look for sleeve art, or continue while it works in the background.
4. Tap a movie to preview its sleeve, then **Insert tape**. Tap a show to choose an episode. Use **Full** for fullscreen and **Eject** to return the tape.

**Setting up for kids?** Use a Jellyfin account with access only to the appropriate libraries. Shelf selection changes what is displayed; Jellyfin’s account permissions provide the access control.

**Missing titles?** VHS-only is enabled by default. In **Settings**, turn it off to show titles that don’t have matching VHS sleeve art.

The late-90s TV/VCR on walnut shelves is the default look. **Settings → SHELF** switches to flat charcoal, and **Settings → TV** offers five more cabinets. Existing saved choices are preserved.

## Self-host the web app

The included Python server serves the release build. It also proxies the optional VHSCollector lookup (see [Data and artwork](#data-and-artwork)), which browsers otherwise block:

```sh
make web                 # build and serve on port 8080
# Or choose a different port:
make web PORT=8090
# Include the optional VHSCollector lookup:
make web VHSCOLLECTOR=true
```

To try the app without a server, `make demo` stocks the shelf with Blender open movies streamed from Wikimedia Commons.

Open `http://localhost:8080` on the host machine, or its LAN address on another device. The helper binds to all network interfaces for LAN use. Ctrl-C stops it. `make help` lists the available commands.

Use a matching setup: an HTTPS app needs an HTTPS Jellyfin server. For a home HTTP server, run the app over HTTP on your trusted LAN, or configure HTTPS for both. A public HTTPS deployment cannot bypass browser mixed-content or local-network restrictions.

To host the static app yourself:

```sh
flutter build web --release
# Publish the contents of build/web with your web server.
```

The Python helper is intended for a trusted home network. Use an appropriately configured web server/reverse proxy for public hosting. Static hosting works for everything except the optional VHSCollector lookup, which needs the proxy. The mobile and desktop apps need no server besides Jellyfin.

## Build it

```sh
flutter build apk --release       # build/app/outputs/flutter-apk/app-release.apk
flutter build web --release      # build/web
flutter build ios                # macOS; configure signing in Xcode
flutter build macos              # macOS
```

Signing stays out of the repository:

- **Android:** copy `android/key.properties.example` to `android/key.properties` and point it at your upload keystore (or set the `VHSFIN_ANDROID_*` variables from `.env.example`). Without either, release builds use the debug key for local installs.
- **iOS:** copy `ios/Flutter/Signing.xcconfig.example` to `ios/Flutter/Signing.xcconfig` and set your Team ID. If Xcode writes `DEVELOPMENT_TEAM` back into `project.pbxproj` when you change signing settings, remove it before committing.

Both files are gitignored. Never commit keystores, certificates, provisioning profiles, or App Store Connect keys. `git config core.hooksPath .githooks` turns on a pre-commit check that rejects a Team ID in `project.pbxproj`.

Store releases use Fastlane (`fastlane/Fastfile`, secrets in a gitignored `.env`; see `.env.example`). Store screenshots come from the demo shelf: `tool/store_screenshots.sh`, then `tool/frame_screenshots.py`. The website in `site/vhsfin` builds the [privacy policy](docs/legal/privacy-policy.md) and [terms](docs/legal/terms-of-service.md) from Markdown.

## When the picture needs tuning

| Symptom | What to check |
| --- | --- |
| Can’t connect | Use a full `http://` or `https://` base address, including the port when needed. Keep reverse-proxy prefixes such as `/jellyfin`; omit `/web/#/home`. |
| Works at home, fails elsewhere | Make sure your device can reach the server through your configured network or VPN. |
| Browser blocks the connection | Check HTTPS/HTTP compatibility, server CORS, and browser local-network permissions. |
| iOS asks about the local network | Allow it. VHSFin needs local network access to reach a Jellyfin server on your LAN. |
| A shelf seems empty | Disable VHS-only in Settings, and check the account’s library permissions. |
| Wrong sleeve art | Inspect the tape and reject the mismatched sleeve; external lookups are best effort. |
| Playback won’t start | Check Jellyfin’s playback/transcoding settings and the device’s supported codecs. |

## Data and artwork

Your password is sent to your Jellyfin server for authentication and is not persisted by VHSFin. A session token is saved in local app preferences (browser storage on web), so treat a signed-in device as having access to that account. This storage is not an encrypted credential vault. Sign out on shared devices, and revoke sessions from Jellyfin when needed.

VHSFin has no accounts, analytics, ads, or tracking, and MarkDid receives no data from the app. It talks to your Jellyfin server and, to find sleeve art, sends movie titles and years to [Internet Archive](https://archive.org). Builds made with `--dart-define=VHSFIN_VHSCOLLECTOR=true` (or `make web VHSCOLLECTOR=true`) add a **Settings → VHSCOLLECTOR** switch that also searches [VHSCollector](https://vhscollector.com). That lookup is left out of the store apps and off by default everywhere else; VHSCollector's scans belong to its contributors, so please respect the site. Artwork is cached locally; availability and matching vary. Third-party cover art belongs to its respective rights holders and is not included in the project’s license.

The original VHSFin icon concepts and movie-night illustration were generated for this project. Source images, prompts, and platform export instructions live in [assets/branding](assets/branding/README.md). Mechanical sound credits are in [assets/sounds/CREDITS.txt](assets/sounds/CREDITS.txt).

## Development

```sh
flutter analyze
flutter test
flutter build web --release
```

VHSFin is written by a human with AI coding assistants; commits made with one say so in a `Co-Authored-By` line. CI runs analysis, tests, and a web release build. The code is organized by feature, with Riverpod in state/coordinator layers and ordinary Flutter widgets for views. See the [contribution guide](CONTRIBUTING.md) for architecture and local checks.

The focus is deliberately small: libraries, shelves, movies, shows, and playback. Downloads, music, live TV, casting, and multi-server navigation are outside the current scope.

## More from MarkDid

VHSFin is made by [MarkDid](https://markdid.dev), an independent software studio. If you enjoy it, take a look at the other apps:

- **[ROLL BACK](https://rollback.markdid.dev)**: a dice game with a very small wizard who knows how every turn could have gone. Out now on Android.
- **[pabo](https://pabo.markdid.dev)**: conversation practice in Korean, Japanese, and Mandarin. Coming soon to iPhone.

## License

VHSFin is free software under the [GNU General Public License v3.0](LICENSE), with an [additional permission](NOTICE.md) that allows distribution through app stores as long as the source stays public. The “VHSFin” name and icon are not licensed for use in forks; see [NOTICE.md](NOTICE.md).

Copyright © 2026 MarkDid, LLC. Built with [Flutter](https://flutter.dev) for [Jellyfin](https://jellyfin.org).
