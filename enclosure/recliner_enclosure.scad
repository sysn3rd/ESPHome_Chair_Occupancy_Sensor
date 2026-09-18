// Recliner occupancy sensor enclosure
// Seeed XIAO ESP32S3 + FPC antenna + pad cable splices (or an optional JST pair)
// License: CC BY-SA 4.0 (see LICENSE-CC-BY-SA-4.0.md)
//
// Render one part at a time:
//   openscad -D 'part="base"' -o base.stl recliner_enclosure.scad
//   openscad -D 'part="lid"'  -o lid.stl  recliner_enclosure.scad
//   openscad -D 'part="test"' -o test.stl recliner_enclosure.scad   (USB-C fit test)
//
// part="layout" shows the base with approximate stand-in parts (board, antenna,
// cables, JST, zip ties, wiring). Use Preview (F5); the stand-ins are not printed.
//
// Coordinates: origin is the inside corner of the floor at the USB-C end.
// X runs from the USB-C wall toward the antenna bay, Y across, Z up.

part = "layout"; // layout | assembly | base | lid | test
show_lid = false;     // layout view: draw the lid as a transparent ghost
show_labels = true;   // layout view: floating text labels

$fn = 48;
eps = 0.01;

// ---------- Shell ----------
wall  = 2.0;
floor_t = 2.0;
lid_t = 2.0;
in_L = 71;   // interior length (X)
in_W = 50;   // interior width (Y)
in_H = 11;   // interior height, floor top to lid underside
corner_r = 3;

// ---------- XIAO ESP32S3 ----------
pcb_L = 21.0;
pcb_W = 17.8;
pcb_gap_front = 0.3;   // PCB edge to inside of USB wall
pcb_y = 15;            // PCB centerline in Y
platform_h = 2.5;      // raised pad the board sits on
tape_t = 1.0;          // double-sided foam tape under the board
locator_h = 2.5;       // how far corner locators rise above the board bottom

// USB-C opening, sized for a cable overmold, not the bare receptacle
usb_open_w = 12.5;
usb_open_h = 7.5;
usb_center_above_pcb_bottom = 2.7;  // from the Seeed case: port sits ~1.1 above floor, ~3.2 tall

// ---------- Pad cable and JST ----------
cable_w = 10.0;        // measure with calipers
cable_t = 5.0;
cable_y = 38;          // cable centerline in Y
cable_clear = 0.4;     // added to each notch dimension
cable_squeeze = 0.3;   // lid tongue presses this far into the jacket
anchor_x = 8;          // zip tie anchor block start
anchor_len = 6;
anchor_h = 3.5;        // cable rides on top of this block
tie_tunnel_w = 3.5;    // for 2.5 mm zip ties
tie_tunnel_h = 2.0;

jst_gap = 8.0;         // space between cradle rails: holds the three soldered splices or a JST pair
jst_x0 = 18;
jst_len = 20;
jst_rail_t = 1.2;
jst_rail_h = 4;

// ---------- Antenna bay ----------
rib_x = 42;
rib_t = 1.2;
rib_h = 3;
rib_gap = 8;           // U.FL cable passes here, centered on pcb_y

// ---------- Lid screws (M3 self-tapping into PLA) ----------
boss_d = 7;
boss_inset = 2;        // boss center from inside corner
pilot_d = 2.5;
screw_clear_d = 3.4;
lip_h = 1.5;
lip_t = 1.2;
lip_clear = 0.25;

// ---------- USB cable tie tab ----------
tab_len = 10;
tab_w = 20;
tab_t = 3;
tie_slot = [3.2, 1.8];  // X (band width), Y (band thickness)
tie_slot_offset = 5;    // slot centers from the USB centerline
tie_groove_d = 1.5;

// ---------- Helpers ----------
module rounded_box(size, r) {
    hull() for (x = [r, size[0] - r], y = [r, size[1] - r])
        translate([x, y, 0]) cylinder(r = r, h = size[2]);
}

boss_pts = [[boss_inset, boss_inset], [boss_inset, in_W - boss_inset],
            [in_L - boss_inset, boss_inset], [in_L - boss_inset, in_W - boss_inset]];

usb_z = platform_h + tape_t + usb_center_above_pcb_bottom;
notch_bottom = anchor_h;
tongue_bottom = anchor_h + cable_t - cable_squeeze;

