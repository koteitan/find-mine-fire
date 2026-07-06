#!/usr/bin/env bash
##
## stats.sh - Print statistics about a user's collected events.
##
## Usage:
##   ./stats.sh <npub>
##
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; export ROOT
source "$ROOT/lib.sh"

NPUB="${1:-}"
[ -n "$NPUB" ] || die "npub required. usage: ./stats.sh <npub>"
HEX="$(npub_to_hex "$NPUB")"
FILTER="$(make_filter "$HEX")"

strfry scan "$FILTER" 2>/dev/null | python3 "$ROOT/stats.py" "$ROOT/strfry-db"
