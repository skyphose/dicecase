#!/bin/sh
# build every variant's parts, then check mesh, overhang, and that the closed
# halves dont interfere.
#   sh tools/build_all.sh            (from the project root)
# models are named so they sort into the order you print them, as in deckblock:
#   Dicecase_<Variant>_1-bottom.{stl,3mf}, Dicecase_<Variant>_2-top.{stl,3mf}
cd "$(dirname "$0")/.."
VARIANTS="grid row mixed"
label() { case "$1" in grid) echo Grid ;; row) echo Row ;; mixed) echo Mixed ;; *) echo "$1" ;; esac; }
mkdir -p stl 3mf
CK=${TMPDIR:-/tmp}/dicecase-check; rm -rf "$CK"; mkdir -p "$CK"
cat > "$CK/closed.scad" <<SCAD
include <$(pwd)/dicecase.scad>
part = "none";
intersection() { half(false); mirror([0, 0, 1]) half(true); }
SCAD
for v in $VARIANTS; do
    L=$(label $v)
    for spec in "bottom:1-bottom" "top:2-top"; do
        p=${spec%%:*}; n=${spec##*:}
        openscad -q --export-format binstl -o "stl/Dicecase_${L}_$n.stl" \
            -D "variant=\"$v\"" -D "part=\"$p\"" dicecase.scad >/dev/null 2>&1 &
        openscad -q --export-format 3mf -o "3mf/Dicecase_${L}_$n.3mf" \
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
