/* [Array] */
// Show panels
show_panel_dummies = false;
// Number of panel columns in layout
panel_columns = 2;
// Number of panel rows in layout
panel_rows = 2;
// Bracket spacing
bracket_spacing = 4;
// Include centre brackets
centre_brackets = true;
// Horizontal edge brackets
horizontal_edge_brackets = true;
// Vertical edge brackets
vertical_edge_brackets = false;
// Include mid panel brackets
mid_panel_brackets = false;

/* [Panel] */
// Width of the matrix panel
matrix_width = 320;
// Height of the matrix panel
matrix_height = 160;
// Depth of the matrix panel
matrix_depth = 15;
// Width of the matrix frame
matrix_frame_width = 12;
// Depth of the matrix frame
matrix_frame_depth = 10;
//Frame has middle member
matrix_frame_has_middle = true;
// Screw shaft diameter
matrix_screw_shaft_size = 3;
// Screw head diameter
matrix_screw_head_size = 5.5;
// Distance screw centres are inset from matrix edges on the X axis
matrix_screw_inset_x = 8;
// Distance screw centres are inset from matrix edges on the Y axis
matrix_screw_inset_y = 8;
// Has pegs
matrix_has_pegs = false;
// Peg diameter
matrix_peg_diameter = 2;
// Peg height
matrix_peg_height = 3.5;
// Distance peg centres are inset from matrix edges on the X axis
matrix_peg_inset_x = 40;
// Distance peg centres are inset from matrix edges on the Y axis
matrix_peg_inset_y = 14;

/* [Bracket] */
// Thickness of the base of the bracket
bracket_base_thickness = 2;
// Thickness of the walls of the bracket
bracket_wall_thickness = 2;
// Height of the walls of the bracket
bracket_wall_height = 2;
// Radius of frame-fitting corners
bracket_corner_radius = 8;
// Length of the bracket extensions along the frame on the X axis
bracket_frame_extension_x = 32;
// Length of the bracket extensions along the frame on the Y axis
bracket_frame_extension_y = 24;
// Include centred screw holes
bracket_centred_screw_holes = false;

/* [Tweak] */
frame_tolerance = 0.25;
peg_tolerance = 0.25;
screw_tolerance = 0.25;
face_down = false;

module private() {}
//Frame middle member width
matrix_frame_middle_width = 2 * matrix_frame_width;

module mirror_copy(axes) {
  children();
  mirror(axes) children();
}

$fn = $preview ? 16 : 64;

function z_fix() = $preview ? 0.1 : 0;

// Matrix
module matrix() {
  module screw_hole(depth=10) {
    translate([0, 0, -depth]) cylinder(h=depth + z_fix(), d=matrix_screw_shaft_size + 2 * screw_tolerance);
  }
  
  difference() {
    union() {
      // Body
      linear_extrude(matrix_depth) square([matrix_width, matrix_height]);
      if (matrix_has_pegs) {
        // Pegs
        mirror([0, 0, 1]) {
          pegs = [
            [matrix_peg_inset_x, matrix_peg_inset_y], [matrix_width - matrix_peg_inset_x, matrix_peg_inset_y],
            [matrix_peg_inset_x, matrix_height - matrix_peg_inset_y], [matrix_width - matrix_peg_inset_x, matrix_height - matrix_peg_inset_y]
          ];
          for (i = pegs) {
            translate([i.x, i.y, 0]) cylinder(matrix_peg_height, d=matrix_peg_diameter);
          }
        }
      }
    }
    union() {
      // Cutouts
      cutout_width = matrix_frame_has_middle ? (matrix_width / 2) - matrix_frame_width - (matrix_frame_middle_width / 2) : matrix_width - (2 * matrix_frame_width);
      cutout_height = matrix_height - (2 * matrix_frame_width);
      translate([0, 0, -z_fix()]) linear_extrude(matrix_frame_depth + z_fix()) {
        translate([matrix_frame_width, matrix_frame_width]) square([cutout_width, cutout_height]);
        if (matrix_frame_has_middle) translate([(matrix_width / 2) + (matrix_frame_middle_width / 2), matrix_frame_width]) square([cutout_width, cutout_height]);
      }
      // Screws
      mirror([0, 0, 1]) {
        screws = [
          [matrix_screw_inset_x, matrix_screw_inset_y], [matrix_width - matrix_screw_inset_x, matrix_screw_inset_y],
          [matrix_screw_inset_x, matrix_height - matrix_screw_inset_y], [matrix_width - matrix_screw_inset_x, matrix_height - matrix_screw_inset_y],
          for (i = [[matrix_width / 2, matrix_screw_inset_y], [matrix_width / 2, matrix_height - matrix_screw_inset_y]]) if (false) i,
        ];
        for (i = screws) {
          translate([i.x, i.y, 0]) screw_hole();
        }
      }
    }
  }
}

