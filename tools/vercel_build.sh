#!/usr/bin/env bash
#
# Vercel build script for the TauntBuddy Flutter web app.
#
# Vercel's build containers don't ship Flutter, so this script installs the
# SDK (same `stable` channel CI uses) and then runs the exact release build
# CI already proves green: `flutter build web --release`.
#
# Output: build/web  (wired up via vercel.json -> outputDirectory)
#
# Optional env overrides (Vercel project settings -> Environment Variables):
#   FLUTTER_VERSION   Flutter channel/tag to install (default: stable)
#   FLUTTER_ROOT      Where to install Flutter (default: $HOME/flutter)
set -euo pipefail

FLUTTER_CHANNEL="${FLUTTER_VERSION:-stable}"
FLUTTER_ROOT_DIR="${FLUTTER_ROOT:-$HOME/flutter}"

if [[ ! -x "$FLUTTER_ROOT_DIR/bin/flutter" ]]; then
  echo "==> Installing Flutter ($FLUTTER_CHANNEL) into $FLUTTER_ROOT_DIR"
  git clone --depth 1 --branch "$FLUTTER_CHANNEL" \
    https://github.com/flutter/flutter.git "$FLUTTER_ROOT_DIR"
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
# TauntBuddy link keeps working at /classic.html on the Vercel deployment.
cp index.html build/web/classic.html

echo '==> Build output'
du -sh build/web
ls -la build/web
