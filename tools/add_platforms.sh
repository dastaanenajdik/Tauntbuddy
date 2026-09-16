#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# TauntBuddy · one-shot platform scaffolding
#
# The repository ships with the Android + Web platform folders wired by hand
# (custom KAVACH native code, Dark Neon splash assets). Run this script once
# after checking out the repo to add the remaining desktop and iOS targets.
#
#   bash tools/add_platforms.sh
#
# It only creates the missing platform folders — Dart code is never touched.
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ORG="com.tauntbuddy"
PROJECT="tauntbuddy"
PLATFORMS=(ios macos linux windows)

command -v flutter >/dev/null 2>&1 || {
  echo "flutter SDK not found on PATH. Install Flutter >= 3.38.1 first." >&2
  exit 1
}

FLUTTER_VERSION="$(flutter --version --machine 2>/dev/null | tr -d '\n' | sed -n 's/.*"frameworkVersion":"\([^"]*\)".*/\1/p')"
echo "Using Flutter ${FLUTTER_VERSION:-unknown}"

requested=("$@")
if [ ${#requested[@]} -gt 0 ]; then
  PLATFORMS=("${requested[@]}")
fi

for platform in "${PLATFORMS[@]}"; do
  if [ -d "$platform" ]; then
    echo "✓ $platform already present — skipping"
    continue
  fi
  echo "▸ creating $platform…"
  flutter create \
    --platforms="$platform" \
    --org "$ORG" \
    --project-name "$PROJECT" \
    --overwrite \
    .
  echo "✓ $platform created"
done

cat <<'EOF'

Next steps
----------
1. Launcher icons / store art:
     dart run tools/generate_branding_assets.dart
2. iOS + macOS: set the display name to "TauntBuddy" and the bundle id to
   com.tauntbuddy.tauntbuddy in the generated Runner project.
3. Desktop notifications:
     - macOS builds need the "App Sandbox → Outgoing Connections" entitlement
       for the GitHub taunt sync.
     - Linux builds need libnotify for flutter_local_notifications.
4. docs/BRANDING.md lists the palette, mascot poses and asset contract.
EOF
