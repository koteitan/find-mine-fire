#!/usr/bin/env bash
##
## run-relay.sh - Start the local strfry relay (websocket on :7777).
##
## Usage:
##   ./run-relay.sh        # foreground (Ctrl-C to stop)
##   ./run-relay.sh -d     # detached; keeps running after this shell exits
##   ./run-relay.sh stop   # stop a detached relay
##
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; export ROOT

NAME="find-mine-fire-relay"
PIDFILE="$ROOT/.relay.pid"
MODE="${1:-fg}"

have_native() { [ -n "$(type -P strfry || true)" ] && [ -z "${FORCE_DOCKER:-}" ]; }

if [ "$MODE" = "stop" ]; then
  docker rm -f "$NAME" >/dev/null 2>&1 && echo "[relay] stopped container $NAME" || true
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null && echo "[relay] stopped pid $(cat "$PIDFILE")" || true
    rm -f "$PIDFILE"
  fi
  exit 0
fi

if have_native; then
  if [ "$MODE" = "-d" ]; then
    nohup strfry --config="$ROOT/strfry.conf" relay >"$ROOT/relay.log" 2>&1 &
    echo $! > "$PIDFILE"
    echo "[relay] detached (pid $(cat "$PIDFILE")) -> ws://localhost:7777"
  else
    exec strfry --config="$ROOT/strfry.conf" relay
  fi
else
  # Reuse of the name would clash; drop any stale container first.
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  DOCKER_OPTS=(--rm -p 7777:7777 --name "$NAME"
    -v "$ROOT:/data" -w /data
    -v "$ROOT/strfry.conf:/etc/strfry.conf:ro"
    --entrypoint /app/strfry)
  if [ "$MODE" = "-d" ]; then
    docker run -d "${DOCKER_OPTS[@]}" dockurr/strfry --config=/etc/strfry.conf relay >/dev/null
    echo "[relay] detached (container $NAME) -> ws://localhost:7777"
  else
    exec docker run -i "${DOCKER_OPTS[@]}" dockurr/strfry --config=/etc/strfry.conf relay
  fi
fi
