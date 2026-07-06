[English](README.md) | [Japanese](README-ja.md)

# find mine fire 🔥

A toolset that collects any nostr user's `kind:1` / `kind:6` events from remote
relays into a local strfry relay and offers **blazing-fast incremental search
via SQLite (FTS5)**.

The **source npub and relays are given as arguments** (defaults: koteitan / x.kojira.io).

## How it works
- **Sync**: NIP-77 Negentropy (`strfry sync`) — pulls only the diff efficiently and practically sidesteps rate limits.
- **strfry**: uses a native `strfry` if it is on PATH, otherwise falls back to Docker (`dockurr/strfry`).
- **Search**: events are indexed into `web/events.sqlite` (FTS5 trigram) and queried in the browser via sqlite-wasm.

## Files
| file | role |
|------|------|
| `lib.sh` | shared helpers (npub→hex decode / filter build / strfry runner) |
| `strfry.conf` | local relay config (DB=`./strfry-db/`, port 7777) |
| `sync.sh` | Negentropy sync from remote into the local DB |
| `build-db.sh` / `build-db.py` | build `web/events.sqlite` (FTS5) from the local DB |
| `stats.sh` / `stats.py` | print statistics about collected events |
| `run-relay.sh` | start the local relay (ws://localhost:7777) to serve events |
| `web/` | search page (`index.html` / `style.css` / `vendor/` sqlite-wasm) |

## Usage
```bash
# 1) Collect (pass an npub and one or more relays; multiple relays are visited in order)
./sync.sh npub1f3w4x7... wss://x.kojira.io wss://yabu.me wss://relay.damus.io

# 2) Statistics
./stats.sh npub1f3w4x7...

# 3) Build the search index
./build-db.sh npub1f3w4x7...

# 4) Serve web/ over a local HTTP server and open index.html
#    (file:// breaks sqlite's fetch, so always use HTTP; avoid ports 8000/8080)

# To serve as a local relay
./run-relay.sh
```
Omitting the argument falls back to `NPUB_DEFAULT` / `RELAY_DEFAULT` (koteitan / x.kojira.io).
A raw hex pubkey may be passed instead of an npub.

### Environment variables
- `SYNC_DIR=down|up|both` … sync direction (default: down)
- `KINDS_DEFAULT=1,6` … kinds to collect
- `SOURCE_RELAY` … default relay when no relay argument is given
- `FORCE_DOCKER=1` … use Docker even if a native strfry exists

## Search behavior
- 3+ characters: FTS5 trigram index (a few ms; works with Japanese)
- 1–2 characters: falls back to a LIKE scan
- filter by kind:1 / kind:6, each result links to njump
- `web/vendor/sqlite3.{mjs,wasm}` bundles the official sqlite-wasm with FTS5 enabled (works offline)

## Notes
- Check a relay's rate limit via NIP-11: `curl -H "Accept: application/nostr+json" <https-url>`
- `strfry.conf` sets `rejectEventsOlderThanSeconds` to 100 years
  (the default 3 years makes `strfry sync` silently drop posts older than 3 years).
- `strfry-db/` (raw LMDB) and `web/events.sqlite` (generated) are git-ignored.
  To serve on GitHub Pages etc., include the data with `git add -f web/events.sqlite`.
