#!/usr/bin/env python3
"""Measure the unsupported downward-facing area of a binary STL.

The listing promises "no supports anywhere", so that promise needs a number
behind it rather than a look at the preview.

A facet needs support when it faces downward and lies shallower than 45 degrees
from horizontal. Two details matter and both were learned the hard way:

  * the build-plate face is downward-facing and horizontal, and counting it
    reports thousands of mm^2 on a part that prints perfectly. Facets sitting
    at z_min are excluded.
  * a wall built at exactly 45 degrees lands exactly on the threshold and
    floating point decides the answer. The test uses 44 degrees so that a
    deliberate 45 degree face reads as supported.

Usage:  python3 tools/overhang.py part.stl [more.stl ...]
"""
import math
import struct
import sys

LIMIT_DEG = 44.0          # shallower than this, facing down, needs support
COS_LIMIT = math.cos(math.radians(LIMIT_DEG))
PLATE_EPS = 1e-4


def facets(path):
    with open(path, "rb") as f:
        f.read(80)
        n = struct.unpack("<I", f.read(4))[0]
        for _ in range(n):
            d = struct.unpack("<12fH", f.read(50))
            yield [d[3 + v * 3: 6 + v * 3] for v in range(3)]


def area_and_normal(t):
    (ax, ay, az), (bx, by, bz), (cx, cy, cz) = t
    ux, uy, uz = bx - ax, by - ay, bz - az
    vx, vy, vz = cx - ax, cy - ay, cz - az
    nx = uy * vz - uz * vy
    ny = uz * vx - ux * vz
    nz = ux * vy - uy * vx
    m = math.sqrt(nx * nx + ny * ny + nz * nz)
    if m == 0.0:
        return 0.0, 0.0
    return m / 2.0, nz / m


def report(path):
    tris = list(facets(path))
    if not tris:
        print("  %-38s no facets" % path.split("/")[-1])
        return 0.0
    zmin = min(p[2] for t in tris for p in t)
    total = 0.0
    for t in tris:
        area, nz = area_and_normal(t)
        if area == 0.0 or nz >= 0.0:
            continue
        if abs(nz) <= COS_LIMIT:            # steeper than the limit: fine
            continue
        if max(p[2] for t2 in [t] for p in t2) <= zmin + PLATE_EPS:
            continue                        # this is the build plate
        total += area
    print("  %-38s unsupported %8.2f mm2  %s"
          % (path.split("/")[-1], total, "OK" if total < 0.5 else "NEEDS A LOOK"))
    return total


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    worst = 0.0
    for p in sys.argv[1:]:
        worst = max(worst, report(p))
    sys.exit(0 if worst < 0.5 else 1)
