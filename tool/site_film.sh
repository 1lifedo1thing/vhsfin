#!/usr/bin/env bash
# Record the landing-page film (tape into the deck, then playback) on a simulator.
# Usage: tool/site_film.sh ["iPhone 18 Pro Max"]   → screenshots/raw/film.mov
set -euo pipefail
name="${1:-iPhone 18 Pro Max}"
udid=$(xcrun simctl list devices available | grep -F "$name (" | head -1 | grep -oE '[0-9A-F-]{36}')
xcrun simctl boot "$udid" 2>/dev/null || true
mkdir -p screenshots/raw
# Build and install first so the recording isn't mostly a build.
flutter build ios --simulator --debug --dart-define=VHSFIN_DEMO=true -t integration_test/site_film_test.dart >/dev/null
xcrun simctl io "$udid" recordVideo --codec=h264 --force screenshots/raw/film.mov &
rec=$!
sleep 2
flutter drive --driver=test_driver/store_screenshots.dart \
  --target=integration_test/site_film_test.dart \
  --dart-define=VHSFIN_DEMO=true -d "$udid" || true
kill -INT "$rec"; wait "$rec" || true
