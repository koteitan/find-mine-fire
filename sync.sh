#!/usr/bin/env bash
##
## sync.sh - Pull a user's events into the local strfry DB via NIP-77 sync.
##
## Usage:
##   ./sync.sh <npub> [relay ...]
##   ./sync.sh                      # NPUB_DEFAULT from RELAY_DEFAULT
##   ./sync.sh npub1... wss://x.kojira.io wss://yabu.me wss://relay.damus.io
##
## Env:
##   SYNC_DIR=down|up|both   (default: down)
##   KINDS_DEFAULT=1,6       (kinds to collect)
##
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; export ROOT
source "$ROOT/lib.sh"

NPUB="${1:-$NPUB_DEFAULT}"; shift || true
RELAYS=("$@")
[ ${#RELAYS[@]} -eq 0 ] && RELAYS=("${SOURCE_RELAY:-$RELAY_DEFAULT}")
DIR="${SYNC_DIR:-down}"

HEX="$(npub_to_hex "$NPUB")"
FILTER="$(make_filter "$HEX")"

echo "[sync] npub   : $NPUB"
echo "[sync] hex    : $HEX"
echo "[sync] dir    : $DIR"
echo "[sync] filter : $FILTER"
echo

for r in "${RELAYS[@]}"; do
  echo "########## $r ##########"
  strfry sync "$r" --dir "$DIR" --filter "$FILTER" || echo "[sync] warning: $r failed, continuing"
  echo
done

echo "[sync] done. local event count for this author:"
strfry scan --count "$FILTER"
