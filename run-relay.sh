#!/usr/bin/env bash
##
## run-relay.sh - Start the local strfry relay (websocket on :7777).
##                Run this yourself to serve/broadcast the collected events.
##
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; export ROOT

if command -v strfry >/dev/null 2>&1 && [ -z "${FORCE_DOCKER:-}" ]; then
  exec strfry --config="$ROOT/strfry.conf" relay
else
  exec docker run --rm -i -p 7777:7777 \
    -v "$ROOT:/data" -w /data \
    -v "$ROOT/strfry.conf:/etc/strfry.conf:ro" \
    --entrypoint /app/strfry \
    dockurr/strfry --config=/etc/strfry.conf relay
fi
