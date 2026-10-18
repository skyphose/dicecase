// ============================================================================
//  counter die, mono  --  a 24 mm counter d6 that reads in ONE colour
// ----------------------------------------------------------------------------
//  No paint, no inlay, no second filament. The symbols read by shadow instead
//  of colour: every face is a CAMEO, like a coin or a wax seal. A panel is
//  sunk `relief` mm into the face and the symbol stands back up to the full
//  surface inside it, so
//    - the pocket wall throws a shadow line all the way round the symbol
//    - the symbol's top is the only flat area at face level, and catches the
//      light differently from the pocket floor below it
//  An engraving in one colour reads only as a thin dark line where the light
//  happens to hit; a cameo reads from any angle.
//
//  Print logo face UP, bolt on the bed. No supports:
//    side faces  the pocket's top edge and each stroke's bottom edge step at
//                45 deg in 0.1 mm terraces, so no edge bridges
//    top face    straight walls; nothing on an upward face can overhang
//    bed face    the bolt stays a plain engraving: a sunk panel on the bed
//                would bridge the whole face
// ============================================================================
version = "0.1";
use <fonts/BarlowSemiCondensed-SemiBold.ttf>   // bundled, OFL -- see fonts/OFL-Barlow.txt

/* [Die] */
die_size = 24.0;
chamfer  = 1.2;

/* [Relief] */
relief  = 1.0;      // how far the panel is sunk -- the depth of the shadow
panel   = 20.0;     // panel size at the surface; leaves a 0.8 mm frame inside the chamfer
panel_r = 2.0;      // panel corner radius
step    = 0.1;      // terrace height for the 45 deg walls

/* [Symbols] */
logo_file = "glg_logo.svg";
logo_aspect = 178.618 / 133.412;
logo_w    = 17.0;
font      = "Barlow Semi Condensed:style=SemiBold";
// Strokes keep their width (only their bottom edges ramp), so the text can
// nearly fill the 20 mm panel.
text_w    = 17.0;

faces = [
    [1, ["logo"]],
    [6, ["bolt"]],
    [2, ["text", "+1/+1"]],
    [5, ["text", "−1/−1"]],
    [3, ["poison"]],
    [4, ["shield"]],
];

/* [Hidden] */
$fa = 2; $fs = 0.2;
eps = 0.01;
s   = die_size;

// ------------------------------------------------------------------ shape ---
module chamfered_cube() {
    hull() {
        cube([s, s - 2*chamfer, s - 2*chamfer], center = true);
        cube([s - 2*chamfer, s, s - 2*chamfer], center = true);
        cube([s - 2*chamfer, s - 2*chamfer, s], center = true);
    }
}
function face_rot(n) =
      n == 1 ? [0, 0, 0]   : n == 6 ? [180, 0, 0]
    : n == 2 ? [0, 90, 0]  : n == 5 ? [0, -90, 0]
    : n == 3 ? [-90, 0, 0] :          [90, 0, 0];
function face_spin(n) = n == 2 ? 90 : n == 5 ? -90 : n == 3 ? 180 : 0;
module on_face(n) {
    rotate(face_rot(n)) translate([0, 0, s/2]) rotate(face_spin(n)) children();
}

// -------------------------------------------------------------- symbols 2d ---
// No stencil ties needed here: nothing is cut through, so nothing comes loose.
module poison2d() {
    difference() { scale([1.15, 1]) circle(r = 5.0); scale([1.15, 1]) circle(r = 3.3); }
    square([1.8, 15], center = true);
}
function shield_pts() =
    let (R = 9.75, a_end = atan2(-9, 3.75),
         right = [for (a = [0 : -3 : a_end]) [-3.75 + R*cos(a), 1 + R*sin(a)]],
         left  = [for (i = [len(right)-1 : -1 : 0]) [-right[i][0], right[i][1]]])
    concat([[-6, 7], [6, 7]], right, [[0, -8]], left);
// Solid, not an outline: in one colour, an outline cameo is a thin ridge and
// reads as a doodle. The solid silhouette reads as a shield at a glance.
module shield2d() { polygon(shield_pts()); }
module bolt2d() {
    scale(0.95) polygon([[1.5, 8], [-5, -0.8], [-0.6, -0.8], [-2.2, -8],
                         [5, 1.2], [0.6, 1.2]]);
}
module logo2d() { resize([logo_w, logo_w / logo_aspect]) import(logo_file, center = true); }
module text2d(t) {
    resize([text_w, 0], auto = true)
        text(t, font = font, size = 6, halign = "center", valign = "center");
}
module symbol2d(k) {
         if (k[0] == "logo")   logo2d();
    else if (k[0] == "text")   text2d(k[1]);
    else if (k[0] == "poison") poison2d();
    else if (k[0] == "shield") shield2d();
    else if (k[0] == "bolt")   bolt2d();
}
module panel2d() { offset(r = panel_r) square(panel - 2*panel_r, center = true); }

// ------------------------------------------------------------------ cameo ---
// Built in a face's frame: z = 0 is the face, the pocket goes down to -relief.
// +y is up (toward the top of the print) on every side face.
//
// On a vertical face only two edges can overhang in print: the TOP edge of the
// pocket (a ceiling) and the BOTTOM edge of every raised stroke (hanging over
// the pocket floor). So only those two are ramped at 45 deg, in 0.1 mm
// terraces, and everything else keeps a straight wall.
//
// The first version flared every edge, which fattened each stroke by `relief`
// a side on its way down -- fine for the shield and the phi, but it merged
// the +1/+1 into a blob under a low light.
module sweep_down(d) {          // smear a 2d shape downward (-y) by d
    if (d <= 0) children();
    else minkowski() { children(); translate([-0.0005, -d]) square([0.001, d]); }
}
module pocket(flared) {
    n = round(relief / step);
    if (flared)
        for (i = [0 : n - 1])
            translate([0, 0, -(i + 1) * step])
                linear_extrude(height = step + (i == 0 ? 1 : eps))
                    intersection() {                     // top edge steps down
                        panel2d();
                        translate([0, -i * step]) panel2d();
                    }
    else
        translate([0, 0, -relief]) linear_extrude(height = relief + 1) panel2d();
}
module raised(k, flared) {
    n = round(relief / step);
    if (flared)
        for (i = [0 : n - 1])
            translate([0, 0, -(i + 1) * step - eps])
                linear_extrude(height = step + eps)      // top lands exactly on the face
                    intersection() {
                        sweep_down(i * step) symbol2d(k); // bottom edges ramp down
                        translate([0, -i * step]) panel2d();
                    }
    else
        translate([0, 0, -relief - eps]) linear_extrude(height = relief + eps) symbol2d(k);
}
module engrave(k) {
    translate([0, 0, -relief]) linear_extrude(height = relief + 1) symbol2d(k);
}

function is_side(n) = n >= 2 && n <= 5;

module die() {
    difference() {
        chamfered_cube();
        for (f = faces) on_face(f[0])
            if (f[0] == 6) engrave(f[1]);        // the bed face
            else pocket(is_side(f[0]));
    }
    for (f = faces) if (f[0] != 6) on_face(f[0]) raised(f[1], is_side(f[0]));
}

translate([0, 0, s/2]) die();
