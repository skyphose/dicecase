#!/bin/sh
# build + check every part (tools/build_all.sh), then render the previews.
set -e
sh tools/build_all.sh
for v in grid row mixed; do for view in open closed; do
    openscad -q -D "variant=\"$v\"" -D "view=\"$view\"" \
        --viewall --autocenter --camera=0,0,0,50,0,30,0 --imgsize=1400,1000 \
        --colorscheme=Tomorrow -o "preview_${v}_$view.png" preview.scad
done; done
# a blank preview is the symptom of the CSG normaliser giving up (see preview.scad)
python3 -c "
import glob, sys
from PIL import Image
bad = [f for f in sorted(glob.glob('preview_*.png')) if Image.open(f).convert('L').getextrema()[0] > 200]
print('  previews: ' + ('BLANK: ' + ' '.join(bad) if bad else 'all have content'))
sys.exit(1 if bad else 0)
"
