// ============================================================================
//  counter die  --  a 24 mm d6 with counter symbols instead of pips
// ----------------------------------------------------------------------------
//  Sized to drop into a dicecase pocket like any 24 mm die. Each face is one
//  line in `faces` below, so the set is yours to change.
//
//  Print the logo face UP and the bolt on the bed. No supports:
//  - every edge is a 45 deg chamfer, so no rounded edge overhangs the bed
//  - symbols on the four side faces are cut with 45 deg walls (a V-ish
//    engrave), so the top edge of each stroke self-supports instead of
//    bridging
//  - the top face is cut straight: it faces up, so nothing overhangs, and
//    straight walls keep the logo's lakes sharp
//  - the bed face is the one place anything bridges: the floor of the bolt,
//    which is narrow on purpose
//
//  Colouring: wipe acrylic paint into the symbols and scrape the faces clean,
//  or print `part = "inlay"` as a second body and give it its own filament.
// ============================================================================
version = "0.1";
use <fonts/BarlowSemiCondensed-SemiBold.ttf>   // bundled, OFL -- see fonts/OFL-Barlow.txt

/* [Part] */
part = "body"; // [body, inlay, preview]

/* [Die] */
die_size = 24.0;
chamfer  = 1.2;

/* [Symbols] */
depth     = 0.8;            // engrave depth on every face
logo_file = "glg_logo.svg";
logo_aspect = 178.618 / 133.412;
logo_w    = 18.0;
font      = "Barlow Semi Condensed:style=SemiBold";
text_w    = 18.0;           // width of the +1/+1 and -1/-1 faces, at the surface

// Face -> symbol. Faces are 1 = +z (printed up) 6 = -z (on the bed)
// 2 = +x  5 = -x  3 = +y  4 = -y. Opposites: 1/6, 2/5, 3/4.
// kinds: ["logo"], ["text", "..."], ["poison"], ["shield"], ["bolt"], ["blank"]
faces = [
    [1, ["logo"]],
    [6, ["bolt"]],
    [2, ["text", "+1/+1"]],
    [5, ["text", "−1/−1"]],     // a real minus, not a hyphen
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
// Rotations above leave each side face's "up" pointing along the die's +z or
// sideways; this extra spin per face makes every symbol read upright when the
// die sits logo-up.
function face_spin(n) = n == 2 ? 90 : n == 5 ? -90 : n == 3 ? 180 : 0;
module on_face(n) {
    rotate(face_rot(n)) translate([0, 0, s/2]) rotate(face_spin(n)) children();
}

// -------------------------------------------------------------- symbols 2d ---
module poison2d() {     // a phi: an oval ring through a vertical bar
    difference() { scale([1.15, 1]) circle(r = 5.0); scale([1.15, 1]) circle(r = 3.3); }
    square([1.8, 15], center = true);
}
module shield2d() {     // heater shield: flat top, two arcs meeting at a point
    R = 9.75;           // the arc through (6, 1) and (0, -8)
    a_end = atan2(-9, 3.75);
    right = [for (a = [0 : -3 : a_end]) [-3.75 + R*cos(a), 1 + R*sin(a)]];
    left  = [for (i = [len(right)-1 : -1 : 0]) [-right[i][0], right[i][1]]];
    difference() {
        polygon(concat([[-6, 7], [6, 7]], right, [[0, -8]], left));
        // an inner panel, so it reads as a shield and not a blob
        offset(delta = -1.6) polygon(concat([[-6, 7], [6, 7]], right, [[0, -8]], left));
    }
}
module bolt2d() {       // a plain zigzag; narrow, because it bridges on the bed
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

// ------------------------------------------------------------- symbols 3d ---
// Straight-walled cut, for faces where nothing can overhang (top, bed).
module cut_straight(k) {
    translate([0, 0, -depth]) linear_extrude(height = depth + 1) symbol2d(k);
}
// 45 deg-walled cut for the side faces, as 0.1 mm terraces (no roof() in
// 2021.01): the surface outline is exactly the symbol, and each step down is
// inset 0.1 mm. A stroke narrower than 2 x depth just bottoms out as a V
// groove instead of growing -- the first version flared OUTWARD and smeared
// the +1/+1 into a blob. Every step faces up in print.
v_step = 0.1;
module cut_flared(k) {
    n = round(depth / v_step);
    for (i = [0 : n - 1])
        translate([0, 0, -(i + 1) * v_step])
            linear_extrude(height = v_step + (i == 0 ? 1 : eps))
                offset(delta = -i * v_step) symbol2d(k);
}
function is_side(n) = n >= 2 && n <= 5;
module cut(n, k) { if (is_side(n)) cut_flared(k); else cut_straight(k); }

// The inlay is the cut, clipped to the die: it fills each recess flush.
module inlay() {
    intersection() {
        chamfered_cube();
        union() for (f = faces) if (f[1][0] != "blank") on_face(f[0]) cut(f[0], f[1]);
    }
}
module body() {
    difference() {
        chamfered_cube();
        for (f = faces) if (f[1][0] != "blank") on_face(f[0]) cut(f[0], f[1]);
    }
}

// ------------------------------------------------------------------ render ---
translate([0, 0, s/2]) {
    if (part == "body") body();
    else if (part == "inlay") inlay();
    else if (part == "preview") {
        color("#efe7d6") render() body();
        color("#6b3fa0") render() inlay();
    }
}
