#!/bin/sh
# build + check every variant (tools/build_all.sh), then render the images.
#   images/<n>-<Variant>-{open,closed}.png, numbered in the order the readme shows them
set -e
sh tools/build_all.sh
mkdir -p images
n=1
for v in grid row mixed; do
    L=$(case $v in grid) echo Grid ;; row) echo Row ;; mixed) echo Mixed ;; esac)
    for view in open closed; do
        openscad -q -D "variant=\"$v\"" -D "view=\"$view\"" \
            --viewall --autocenter --camera=0,0,0,50,0,30,0 --imgsize=1400,1000 \
            --colorscheme=Tomorrow -o "images/$n-$L-$view.png" preview.scad
    done
    n=$((n + 1))
done
# a blank image is the symptom of the CSG normaliser giving up (see preview.scad)
python3 -c "
import glob, sys
from PIL import Image
bad = [f for f in sorted(glob.glob('images/*.png')) if Image.open(f).convert('L').getextrema()[0] > 200]
print('  images: ' + ('BLANK: ' + ' '.join(bad) if bad else 'all have content'))
sys.exit(1 if bad else 0)
"
