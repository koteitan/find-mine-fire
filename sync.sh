#!/usr/bin/env bash
##
## sync.sh - Pull a user's events into the local strfry DB via NIP-77 sync.
##
## Usage:
##   ./sync.sh <npub> <relay> [relay ...]
##   ./sync.sh npub1... wss://x.kojira.io wss://yabu.me wss://relay.damus.io
##
## Env:
##   SYNC_DIR=down|up|both   (default: down)
##   KINDS_DEFAULT=1,6       (kinds to collect)
##   SOURCE_RELAY            (used only if no relay arg is given)
##
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; export ROOT
source "$ROOT/lib.sh"

NPUB="${1:-}"; [ $# -gt 0 ] && shift
RELAYS=("$@")
[ ${#RELAYS[@]} -eq 0 ] && [ -n "${SOURCE_RELAY:-}" ] && RELAYS=("$SOURCE_RELAY")
[ -n "$NPUB" ] || die "npub required. usage: ./sync.sh <npub> <relay> [relay...]"
[ ${#RELAYS[@]} -gt 0 ] || die "at least one relay required. usage: ./sync.sh <npub> <relay> [relay...]"
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