// ---------- Base ----------
module shell() {
    difference() {
        translate([-wall, -wall, -floor_t])
            rounded_box([in_L + 2 * wall, in_W + 2 * wall, floor_t + in_H], corner_r);
        cube([in_L, in_W, in_H + eps]);
    }
}

module usb_cut() {
    translate([-wall - eps, pcb_y, usb_z])
        rotate([0, 90, 0])
        hull() for (dy = [-(usb_open_w - usb_open_h) / 2, (usb_open_w - usb_open_h) / 2])
            translate([0, dy, 0]) cylinder(d = usb_open_h, h = wall + 2 * eps);
}

module cable_notch() {
    translate([-wall - eps, cable_y - (cable_w + cable_clear) / 2, notch_bottom])
        cube([wall + 2 * eps, cable_w + cable_clear, in_H]);
}

module board_platform() {
    translate([2, pcb_y - 7, 0]) cube([pcb_L - 4, 14, platform_h]);
}

module box2(a, b) {  // cube between two corner points
    translate([min(a[0], b[0]), min(a[1], b[1]), min(a[2], b[2])])
        cube([abs(b[0] - a[0]), abs(b[1] - a[1]), abs(b[2] - a[2])]);
}

// L-shaped stops at the two corners away from the USB-C port.
// They touch only the last ~1.5 mm of each long edge, clear of the castellated pads.
module board_locators() {
    top = platform_h + tape_t + locator_h;
    back = pcb_gap_front + pcb_L + 0.3;
    for (s = [-1, 1]) {
        edge = pcb_y + s * (pcb_W / 2 + 0.2);
        box2([back, pcb_y + s * (pcb_W / 2 - 3), 0], [back + 1.5, edge + s * 1.5, top]);
        box2([back - 1.5, edge, 0], [back + 1.5, edge + s * 1.5, top]);
    }
}

module tie_anchor() {
    difference() {
        translate([anchor_x, cable_y - cable_w / 2, 0])
            cube([anchor_len, cable_w, anchor_h]);
        translate([anchor_x + (anchor_len - tie_tunnel_w) / 2, cable_y - cable_w / 2 - eps, -eps])
            cube([tie_tunnel_w, cable_w + 2 * eps, tie_tunnel_h + eps]);
    }
}

module jst_cradle() {
    for (s = [-1, 1])
        translate([jst_x0, cable_y + s * (jst_gap / 2) + (s > 0 ? 0 : -jst_rail_t), 0])
            cube([jst_len, jst_rail_t, jst_rail_h]);
}

module antenna_rib() {
    difference() {
        translate([rib_x, 0, 0]) cube([rib_t, in_W, rib_h]);
        translate([rib_x - eps, pcb_y - rib_gap / 2, -eps]) cube([rib_t + 2 * eps, rib_gap, rib_h + 2 * eps]);
    }
}

module bosses() {
    for (p = boss_pts) translate([p[0], p[1], 0])
        difference() {
            cylinder(d = boss_d, h = in_H);
            translate([0, 0, 2]) cylinder(d = pilot_d, h = in_H);
        }
}

// Floor-level tab outside the USB-C wall. Zip tie the power cable here so a tug
// never reaches the XIAO's USB-C receptacle.
module usb_tie_tab() {
    slot_x = -wall - tab_len / 2;
    difference() {
        translate([-wall - tab_len, pcb_y - tab_w / 2, -floor_t])
            cube([tab_len + eps, tab_w, tab_t]);
        for (s = [-1, 1])
            translate([slot_x - tie_slot[0] / 2, pcb_y + s * tie_slot_offset - tie_slot[1] / 2, -floor_t - eps])
                cube([tie_slot[0], tie_slot[1], tab_t + 2 * eps]);
        // underside groove so the tie band stays flush with the Velcro
        translate([slot_x - tie_slot[0] / 2, pcb_y - tie_slot_offset - tie_slot[1] / 2, -floor_t - eps])
            cube([tie_slot[0], 2 * tie_slot_offset + tie_slot[1], tie_groove_d + eps]);
    }
}

