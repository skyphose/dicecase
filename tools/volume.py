"""Solid volume of a binary STL, by signed tetrahedron sum.

  python3 tools/volume.py file.stl [file.stl ...]      # cm3, one line each
  python3 tools/volume.py --mm3 file.stl               # mm3

Used two ways here: as a regression fixture (one number that almost any
unintended change will move), and as the pass criterion for the probe solids in
verify_reversible.scad, where "did the intersection come back empty" is too
strict -- coplanar contact leaves zero-volume slivers that are real facets but
not real interference.
"""
import struct
import sys


def volume_mm3(path):
    with open(path, "rb") as f:
        f.read(80)
        n = struct.unpack("<I", f.read(4))[0]
        total = 0.0
        for _ in range(n):
            d = struct.unpack("<12fH", f.read(50))
            a, b, c = d[3:6], d[6:9], d[9:12]
            total += (a[0] * (b[1] * c[2] - b[2] * c[1])
                      - a[1] * (b[0] * c[2] - b[2] * c[0])
                      + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
    return abs(total)


def main(argv):
    mm3 = "--mm3" in argv
    files = [a for a in argv if not a.startswith("--")]
    if not files:
        print(__doc__.strip())
        return 1
    for path in files:
        try:
            v = volume_mm3(path)
        except (OSError, struct.error) as exc:
            print("  %-38s ERROR  %s" % (path.rsplit("/", 1)[-1], exc))
            return 1
        if mm3:
            print("%.4f" % v)
        else:
            print("  %-38s %8.3f cm3" % (path.rsplit("/", 1)[-1], v / 1000.0))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
