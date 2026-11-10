#!/usr/bin/env bash
# Start a throwaway Jellyfin in Docker, seeded with one movie and one episode,
# for test/jellyfin_server_compat_test.dart.
#
#   tool/jellyfin_server.sh up [image] [port]   (default jellyfin/jellyfin:latest 8096)
#   tool/jellyfin_server.sh down
#
# Login: vhsfin / vhsfin. The clips are generated inside the container with
# Jellyfin's own ffmpeg, so the host needs only Docker, curl and python3.
set -euo pipefail

NAME=vhsfin-jellyfin-compat
CMD=${1:-up}
IMAGE=${2:-jellyfin/jellyfin:latest}
PORT=${3:-8096}
BASE="http://localhost:$PORT"
USERNAME=vhsfin
PASSWORD=vhsfin
CLIENT='MediaBrowser Client="VHSFin compat", Device="CI", DeviceId="vhsfin-compat", Version="0.0.0"'

if [ "$CMD" = down ]; then
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  exit 0
fi

json() { python3 -I -c "import json,sys; d=json.load(sys.stdin); print($1)"; }

wait_for() { # <description> <seconds> <command...>
  local what=$1 limit=$2
  shift 2
  for _ in $(seq 1 "$limit"); do
    if "$@" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  echo "Timed out waiting for $what" >&2
  docker logs --tail 60 "$NAME" >&2 || true
  exit 1
}

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -p "$PORT:8096" "$IMAGE" >/dev/null

wait_for "Jellyfin to start" 180 sh -c "curl -sf $BASE/System/Info/Public | grep -q '\"Version\"'"
echo "Jellyfin $(curl -s "$BASE/System/Info/Public" | json 'd["Version"]') ($IMAGE) on $BASE"

docker exec "$NAME" sh -c '
  set -e
  ff=/usr/lib/jellyfin-ffmpeg/ffmpeg
  mkdir -p "/media/movies/Test Movie (2001)" "/media/shows/Test Show (2020)/Season 01"
  clip() {
    "$ff" -hide_banner -loglevel error -y \
      -f lavfi -i testsrc2=s=640x360:r=24:d=20 -f lavfi -i sine=f=440:d=20 \
      -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac -shortest "$1"
  }
  clip "/media/movies/Test Movie (2001)/Test Movie (2001).mkv"
  clip "/media/shows/Test Show (2020)/Season 01/Test Show S01E01.mkv"
'

# First-run wizard. GET /Startup/User creates the initial user on older servers.
curl -sf -X POST "$BASE/Startup/Configuration" -H 'Content-Type: application/json' \
  -d '{"UICulture":"en-US","MetadataCountryCode":"US","PreferredMetadataLanguage":"en"}'
curl -sf "$BASE/Startup/User" >/dev/null
curl -sf -X POST "$BASE/Startup/User" -H 'Content-Type: application/json' \
  -d "{\"Name\":\"$USERNAME\",\"Password\":\"$PASSWORD\"}"
curl -sf -X POST "$BASE/Startup/Complete"

TOKEN=$(curl -sf -X POST "$BASE/Users/AuthenticateByName" \
  -H 'Content-Type: application/json' -H "Authorization: $CLIENT" \
  -d "{\"Username\":\"$USERNAME\",\"Pw\":\"$PASSWORD\"}" | json 'd["AccessToken"]')
AUTH="Authorization: $CLIENT, Token=\"$TOKEN\""

add_library() { # <name> <collectionType> <path>
  curl -sf -X POST "$BASE/Library/VirtualFolders?name=$1&collectionType=$2&paths=$3&refreshLibrary=true" \
    -H 'Content-Type: application/json' -H "$AUTH" \
    -d "{\"LibraryOptions\":{\"PathInfos\":[{\"Path\":\"$3\"}]}}"
}
add_library Movies movies /media/movies
add_library Shows tvshows /media/shows
# 12.x can drop the second library's scan while the first runs; scan everything.
curl -sf -X POST "$BASE/Library/Refresh" -H "$AUTH"

USER_ID=$(curl -sf "$BASE/Users/Me" -H "$AUTH" | json 'd["Id"]')
# Both items scanned and probed: VOD HLS needs a runtime. Nudge a stalled scan
# and refresh any item still missing its runtime.
ITEMS="$BASE/Users/$USER_ID/Items?Recursive=true&IncludeItemTypes=Movie,Episode"
for attempt in $(seq 1 90); do
  ids=$(curl -sf "$ITEMS" -H "$AUTH" | json '" ".join(i["Id"] for i in d["Items"] if not i.get("RunTimeTicks")) + ("" if len(d["Items"]) == 2 else " pending")')
  [ -z "$ids" ] && break
  if [ "$attempt" = 90 ]; then
    echo "Timed out waiting for the library scan" >&2
    docker logs --tail 60 "$NAME" >&2 || true
    exit 1
  fi
  if [ $((attempt % 15)) = 0 ]; then
    for id in $ids; do
      if [ "$id" = pending ]; then
        curl -sf -X POST "$BASE/Library/Refresh" -H "$AUTH" || true
        continue
      fi
      curl -sf -X POST "$BASE/Items/$id/Refresh?metadataRefreshMode=FullRefresh&replaceAllMetadata=true" -H "$AUTH" || true
    done
  fi
  sleep 2
done

LEGACY=$(docker exec "$NAME" sh -c 'grep -o "<EnableLegacyAuthorization>[a-z]*" /config/config/system.xml 2>/dev/null | cut -d">" -f2' || true)
echo "Ready: 1 movie, 1 episode. EnableLegacyAuthorization=${LEGACY:-n/a}"