module base() {
    difference() {
        union() {
            shell();
            bosses();
            board_platform();
            board_locators();
            tie_anchor();
            jst_cradle();
            antenna_rib();
            usb_tie_tab();
        }
        usb_cut();
        cable_notch();
        // keep pilot holes open where bosses meet the shell
        for (p = boss_pts) translate([p[0], p[1], 2]) cylinder(d = pilot_d, h = in_H);
    }
}

// ---------- Lid ----------
// Modeled in place (underside at z = in_H). Flipped for printing in "lid" mode.
module lid() {
    difference() {
        union() {
            translate([-wall, -wall, in_H])
                rounded_box([in_L + 2 * wall, in_W + 2 * wall, lid_t], corner_r);
            // locating lip just inside the walls
            difference() {
                translate([lip_clear, lip_clear, in_H - lip_h])
                    cube([in_L - 2 * lip_clear, in_W - 2 * lip_clear, lip_h + eps]);
                translate([lip_clear + lip_t, lip_clear + lip_t, in_H - lip_h - eps])
                    cube([in_L - 2 * (lip_clear + lip_t), in_W - 2 * (lip_clear + lip_t), lip_h + 3 * eps]);
                for (p = boss_pts) translate([p[0], p[1], in_H - lip_h - eps])
                    cylinder(d = boss_d + 1, h = lip_h + 3 * eps);
            }
            // tongue that fills the cable notch and clamps the jacket
            translate([-wall + 0.2, cable_y - (cable_w + cable_clear) / 2 + 0.2, tongue_bottom])
                cube([wall - 0.2 + lip_clear + lip_t, cable_w + cable_clear - 0.4, in_H - tongue_bottom + eps]);
        }
        for (p = boss_pts) translate([p[0], p[1], in_H - lip_h - 1])
            cylinder(d = screw_clear_d, h = lid_t + lip_h + 2);
        // vent slots over the board
        for (i = [0 : 3])
            translate([5 + i * 4, pcb_y - 6, in_H - eps])
                hull() for (dy = [0, 12]) translate([0, dy, 0]) cylinder(d = 1.6, h = lid_t + 2 * eps);
    }
}

// ---------- USB-C fit test ----------
// Prints the USB end wall, platform and locators only. Check the plug seats fully.
module test_piece() {
    intersection() {
        base();
        translate([-wall - tab_len - 1, -wall - 1, -floor_t - 1]) cube([wall + tab_len + 27, 32, in_H + floor_t + 2]);
    }
}

// ---------- Layout stand-ins (approximate, for visualizing only) ----------
module wire(pts, d = 1.2) {
    for (i = [0 : len(pts) - 2]) hull() {
        translate(pts[i]) sphere(d = d, $fn = 12);
        translate(pts[i + 1]) sphere(d = d, $fn = 12);
    }
}

module label(txt, pos, size = 2.2) {
    if (show_labels)
        color("Black") translate(pos) linear_extrude(0.2)
            text(txt, size = size, halign = "center", valign = "center");
}

pcb_x0 = pcb_gap_front;
pcb_z0 = platform_h + tape_t;   // bottom of PCB
pcb_t = 1.0;
pcb_top = pcb_z0 + pcb_t;
function pad_x(n) = pcb_x0 + 2.88 + n * 2.54;   // n = 0..6 from the USB-C end
low_edge = pcb_y - pcb_W / 2;
high_edge = pcb_y + pcb_W / 2;

// Standard XIAO layout, component side up, USB-C end first:
//   low-Y edge : D0 D1 D2 D3 D4 D5 D6
//   high-Y edge: 5V GND 3V3 D10 D9 D8 D7
// Confirm against the labels printed on your board before soldering.
d3_pad  = [pad_x(3), low_edge, pcb_top];
gnd_pad = [pad_x(1), high_edge, pcb_top];
d4_pad  = [pad_x(4), low_edge, pcb_top];

