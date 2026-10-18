#!/usr/bin/env python3
"""Count connected pieces in a binary STL. A part that should be one piece and
reports more has loose islands -- e.g. shell enclosed by a stencil window.
  python3 tools/components.py part.stl [more.stl ...]"""
import struct, sys
Q = 1e-4
def key(p): return (round(p[0]/Q), round(p[1]/Q), round(p[2]/Q))
for path in sys.argv[1:]:
    d = open(path, 'rb').read(); n = struct.unpack('<I', d[80:84])[0]
    parent = {}
    def find(x):
        while parent.setdefault(x, x) != x:
            parent[x] = parent[parent[x]]; x = parent[x]
        return x
    for i in range(n):
        v = struct.unpack('<12f', d[84+i*50:84+i*50+48])
        a, b, c = key(v[3:6]), key(v[6:9]), key(v[9:12])
        ra, rb, rc = find(a), find(b), find(c)
        parent[rb] = ra; parent[find(c)] = ra
    roots = {find(k) for k in list(parent)}
    print("  %-34s %d piece%s" % (path.rsplit('/',1)[-1], len(roots), "" if len(roots)==1 else "s  <-- LOOSE PIECES"))
