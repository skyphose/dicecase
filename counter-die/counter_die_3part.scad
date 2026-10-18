// ============================================================================
//  counter die, 3-part  --  a 24 mm counter d6 that prints with zero purge
// ----------------------------------------------------------------------------
//  The single-piece die needs a colour swap on almost every layer from 5 mm
//  up when its inlay is printed on an AMS, because the symbols sit on all six
//  faces -- well over a hundred swaps, whose purge can outweigh the die. This
//  version splits the colours into separate parts instead, so neither print
//  ever changes filament:
//
//    shell_bottom, shell_top   die colour. The die's outer skin, split at
//                              the midline like the dicecase, with every
//                              symbol cut clean through it as a window.
//    core                      accent colour. A plain cube that fills the
//                              shell and shows through every window, so the
//                              symbols read in colour, recessed `shell_t`.
//
//  Assembly: drop the core into the bottom shell, put the top shell on, and
//  glue the seam (a thin CA line round the parting face). The core registers
//  the halves.
//
//  Print, no supports:
//    shell_bottom  as oriented: outer (bolt) face on the bed, open side up
//    shell_top     as oriented: outer (logo) face on the bed -- the logo
//                  gets the smooth bed finish
//    core          any face down; it's a plain cube
//
//  Stencil bridges: a window cut clean through the shell leaves any shell
//  that a symbol fully encloses -- the inside of the shield, the two halves
//  inside the phi -- as loose pieces. Those symbols carry small ties, the
//  way a spray-paint stencil does, one per piece per half, since the parting
//  plane cuts each enclosed piece in two.
// ============================================================================
version = "0.1";
use <fonts/BarlowSemiCondensed-SemiBold.ttf>   // bundled, OFL -- see fonts/OFL-Barlow.txt

/* [Part] */
part = "shell_bottom"; // [shell_bottom, shell_top, core, assembled, exploded]

/* [Die] */
die_size = 24.0;
chamfer  = 1.2;

/* [Shell and core] */
shell_t   = 1.2;     // shell wall: 3 perimeters at 0.4, and the symbol recess
core_c    = 0.15;    // clearance per side between core and shell cavity
core_ch   = 0.4;     // chamfer on the core's edges, so the printed cavity's
                     // slightly rounded inside corners can't hold it off
bridge_w  = 1.0;     // stencil tie width

/* [Symbols] */
logo_file = "glg_logo.svg";
logo_aspect = 178.618 / 133.412;
logo_w    = 18.0;
font      = "Barlow Semi Condensed:style=SemiBold";
text_w    = 18.0;

// Face -> symbol. 1 = +z (top)  6 = -z (bottom)  2 = +x  5 = -x  3 = +y  4 = -y
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
cav = s - 2*shell_t;               // the shell's cavity
core_s = cav - 2*core_c;

// ------------------------------------------------------------------ shape ---
module chamfered_cube(a, c) {
    hull() {
        cube([a, a - 2*c, a - 2*c], center = true);
        cube([a - 2*c, a, a - 2*c], center = true);
        cube([a - 2*c, a - 2*c, a], center = true);
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
// In each face's frame, +y is "up" with the die logo-up, so on the four
// side faces y = 0 is the parting plane.
module poison2d() {     // a phi: an oval ring through a vertical bar
    difference() {
        union() {
            difference() { scale([1.15, 1]) circle(r = 5.0); scale([1.15, 1]) circle(r = 3.3); }
            square([1.8, 15], center = true);
        }
        // four ties across the ring at +-45 / +-135 deg: one for each quarter
        // of the enclosed centre, since the bar halves it and the parting
        // plane halves it again
        for (a = [45, 135, 225, 315])
            rotate(a) translate([4.6, 0]) square([3, bridge_w], center = true);
    }
}
function shield_pts() =
    let (R = 9.75, a_end = atan2(-9, 3.75),
         right = [for (a = [0 : -3 : a_end]) [-3.75 + R*cos(a), 1 + R*sin(a)]],
         left  = [for (i = [len(right)-1 : -1 : 0]) [-right[i][0], right[i][1]]])
    concat([[-6, 7], [6, 7]], right, [[0, -8]], left);
module shield2d() {     // heater shield outline round an inner panel
    difference() {
        polygon(shield_pts());
        offset(delta = -1.6) polygon(shield_pts());
    }
}
module shield_ties() {  // panel is cut in two by the parting plane: tie each
    for (y = [3.5, -3.5]) translate([0, y]) square([16, bridge_w], center = true);
    // and one down the middle of the top bar: on the flipped top shell the
    // panel's top edge is a bridge, and this halves it (about 9 mm -> 4.4)
    translate([0, 6.2]) square([bridge_w, 3], center = true);
}
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
    else if (k[0] == "shield") difference() { shield2d(); shield_ties(); }
    else if (k[0] == "bolt")   bolt2d();
}

// ------------------------------------------------------------------ parts ---
// Windows go from just outside the surface to just inside the cavity.
module windows() {
    for (f = faces) if (f[1][0] != "blank")
        on_face(f[0]) translate([0, 0, -shell_t - 0.5])
            linear_extrude(height = shell_t + 1) symbol2d(f[1]);
}
module shell() {
    difference() {
        chamfered_cube(s, chamfer);
        cube(cav, center = true);
        windows();
    }
}
module shell_half(top) {
    intersection() {
        shell();
        translate([0, 0, top ? s : -s]) cube(2*s, center = true);
    }
}
module core() { chamfered_cube(core_s, core_ch); }

// ------------------------------------------------------------------ render ---
if (part == "shell_bottom")
    translate([0, 0, s/2]) shell_half(false);
else if (part == "shell_top")                    // flipped: logo face on the bed
    translate([0, 0, s/2]) rotate([180, 0, 0]) shell_half(true);
else if (part == "core")
    translate([0, 0, core_s/2]) core();
else if (part == "assembled") translate([0, 0, s/2]) {
    color("#efe7d6") render() shell();
    color("#6b3fa0") core();
}
else if (part == "exploded") translate([0, 0, s/2]) {
    color("#efe7d6") render() shell_half(false);
    color("#6b3fa0") translate([0, 0, 18]) core();
    color("#efe7d6") translate([0, 0, 36]) render() shell_half(true);
}

echo(str("shell ", shell_t, " mm, cavity ", cav, ", core ", core_s, " (", core_c, "/side)"));
