#!/bin/sh
# build every part, then check mesh, overhang, and that the closed halves
# dont interfere.
#   sh tools/build_all.sh            (from the project root)
cd "$(dirname "$0")/.."
mkdir -p stl
CK=${TMPDIR:-/tmp}/dicecase-check; rm -rf "$CK"; mkdir -p "$CK"
cat > "$CK/closed.scad" <<SCAD
include <$(pwd)/dicecase.scad>
part = "none";
intersection() { half(false); mirror([0, 0, 1]) half(true); }
SCAD
for v in grid row mixed; do
    for p in bottom top; do
        openscad -q --export-format binstl -o "stl/${v}_$p.stl" \
            -D "variant=\"$v\"" -D "part=\"$p\"" dicecase.scad >/dev/null 2>&1 &
    done
    openscad -q --export-format binstl -o "$CK/closed_$v.stl" \
        -D "variant=\"$v\"" "$CK/closed.scad" >/dev/null 2>&1 &
    wait
done
echo "== mesh (zero-area facets stripped, as in deckblock)"
python3 tools/meshcheck.py --strip stl/*.stl >/dev/null; python3 tools/meshcheck.py stl/*.stl
echo "== unsupported"; python3 tools/overhang.py stl/*.stl
echo "== volume";      python3 tools/volume.py stl/*.stl
echo "== closed interference (no file = nothing overlaps)"
for f in "$CK"/*.stl; do [ -e "$f" ] || continue; printf "  %-14s " "$(basename "$f" .stl)"; python3 tools/volume.py --mm3 "$f"; done