module xiao() {
    color("White", 0.9) translate([2, pcb_y - 7, platform_h]) cube([pcb_L - 4, 14, tape_t]);   // foam tape
    color("RoyalBlue") translate([pcb_x0, low_edge, pcb_z0]) cube([pcb_L, pcb_W, pcb_t]);
    color("Silver") translate([pcb_x0 + 7.5, pcb_y - 7, pcb_top]) cube([12.5, 14, 2.4]);          // RF shield (approx.)
    color("Silver") translate([pcb_x0 - 0.3, pcb_y - 4.47, pcb_top]) cube([7.35, 8.94, 3.26]);    // USB-C receptacle
    color("Gold") translate([pcb_x0 + pcb_L - 2.5, low_edge + 2.5, pcb_top]) cylinder(d = 2, h = 1.2); // U.FL (approx.)
    for (n = [0 : 6], e = [low_edge, high_edge])
        color("Goldenrod") translate([pad_x(n) - 0.75, e - 0.6, pcb_top]) cube([1.5, 1.2, 0.05]);
    color("Red") translate(d3_pad - [0.9, 0.7, 0]) cube([1.8, 1.4, 0.3]);
    color("Green") translate(gnd_pad - [0.9, 0.7, 0]) cube([1.8, 1.4, 0.3]);
    color("Gold") translate(d4_pad - [0.9, 0.7, 0]) cube([1.8, 1.4, 0.3]);
}

module antenna() {
    color("Peru") translate([rib_x + rib_t + 2, (in_W - 40) / 2, 0]) cube([20, 40, 0.3]);
    ufl = [pcb_x0 + pcb_L - 2.5, low_edge + 2.5, pcb_top + 1.2];
    color("DimGray") wire([ufl, ufl + [3, 0, 1], [rib_x - 2, pcb_y - 2, 3.5], [rib_x + 3, pcb_y, 3.5],
                           [rib_x + 8, pcb_y + 6, 1.5], [rib_x + 14, pcb_y + 3, 0.6]], d = 1.13);
}

module usb_plug() {
    color("DarkSlateGray") translate([-wall - 20, pcb_y - 6, usb_z - 3.25]) cube([20 + wall, 12, 6.5]);   // overmold
    color("Silver") translate([0, pcb_y - 4.1, usb_z - 1.2]) cube([6.5, 8.2, 2.4]);                      // plug shell
    color("DarkSlateGray") wire([[-wall - 20, pcb_y, usb_z], [-wall - 28, pcb_y, -floor_t + tab_t + 2],
                                 [-wall - 45, pcb_y, -floor_t + tab_t + 2]], d = 4);
    // zip tie on the outside tab
    color("Black") translate([-wall - tab_len / 2 - 1.25, pcb_y - tie_slot_offset, -floor_t])
        difference() {
            translate([0, -0.5, 0]) cube([2.5, 2 * tie_slot_offset + 1, tab_t + 5]);
            translate([-eps, 0.5, tie_groove_d - 0.6 + 1]) cube([2.5 + 2 * eps, 2 * tie_slot_offset - 1, tab_t + 2.5]);
        }
}

module pad_cable() {
    jacket_end = anchor_x + anchor_len + 2;
    color("Gainsboro") translate([-wall - 30, cable_y - cable_w / 2, anchor_h]) cube([30 + wall + jacket_end, cable_w, cable_t - cable_squeeze]);
    // zip tie through the anchor tunnel and over the jacket
    color("Black") translate([anchor_x + anchor_len / 2 - 1.25, 0, 0])
        difference() {
            translate([0, cable_y - cable_w / 2 - 1.1, 0.2]) cube([2.5, cable_w + 2.2, anchor_h + cable_t + 0.8]);
            translate([-eps, cable_y - cable_w / 2, 1.3]) cube([2.5 + 2 * eps, cable_w, anchor_h + cable_t - 1.3 - cable_squeeze]);
        }
    // pad conductors to the JST plug
    jst_in = jst_x0 + (jst_len - 12) / 2;
    color("Gray") wire([[jacket_end, cable_y - 1, anchor_h + 2], [jst_in - 2, cable_y - 1, 3], [jst_in, cable_y - 1, 2.2]]);
    color("Gray") wire([[jacket_end, cable_y + 1, anchor_h + 2], [jst_in - 2, cable_y + 1, 3], [jst_in, cable_y + 1, 2.2]]);
    color("Gray") wire([[jacket_end, cable_y + 3, anchor_h + 2], [jst_in - 2, cable_y + 3, 3], [jst_in, cable_y + 2.6, 2.2]]);
}

module jst_pair() {
    x = jst_x0 + (jst_len - 12) / 2;
    color("WhiteSmoke") translate([x, cable_y - 3, 0]) cube([6, 6, 4.5]);
    color("Tan") translate([x + 6, cable_y - 3, 0]) cube([6, 6, 4.5]);
}