function fragments_from_radius(radius) =
  ($fn > 0) ? ($fn >= 3 ? $fn : 3) :
  ceil(max(min(360 / $fa, radius * 2 * PI / $fs), 5));

module sector(radius, start_angle, end_angle, symmetrical = true) {
  delta = end_angle - start_angle;
  revolutions = delta / 360;
  segments = revolutions * fragments_from_radius(radius);
  segment_angle = delta / segments;
  whole_segments = floor(segments);
  whole_segment_offset = symmetrical ? (segments - whole_segments) / 2 * segment_angle : 0;
  points = [
    [0, 0],
    if (symmetrical && whole_segments < segments) [radius * cos(start_angle), radius * sin(start_angle)],
    for (i = [0:whole_segments]) let (angle = start_angle + whole_segment_offset + i * segment_angle) [radius * cos(angle), radius * sin(angle)],
    if (whole_segments < segments) [radius * cos(end_angle), radius * sin(end_angle)]
  ];
  polygon(points);
}

module arc(outer_radius, inner_radius, start_angle, end_angle) {
  difference() {
    sector(outer_radius, start_angle, end_angle);
    sector(inner_radius, start_angle, end_angle);
  }
}

bracket_quadrant_width = matrix_frame_width + bracket_frame_extension_x;
bracket_quadrant_height = matrix_frame_width + bracket_frame_extension_y;

// Bracket Quadrant
module bracket_quadrant(centre_screw_a = false, centre_screw_b = false) {
  tolerance = 0.125;
  bracket_top = bracket_base_thickness + bracket_wall_height;
  bracket_bottom = -bracket_wall_height;
  bracket_thickness = bracket_top - bracket_bottom;
  inner_corner_radius = max(bracket_corner_radius - bracket_wall_thickness, 0);

  // Bracket screw hole
  module screw_hole() {
    translate([0, 0, -(bracket_base_thickness + z_fix())]) cylinder(h=bracket_base_thickness + 2 * z_fix(), d=matrix_screw_shaft_size + 2 * screw_tolerance);
    cylinder(h=bracket_wall_height + z_fix(), d=matrix_screw_head_size + 2 * screw_tolerance);
  }
  
  module extension_end_cutter() {
    rotate([-90, 0, 0]) translate([0, -(bracket_thickness / 2 + bracket_base_thickness / 2), -z_fix()]) linear_extrude(matrix_frame_width + bracket_wall_thickness + 2 * z_fix()) difference () {
      translate([-z_fix(), -z_fix()]) square([bracket_thickness / 2 + z_fix(), bracket_thickness + 2 * z_fix()]);
      translate([bracket_thickness / 2, bracket_thickness / 2]) sector(bracket_thickness / 2, 90, 270);
    }
  }

