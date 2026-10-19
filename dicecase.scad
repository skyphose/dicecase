// ============================================================================
//  dicecase  --  a snap-shut clamshell dice case, three variants
// ----------------------------------------------------------------------------
//  Two separate halves split at the dice midline. A rim on the bottom clicks
//  into a rebate in the top, beaded along both long sides. No hardware.
//
//  The variants answer "what are you carrying?":
//    grid    6 x 24 mm d6, two across          59.6 x  88.0 x 26.7 mm
//    row     6 x 24 mm d6, one line            31.2 x 173.2 x 26.7 mm
//    mixed   6 x 24 mm + 6 x 16 mm d6          64.0 x 128.8 x 26.7 mm
//  Everything else -- the rim, the bead, the thumb dishes, the depth budget
//  -- is shared, so a fix to one is a fix to all three.
//
//  The dice are a second register: each sits half in the bottom and half in
//  the top. Open, every die stands half proud of the bottom -- which is why
//  deckblock's push-out holes and pinch notches are gone.
//
//  Print both halves flat, outer face down, parting face up. No supports.
// ============================================================================
version = "0.5";

/* [Variant] */
variant = "grid";   // [grid, row, mixed, custom]

/* [Part to render] */
part = "bottom"; // [bottom, top, closed, open]

/* [Dice] */
die_size      = 24.0;   // across flats of one d6 -- CALIPER YOURS
small_die     = 16.0;   // the deckblock-size d6, for the mixed layout
die_clearance = 0.8;    // TOTAL added to die_size -> 0.4 per side (deckblock)
die_headroom  = 0.3;    // TOTAL extra depth, split across the two halves

/* [Shell] */
// 3.2 rather than 2.5: the wall now has to hold a 1.6 mm outer skin AND the
// rim that clicks inside it.
wall      = 3.2;
side_gap  = 3.6;
band_gap  = 3.6;
floor_t   = 1.2;
corner_relief = 2.0;
lead_in   = 0.8;        // guides each die's top half into the lid as it closes

/* [Snap rim] */
// The rim stands up off the bottom half and drops into a rebate in the top
// half's wall. A 45 deg diamond bead on its outer face clicks into a matching
// groove in the top's skin.
skin_t    = 1.6;        // the top's outer skin that the rim sits inside
rim_c     = 0.15;       // gap between rim and skin, per side
rim_t     = 1.2;
rim_h     = 4.0;        // taller = more flex for the same click
// Interference = bead_h - rim_c = 0.15 mm. Like deckblock's detent, the bead
// has to beat the slop before it does anything: bead_h must exceed rim_c.
// Over a 4 mm tall, 1.2 mm rim that is ~1.7% strain at the root, inside PLA's
// elastic range. Too stiff: lower bead_h. Too weak: raise it.
bead_h    = 0.30;
rim_ch    = 0.8;        // 45 deg chamfer on the rim's top outer edge: the
                        // ramp that leads the top's skin onto the bead
bead_end  = 6.0;        // bead stops this far short of each corner, where the
                        // rim cant flex
rebate_c  = 0.2;        // extra depth and inner clearance in the top's rebate

/* [Thumb dish] */
thumb_r     = 9.0;
// 2.0, not 2.5: with six dice every edge has a pocket right behind the wall,
// and 2.5 into a 3.2 wall left 0.7 mm at the bottom of the dish. 2.0 leaves 1.2.
thumb_bite  = 2.0;

/* [Hidden] */
$fa = 2; $fs = 0.4;
eps = 0.01;

// ============================================================================
//  Band layout model (deckblock's)
// ============================================================================
// Every die sits half in each shell, centred on the parting plane, so a
// pocket's depth per half is half its die. A small die in a case sized for
// big ones just gets a shallower pocket and a thicker floor under it.
function d6(sz = die_size) =
    ["sq", sz + die_clearance, sz + die_clearance, (sz + die_headroom) / 2];

