// visual preview only, not a printable part.
// each half is wrapped in render(): without it the preview CSG normaliser
// passes 100000 terms on the rim and gives up, rendering nothing.
// same fix as deckblock. it does not touch the exported geometry.
//   openscad -D 'variant="grid"' -D 'view="open"' -o p.png preview.scad
include <dicecase.scad>
part = "none";
view = "open"; // [open, closed]

if (view == "closed") {
    color("#7d99ad") render() half(false);
    color("#d8a13a") mirror([0, 0, 1]) render() half(true);
} else {
    color("#7d99ad") render() half(false);
    color("#d8a13a") translate([-case_w - 12, 0, 0]) render() half(true);
    // dice sitting in the bottom, half proud
    for (k = [0:len(bands)-1], i = [0:len(b_cells(bands[k]))-1]) {
        c = b_cells(bands[k])[i];
        color("#efe7d6")
            // the die each pocket was sized for: its width less the clearance
            translate([cell_x(bands[k], i) + c[1]/2, cell_y(k, c) + c[2]/2, -c[3] + (c[1] - die_clearance)/2])
                cube(c[1] - die_clearance, center = true);
    }
}
