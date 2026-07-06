#!/usr/bin/env python3
"""Build web/events.sqlite (FTS5 trigram) from strfry `scan` JSON-line output.

Usage:  strfry scan <filter> | build-db.py web/events.sqlite
"""
import sys, json, sqlite3, os

out = sys.argv[1] if len(sys.argv) > 1 else "web/events.sqlite"
os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
if os.path.exists(out):
    os.remove(out)

db = sqlite3.connect(out)
db.execute("PRAGMA journal_mode=OFF")
db.execute("PRAGMA synchronous=OFF")
# Single FTS5 table: content is indexed (trigram → substring/Japanese match),
# id/created_at/kind ride along as UNINDEXED columns.
db.execute(
    "CREATE VIRTUAL TABLE ev USING fts5("
    "c, i UNINDEXED, t UNINDEXED, k UNINDEXED, "
    "tokenize='trigram')"
)

n = 0
batch = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
    except Exception:
        continue
    batch.append((ev.get("content", ""), ev.get("id", ""),
                  ev.get("created_at", 0), ev.get("kind", 0)))
    if len(batch) >= 5000:
        db.executemany("INSERT INTO ev(c,i,t,k) VALUES(?,?,?,?)", batch)
        n += len(batch); batch = []
if batch:
    db.executemany("INSERT INTO ev(c,i,t,k) VALUES(?,?,?,?)", batch)
    n += len(batch)

db.commit()
db.execute("INSERT INTO ev(ev) VALUES('optimize')")
db.commit()
db.execute("VACUUM")
db.close()
sys.stderr.write(f"built {out} with {n} events ({os.path.getsize(out)/1024/1024:.1f} MiB)\n")