grid_bands = [
    [[ d6(), d6() ], band_gap, side_gap],
    [[ d6(), d6() ], band_gap, side_gap],
    [[ d6(), d6() ], 0,        side_gap],
];
row_bands = [
    [[ d6() ], band_gap, side_gap],
    [[ d6() ], band_gap, side_gap],
    [[ d6() ], band_gap, side_gap],
    [[ d6() ], band_gap, side_gap],
    [[ d6() ], band_gap, side_gap],
    [[ d6() ], 0,        side_gap],
];
// Six big dice over six small ones -- this case's six plus deckblock's six.
mixed_bands = [
    [[ d6(), d6() ], band_gap, side_gap],
    [[ d6(), d6() ], band_gap, side_gap],
    [[ d6(), d6() ], band_gap, side_gap],
    [[ d6(small_die), d6(small_die), d6(small_die) ], band_gap, side_gap],
    [[ d6(small_die), d6(small_die), d6(small_die) ], 0,        side_gap],
];
custom_bands = [
    [[ d6(), d6(), d6() ], band_gap, side_gap],
    [[ d6(), d6()       ], 0,        side_gap],
];
bands = variant == "grid"  ? grid_bands
      : variant == "row"   ? row_bands
      : variant == "mixed" ? mixed_bands
      :                      custom_bands;

function sum(v, i = 0) = i >= len(v) ? 0 : v[i] + sum(v, i + 1);
function b_cells(b) = b[0];
function b_h(b)     = max([for (c = b_cells(b)) c[2]]);
function b_w(b)     = sum([for (c = b_cells(b)) c[1]]) + (len(b_cells(b)) - 1) * b[2];

// ---------------------------------------------------------------- derived ---
field_w = max([for (b = bands) b_w(b)]);
field_h = sum([for (b = bands) b_h(b)]) + sum([for (k = [0:len(bands)-2]) bands[k][1]]);
case_w  = 2*wall + field_w;
case_h  = 2*wall + field_h;
pd      = max([for (b = bands, c = b_cells(b)) c[3]]);   // deepest pocket
H       = floor_t + pd;

rim_o   = skin_t + rim_c;           // rim outer face, inset from the case edge
rim_i   = rim_o + rim_t;            // rim inner face

function band_top(k) = k == 0 ? case_h - wall
                              : band_top(k-1) - b_h(bands[k-1]) - bands[k-1][1];
function cell_x(b, i) = wall + (field_w - b_w(b)) / 2
                      + sum([for (j = [0:1:i-1]) b_cells(b)[j][1] + b[2]]);
function cell_y(k, c) = band_top(k) - b_h(bands[k]) + (b_h(bands[k]) - c[2]) / 2;

// Where the bead runs: both long edges. [side, y0, y1]; side +1 = the
// x = case_w edge, -1 = the x = 0 edge.
by0 = wall + bead_end;
by1 = case_h - wall - bead_end;
bead_runs = [[ 1, by0, by1], [-1, by0, by1]];
// Thumb dishes on the two ends: [x, y] centre on the parting plane, pushed
// out past the edge.
thumbs = [[case_w/2, -thumb_r + thumb_bite], [case_w/2, case_h + thumb_r - thumb_bite]];

// ------------------------------------------------------------- primitives ---
module outer_shape(w, h, cr) {
    polygon([[cr,0],[w-cr,0],[w,cr],[w,h-cr],[w-cr,h],[cr,h],[0,h-cr],[0,cr]]);
}
module ring(o1, o2) {           // band between two insets of the outline
    difference() {
        offset(delta = -o1) outer_shape(case_w, case_h, corner_relief);
        offset(delta = -o2) outer_shape(case_w, case_h, corner_relief);
    }
}

// 45 deg diamond prism along y, its widest point at (x, z), pointing in `dir`
// (+1 = +x). Both of its sloped faces are at 45 deg, so as a bead or as a
// groove it prints without support.
module diamond(x, z, h, y0, y1, dir) {
    translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(height = y1 - y0)
        polygon([[x - dir*eps, z - h], [x + dir*h, z], [x - dir*eps, z + h]]);
}

