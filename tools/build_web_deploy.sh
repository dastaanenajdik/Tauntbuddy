#!/usr/bin/env bash
#
# Web deploy build for Vercel + Render (used by vercel.json and render.yaml).
#
# Neither provider ships Flutter in their build containers, so this script
# installs the SDK (same `stable` channel CI proves green on every push) and
# runs the exact release build CI already verifies: `flutter build web --release`.
#
# Output: build/web
#   /                → the Flutter web app (hash-routed SPA)
#   /classic.html    → the legacy single-file TauntBuddy page
#   /study-hub/      → the Study Hub / Exam Hub static site WITH the six
#                      photographic backgrounds (assets/bg-*.jpg) — the photos
#                      that were previously missing from the published site
#                      because only build/web (Flutter output) was deployed.
#   /build-info.txt  → commit + timestamp of the build, so anyone can verify
#                      which revision is actually live.
#
# Optional env overrides (provider project settings -> Environment Variables):
#   FLUTTER_VERSION   Flutter channel/tag to install (default: stable)
#   FLUTTER_ROOT      Where to install Flutter (default: $HOME/flutter)
set -euo pipefail

FLUTTER_CHANNEL="${FLUTTER_VERSION:-stable}"
FLUTTER_ROOT_DIR="${FLUTTER_ROOT:-$HOME/flutter}"

if [[ ! -x "$FLUTTER_ROOT_DIR/bin/flutter" ]]; then
  echo "==> Installing Flutter ($FLUTTER_CHANNEL) into $FLUTTER_ROOT_DIR"
  # Provider networks hiccup on big clones; retry a few times before failing.
  attempt=1
  until git clone --depth 1 --branch "$FLUTTER_CHANNEL" \
      https://github.com/flutter/flutter.git "$FLUTTER_ROOT_DIR"; do
    attempt=$((attempt + 1))
    if [[ $attempt -gt 3 ]]; then
      echo "::error::Flutter SDK clone failed after 3 attempts" >&2
      exit 1
    fi
    echo "==> Flutter clone attempt $attempt of 3..."
    rm -rf "$FLUTTER_ROOT_DIR"
    sleep 5
  done
fi

export PATH="$FLUTTER_ROOT_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics
flutter precache --web

echo '==> Resolving Dart dependencies'
flutter pub get

echo '==> Building Flutter web release'
flutter build web --release

# Ship the legacy single-file page alongside the Flutter app so the original
# TauntBuddy link keeps working at /classic.html on the deployment.
cp index.html build/web/classic.html

# Ship the Study Hub / Exam Hub static site (pages + CSS + JS + the six
# background photos) at /study-hub/ — until now it was never copied into the
# deploy output, which is why the published site showed no backgrounds.
rm -rf build/web/study-hub
mkdir -p build/web/study-hub
cp -r study-hub/index.html study-hub/css study-hub/js study-hub/data study-hub/assets build/web/study-hub/

# Stamp the build so the live revision is verifiable at /build-info.txt.
{
  echo "commit: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  date -u +"built_utc: %Y-%m-%dT%H:%M:%SZ"
  echo "flutter: $FLUTTER_CHANNEL"
} > build/web/build-info.txt

echo '==> Build output'
du -sh build/web
ls -la build/web
ls -la build/web/study-hub build/web/study-hub/assets
