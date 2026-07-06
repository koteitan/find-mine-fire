#!/usr/bin/env python3
"""Aggregate strfry `scan` JSON-line output into statistics.
Usage:  strfry scan <filter> | stats.py <db-dir>
"""
import sys, json, time, os, collections

dbdir = sys.argv[1] if len(sys.argv) > 1 else "./strfry-db"
total = 0
by_kind = collections.Counter()
by_month = collections.Counter()
oldest = None
newest = None

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
    except Exception:
        continue
    total += 1
    by_kind[ev.get("kind")] += 1
    ts = ev.get("created_at")
    if ts is None:
        continue
    if oldest is None or ts < oldest:
        oldest = ts
    if newest is None or ts > newest:
        newest = ts
    by_month[time.strftime("%Y-%m", time.gmtime(ts))] += 1


def fmt(ts):
    return time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime(ts)) if ts else "-"


db_bytes = 0
try:
    for f in os.listdir(dbdir):
        p = os.path.join(dbdir, f)
        if os.path.isfile(p):
            db_bytes += os.path.getsize(p)
except FileNotFoundError:
    pass

maxm = max(by_month.values()) if by_month else 1

print("=" * 48)
print(" backup-relay statistics")
print("=" * 48)
print(f" total events    : {total}")
print(f"   kind:1 (note)  : {by_kind.get(1, 0)}")
print(f"   kind:6 (repost): {by_kind.get(6, 0)}")
for k in sorted(x for x in by_kind if x not in (1, 6)):
    print(f"   kind:{k}: {by_kind[k]}")
print(f" oldest          : {fmt(oldest)}")
print(f" newest          : {fmt(newest)}")
print(f" db size         : {db_bytes/1024/1024:.1f} MiB")
print("-" * 48)
print(" events per month")
for ym in sorted(by_month):
    bar = "#" * max(1, round(40 * by_month[ym] / maxm))
    print(f"   {ym}  {by_month[ym]:5d}  {bar}")
print("=" * 48)