module board_wiring() {
    out = jst_x0 + (jst_len - 12) / 2 + 12;
    // GND: short run across to the high-Y edge
    // Pad green: to GND on the far edge
    color("Green") wire([[out, cable_y + 1, 2.2], [out + 3, cable_y + 1, 6], [out - 4, 29, 8],
                         [gnd_pad[0] + 3, high_edge + 3, 7], gnd_pad + [0, 1.5, 2], gnd_pad]);
    // D3: around the antenna end of the board to the low-Y edge, through the 1k resistor
    color("Red") wire([[out, cable_y - 1, 2.2], [out + 3, cable_y - 1, 6], [out + 4, 22, 8],
                       [27, 12, 8], [26, 3, 7], [22, 2.5, 7]]);
    color("Red") wire([[14, 2.5, 7], [d3_pad[0], 2.5, 7], d3_pad + [0, -1.5, 2], d3_pad]);
    color("Tan") translate([15, 2.5, 7]) rotate([0, 90, 0]) cylinder(d = 2.4, h = 6);        // 1k resistor
    color("DarkRed", 0.6) translate([13.5, 2.5, 7]) rotate([0, 90, 0]) cylinder(d = 3, h = 9); // heat shrink
    // Pad yellow: cable check to D4, next to D3 on the same edge, through a second 1k resistor
    color("Gold") wire([[out, cable_y + 2.6, 2.2], [out + 5, cable_y + 2.6, 6.5], [out + 7, 22, 9.5],
                        [29, 9, 9.5], [26, 5.5, 9.5]]);
    color("Gold") wire([[17, 5.5, 9.5], [d4_pad[0] + 2, 5.5, 9.5], d4_pad + [0, -1.5, 2.5], d4_pad]);
    color("Tan") translate([18.5, 5.5, 9.5]) rotate([0, 90, 0]) cylinder(d = 2.4, h = 6);     // 1k resistor
    color("Goldenrod", 0.6) translate([17, 5.5, 9.5]) rotate([0, 90, 0]) cylinder(d = 3, h = 9); // heat shrink
}

module screws() {
    for (p = boss_pts) color("DimGray") translate([p[0], p[1], in_H + 0.5]) {
        translate([0, 0, lid_t]) cylinder(d = 5.5, h = 2);
        translate([0, 0, lid_t - 8]) cylinder(d = 3, h = 8);
    }
}

module velcro() {
    color("#333") translate([4, 4, -floor_t - 2]) cube([in_L - 8, in_W - 8, 2]);
}

module layout() {
    color("Khaki") base();
    xiao();
    antenna();
    usb_plug();
    pad_cable();
    jst_pair();
    board_wiring();
    velcro();
    if (show_lid) { color("SkyBlue", 0.35) translate([0, 0, 0.5]) lid(); screws(); }
    lz = in_H + 4;
    label("XIAO ESP32S3", [pcb_x0 + pcb_L / 2, pcb_y, lz]);
    label("D3", [d3_pad[0] - 1.5, low_edge - 4, lz], 2);
    label("D4", [d4_pad[0] + 2, low_edge - 4, lz], 2);
    label("GND", [gnd_pad[0], high_edge + 2, lz], 2);
    label("1k x2", [19, -3, lz], 2);
    label("USB-C", [-wall - 14, pcb_y + 9, lz]);
    label("PAD CABLE", [-wall - 16, cable_y + 8, lz]);
    label("TIE ANCHOR", [anchor_x + anchor_len / 2, cable_y + 9, lz], 1.8);
    label("SPLICES", [jst_x0 + jst_len / 2, cable_y - 7, lz]);
    label("FPC ANTENNA", [rib_x + 13, in_W / 2, lz]);
}

if (part == "base") base();
else if (part == "lid") translate([0, 0, in_H + lid_t]) rotate([180, 0, 0]) lid();  // top face down on the bed
else if (part == "test") test_piece();
else if (part == "assembly") { base(); color("SkyBlue", 0.5) translate([0, 0, 0.5]) lid(); }
else if (part == "layout") {
    // Stand-ins, colors and labels only make sense in Preview (F5).
    if ($preview) layout();
    else { echo("Layout view is preview only. Press F5 to see components. Showing the base."); base(); }
}
