#!/usr/bin/env bash
##
## lib.sh - shared helpers for the find-mine-fire scripts.
##          Source this after setting ROOT to the project dir.
##

# kinds to collect (override with env). No built-in npub/relay defaults:
# the npub and relay(s) must be given explicitly.
: "${KINDS_DEFAULT:=1,6}"

die() { echo "error: $*" >&2; exit 1; }

# npub_to_hex <npub|hex> -> prints 64-char hex pubkey
npub_to_hex() {
  python3 - "$1" <<'PY'
import sys
s = sys.argv[1].strip()
if len(s) == 64 and all(c in "0123456789abcdefABCDEF" for c in s):
    print(s.lower()); raise SystemExit
CH = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
pos = s.rfind("1")
hrp = s[:pos]
data = [CH.find(c) for c in s.lower()[pos+1:]]
if pos < 1 or any(d == -1 for d in data):
    sys.exit(f"invalid bech32: {s}")
if hrp != "npub":
    sys.exit(f"not an npub (hrp={hrp}): {s}")
acc = bits = 0; out = []
for v in data[:-6]:                       # drop 6-word checksum
    acc = (acc << 5) | v; bits += 5
    while bits >= 8:
        bits -= 8; out.append((acc >> bits) & 0xff)
print(bytes(out).hex())
PY
}

# make_filter <hex> [kinds-csv] -> prints a nostr REQ filter JSON
make_filter() {
  local hex="$1" kinds="${2:-$KINDS_DEFAULT}"
  printf '{"kinds":[%s],"authors":["%s"]}' "$kinds" "$hex"
}

# strfry ... -> run strfry via native binary if present, else Docker.
# Use `type -P` (PATH executables only) so it doesn't match this function.
strfry() {
  local bin; bin="$(type -P strfry || true)"
  if [ -n "$bin" ] && [ -z "${FORCE_DOCKER:-}" ]; then
    "$bin" --config="$ROOT/strfry.conf" "$@"
  else
    docker run --rm -i \
      -v "$ROOT:/data" -w /data \
      -v "$ROOT/strfry.conf:/etc/strfry.conf:ro" \
      --entrypoint /app/strfry \
      dockurr/strfry --config=/etc/strfry.conf "$@"
  fi
}
