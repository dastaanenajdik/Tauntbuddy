#!/usr/bin/env bash
#
# Back-compat shim: earlier Vercel projects were configured with
# `bash tools/vercel_build.sh`. The real build now lives in
# tools/build_web_deploy.sh (shared by Vercel + Render) — keep this entry
# point working so an old project setting never breaks the deploy.
set -euo pipefail
exec bash "$(dirname "$0")/build_web_deploy.sh"