// ------------------------------------------------------------------ half ----
// Built in assembly coordinates: z from -H (outer face) to 0 (parting plane).
// top = false -> bottom (rim, bead)
// top = true  -> top    (rebate, groove)
module half(top) {
    difference() {
        union() {
            translate([0, 0, -H]) linear_extrude(height = H)
                outer_shape(case_w, case_h, corner_relief);
            if (!top) {
                // The rim, gapped at each thumb dish, where it would
                // otherwise stand over the dish with nothing under it.
                // chamfer as 0.1 mm terraces: no roof() in 2021.01, and every
                // step faces up
                steps = round(rim_ch / 0.1);
                for (j = [0 : steps])
                    let (z0 = j == 0 ? 0 : rim_h - rim_ch + (j - 1) * rim_ch / steps,
                         h  = j == 0 ? rim_h - rim_ch + eps : rim_ch / steps + eps,
                         o  = j == 0 ? rim_o : rim_o + j * rim_ch / steps)
                    translate([0, 0, z0]) linear_extrude(height = h) difference() {
                        ring(o, rim_i);
                        for (t = thumbs) translate([t[0], t[1]]) circle(r = thumb_r + 0.3);
                    }
                for (r = bead_runs)
                    diamond(r[0] > 0 ? case_w - rim_o : rim_o, rim_h / 2, bead_h,
                            r[1], r[2], r[0]);
            }
        }

        // Pockets, each with a lead-in clipped to inside the wall.
        for (k = [0:len(bands)-1], i = [0:len(b_cells(bands[k]))-1]) {
            c = b_cells(bands[k])[i];
            x = cell_x(bands[k], i);
            y = cell_y(k, c);
            translate([x, y, -c[3]]) cube([c[1], c[2], c[3] + rim_h + 1]);
            intersection() {
                translate([wall, wall, -lead_in - 1])
                    cube([case_w - 2*wall, case_h - 2*wall, lead_in + 2]);
                translate([x + c[1]/2, y + c[2]/2, -lead_in])
                    linear_extrude(height = lead_in + eps,
                                   scale = [(c[1] + 2*lead_in)/c[1], (c[2] + 2*lead_in)/c[2]])
                        square([c[1], c[2]], center = true);
            }
        }

        if (top) {
            // Rebate for the rim, and the groove the bead clicks into.
            translate([0, 0, -(rim_h + rebate_c)])
                linear_extrude(height = rim_h + rebate_c + eps)
                    ring(skin_t, rim_i + rebate_c);
            for (r = bead_runs)
                diamond(r[0] > 0 ? case_w - skin_t : skin_t, -rim_h / 2,
                        bead_h + 0.05, r[1] - 0.5, r[2] + 0.5, r[0]);
        }

        // Thumb dishes, below the parting plane only: the rim above it stays
        // whole, and every cut face looks upward in print.
        for (t = thumbs)
            intersection() {
                translate([t[0], t[1], 0]) sphere(r = thumb_r);
                translate([-50, -50, -thumb_r - 1]) cube([case_w + 100, case_h + 100, thumb_r + 1]);
            }
    }
}

// ------------------------------------------------------------------ render ---
if (part == "bottom") translate([0, 0, H]) half(false);
else if (part == "top") translate([0, 0, H]) half(true);
else if (part == "closed") {
    color("#7d99ad") render() half(false);
    color("#d8a13a") mirror([0, 0, 1]) render() half(true);
}
else if (part == "open") {
    color("#7d99ad") render() half(false);
    color("#d8a13a") translate([-case_w - 10, 0, 0]) render() half(true);
}

// ------------------------------------------------------------------- report ---
echo(str("variant = ", variant));
echo(str("case = ", case_w, " x ", case_h, " x ", 2*H, " mm closed"));
echo(str("half = ", H, " mm, deepest pocket per half = ", pd));
echo(str("bead interference = ", bead_h - rim_c, " mm"));
