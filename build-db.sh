#!/usr/bin/env bash
##
## build-db.sh - Export a user's collected events into web/events.sqlite (FTS5).
##
## Usage:
##   ./build-db.sh <npub>
##
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; export ROOT
source "$ROOT/lib.sh"

NPUB="${1:-}"
[ -n "$NPUB" ] || die "npub required. usage: ./build-db.sh <npub>"
HEX="$(npub_to_hex "$NPUB")"
FILTER="$(make_filter "$HEX")"

echo "[build-db] npub: $NPUB"
strfry scan "$FILTER" 2>/dev/null | python3 "$ROOT/build-db.py" "$ROOT/web/events.sqlite"
echo "[build-db] done -> web/events.sqlite"
