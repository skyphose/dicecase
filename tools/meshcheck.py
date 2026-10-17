#!/usr/bin/env python3
"""Validate (and optionally clean) binary STL files before publishing.

  python3 tools/meshcheck.py dist/models-stl/*.stl
  python3 tools/meshcheck.py --strip file.stl      # rewrite without zero-area facets

Checks the mesh is a closed 2-manifold: every edge shared by exactly two
triangles, no zero-area facets. Reports the genus, which is a useful sanity
check here -- a body should have one tunnel per push-out hole.
"""
import struct, sys, collections

Q = 1e-5          # quantise coordinates so shared vertices compare equal
key = lambda p: (round(p[0]/Q), round(p[1]/Q), round(p[2]/Q))

def read(path):
    d = open(path, 'rb').read()
    n = struct.unpack('<I', d[80:84])[0]
    out = []
    for i in range(n):
        o = 84 + i*50
        v = struct.unpack('<12f', d[o:o+48])
        out.append((v[0:3], v[3:6], v[6:9], v[9:12]))   # normal, a, b, c
    return out

def write(path, facets):
    with open(path, 'wb') as f:
        f.write(b'\0'*80 + struct.pack('<I', len(facets)))
        for nrm, a, b, c in facets:
            f.write(struct.pack('<12fH', *nrm, *a, *b, *c, 0))

def degenerate(t):
    _, a, b, c = t
    ka, kb, kc = key(a), key(b), key(c)
    return ka == kb or kb == kc or ka == kc

def check(path, strip=False):
    facets = read(path)
    good   = [t for t in facets if not degenerate(t)]
    ndeg   = len(facets) - len(good)
    if strip and ndeg:
        write(path, good)

    edges = collections.Counter(); verts = set()
    for _, a, b, c in good:
        ka, kb, kc = key(a), key(b), key(c)
        verts.update((ka, kb, kc))
        for u, v in ((ka, kb), (kb, kc), (kc, ka)):
            edges[frozenset((u, v))] += 1
    bad      = [v for v in edges.values() if v != 2]
    open_e   = sum(1 for v in bad if v == 1)
    nonman_e = sum(1 for v in bad if v  > 2)
    chi      = len(verts) - len(edges) + len(good)
    closed   = not bad
    ok       = closed and (ndeg == 0 or strip)

    print(f"  {path.split('/')[-1]:<38} tris={len(good):<6} "
          f"{'OK' if ok else 'FAIL':<5} open={open_e} nonmanifold={nonman_e} "
          f"zero_area={'stripped ' + str(ndeg) if (strip and ndeg) else ndeg} "
          f"genus={(2 - chi)//2 if closed else '?'}")
    return ok

if __name__ == '__main__':
    args  = sys.argv[1:]
    strip = '--strip' in args
    files = [a for a in args if a != '--strip']
    sys.exit(0 if all([check(f, strip) for f in files]) else 1)