  difference() {
    translate([0, 0, bracket_bottom]) union() {
      cube([bracket_quadrant_width - bracket_thickness / 2, bracket_quadrant_height - bracket_thickness / 2, bracket_thickness]);
      translate([0, bracket_quadrant_height - bracket_thickness / 2, bracket_thickness / 2]) rotate([0, 90, 0]) cylinder(bracket_quadrant_width, bracket_thickness / 2, bracket_thickness / 2);
      translate([bracket_quadrant_width - bracket_thickness / 2, 0, bracket_thickness / 2]) rotate([270, 0, 0]) cylinder(bracket_quadrant_height, bracket_thickness / 2, bracket_thickness / 2);
    }
    union() {
      sector_cutout_offset = matrix_frame_width + bracket_wall_thickness;
      sector_offset = sector_cutout_offset + inner_corner_radius;
      // Full depth cutouts
      // Corner cutout
      translate([0, 0, bracket_bottom - z_fix()]) linear_extrude(bracket_thickness + 2 * z_fix()) {
        difference() {
          corner_cutout_width = bracket_quadrant_width - (matrix_frame_width + bracket_wall_thickness);
          corner_cutout_offset_x = bracket_quadrant_width - corner_cutout_width;
          corner_cutout_height = bracket_quadrant_height - (matrix_frame_width + bracket_wall_thickness);
          corner_cutout_offset_y = bracket_quadrant_height - corner_cutout_height;
          translate([corner_cutout_offset_x, corner_cutout_offset_y]) square([corner_cutout_width + z_fix(), corner_cutout_height + z_fix()]);
          translate([sector_cutout_offset, sector_cutout_offset]) square([inner_corner_radius, inner_corner_radius]);
        }
        translate([sector_offset, sector_offset]) sector(inner_corner_radius, 180, 270);
      }
      // Top cutouts
      translate([0, 0, bracket_base_thickness]) linear_extrude(bracket_wall_height + z_fix()) difference() {
        union() {
          // Top centre
          translate([bracket_wall_thickness, bracket_wall_thickness]) square([matrix_frame_width, matrix_frame_width]);
          // Top extensions
          top_extension_cutout_width = bracket_frame_extension_x - bracket_wall_thickness + z_fix();
          top_extension_cutout_offset_x = bracket_quadrant_width - top_extension_cutout_width + z_fix();
          top_extension_cutout_height = bracket_frame_extension_y - bracket_wall_thickness + z_fix();
          top_extension_cutout_offset_y = bracket_quadrant_height - top_extension_cutout_height + z_fix();
          translate([top_extension_cutout_offset_x, bracket_wall_thickness]) square([top_extension_cutout_width, matrix_frame_width - bracket_wall_thickness]);
          translate([bracket_wall_thickness, top_extension_cutout_offset_y]) square([matrix_frame_width - bracket_wall_thickness, top_extension_cutout_height]);
          // Top sector
          difference() {
            translate([matrix_frame_width, matrix_frame_width]) square([bracket_corner_radius, bracket_corner_radius]);
            translate([sector_offset, sector_offset]) sector(bracket_corner_radius, 180, 270);
          }
        }
        union() {
          // Top diagonal wall
          diagonal_length = norm([matrix_frame_width + bracket_wall_thickness, matrix_frame_width + bracket_wall_thickness]) + norm([bracket_corner_radius, bracket_corner_radius]) - bracket_corner_radius;
          rotate([0, 0, -45]) translate([-bracket_wall_thickness / 2, 0]) square([bracket_wall_thickness, diagonal_length]);
          // Top screw surrounds
          screw_surround_radius = matrix_screw_head_size / 2 + screw_tolerance + bracket_wall_thickness;
          translate([matrix_screw_inset_x, matrix_screw_inset_y]) circle(screw_surround_radius);
          if (centre_screw_a) translate([0, matrix_screw_inset_y]) circle(screw_surround_radius);
          if (centre_screw_b) translate([matrix_screw_inset_x, 0]) circle(screw_surround_radius);
        }
      }
      // Bottom cutouts
      translate([0, 0, -bracket_wall_height - z_fix()]) linear_extrude(bracket_wall_height + z_fix()) union() {
        // Bottom centre
        translate([-z_fix(), -z_fix()]) square([matrix_frame_width + tolerance + z_fix(), matrix_frame_width + tolerance + z_fix()]);
        // Bottom extensions
        bottom_extension_cutout_offset_x = bracket_quadrant_width - bracket_frame_extension_x + z_fix();
        bottom_extension_cutout_offset_y = bracket_quadrant_height - bracket_frame_extension_y + z_fix();
        translate([bottom_extension_cutout_offset_x, -z_fix()]) square([bracket_frame_extension_x + z_fix(), matrix_frame_width + tolerance + z_fix()]);
        translate([-z_fix(), bottom_extension_cutout_offset_y]) square([matrix_frame_width + tolerance + z_fix(), bracket_frame_extension_y + z_fix()]);
        // Bottom sector
        difference() {
          translate([matrix_frame_width, matrix_frame_width]) square([bracket_corner_radius, bracket_corner_radius]);
          translate([sector_offset, sector_offset]) sector(bracket_corner_radius - tolerance, 180, 270);
        }
      }
      // Round extension ends
//      translate([0, bracket_frame_extensions + matrix_frame_width, 0]) rotate([0, 0, -90]) extension_end_cutter();
//      translate([bracket_frame_extensions + matrix_frame_width, matrix_frame_width + bracket_wall_thickness, 0]) rotate([0, 0, 180]) extension_end_cutter();
      // Peg holes
      if (matrix_has_pegs) {
        pegs = [
          [matrix_peg_inset_x, matrix_peg_inset_y]
        ];
        for (i = pegs) {
          translate([i.x, i.y, -z_fix()]) cylinder(matrix_peg_height + 2 * z_fix(), d=matrix_peg_diameter + 2 * peg_tolerance);
        }
      }
      // Screw holes
      screws = [
        [matrix_screw_inset_x, matrix_screw_inset_y],
        if (centre_screw_a) [0, matrix_screw_inset_y],
        if (centre_screw_b) [matrix_screw_inset_x, 0],
        if (centre_screw_a && centre_screw_b) [0, 0]
      ];
      for (i = screws) {
        translate([i.x, i.y, bracket_base_thickness]) screw_hole();
      }
    }
  }
}

