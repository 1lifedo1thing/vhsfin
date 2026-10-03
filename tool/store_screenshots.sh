#!/usr/bin/env bash
# Capture raw store screenshots from the demo shelf on an iOS simulator.
# Usage: tool/store_screenshots.sh "iPhone 18 Pro Max" iphone
#        tool/store_screenshots.sh "iPad Pro 13-inch (M5)" ipad
set -euo pipefail
name="$1"; slug="$2"
udid=$(xcrun simctl list devices available | grep -F "$name (" | head -1 | grep -oE '[0-9A-F-]{36}')
[ -n "$udid" ] || { echo "No simulator named $name" >&2; exit 1; }
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi \
  --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100
SHOT_DIR="screenshots/raw/$slug" flutter drive \
  --driver=test_driver/store_screenshots.dart \
  --target=integration_test/store_screenshots_test.dart \
  --dart-define=VHSFIN_DEMO=true -d "$udid"
xcrun simctl status_bar "$udid" clear