// Horizontal Edge Bracket
module horizontal_edge_bracket() {
  mirror_copy([1, 0, 0]) bracket_quadrant(bracket_centred_screw_holes);
}

// Vertical Edge Bracket
module vertical_edge_bracket() {
  mirror_copy([0, 1, 0]) bracket_quadrant(false);
}

// Centre Bracket
module centre_bracket() {
  mirror_copy([0, 1, 0]) mirror_copy([1, 0, 0]) bracket_quadrant(matrix_frame_has_middle);
}

// Matrix array
color("Gray") {
  if (show_panel_dummies) {
    mirror([0, 0, 1]) {
      for (y = [0:panel_rows - 1]) {
        for (x = [0:panel_columns - 1]) {
          translate([x * matrix_width, y * matrix_height, 0]) matrix();
        }
      }
    }
  }
}

color("Red") {
  bracket_x_offset = show_panel_dummies ? matrix_width : (2 * bracket_quadrant_width) + bracket_spacing + (mid_panel_brackets && matrix_frame_has_middle ? (2 * bracket_quadrant_width) : 0);
  bracket_y_offset = show_panel_dummies ? matrix_height : (2 * bracket_quadrant_height) + bracket_spacing;

  // Centre brackets
  if (panel_rows > 1 && panel_columns > 1) {
    for (y = [1:panel_rows - 1]) {
      for (x = [1:panel_columns - 1]) {
        translate([x * bracket_x_offset, y * bracket_y_offset, 0]) centre_bracket();
      }
    }
  }
  
  // Mid panel brackets
  if (mid_panel_brackets && matrix_frame_has_middle && panel_rows > 1 && panel_columns > 0) {
    for (y = [1:panel_rows - 1]) {
      for (x = [1:panel_columns - 1 + 1]) {
        translate([(x - 0.5) * bracket_x_offset, y * bracket_y_offset, 0]) centre_bracket();
      }
    }
  }

  if (panel_columns > 1) {
    // Bottom edge brackets
    for (x = [1:panel_columns - 1]) {
      translate([x * bracket_x_offset, 0, 0]) horizontal_edge_bracket();
    }
    // Top edge brackets
    for (x = [1:panel_columns - 1]) {
      translate([x * bracket_x_offset, panel_rows * bracket_y_offset, 0]) rotate([0, 0, 180]) horizontal_edge_bracket();
    }
  }

  if (panel_rows > 1) {
    // Left edge brackets
    for (y = [1:panel_rows - 1]) {
        translate([0, y * bracket_y_offset, 0]) vertical_edge_bracket();
    }
    // Right edge brackets
    for (y = [1:panel_rows - 1]) {
        translate([panel_columns * bracket_x_offset, y * bracket_y_offset, 0]) rotate([0, 0, 180]) vertical_edge_bracket();
    }
  }
}
