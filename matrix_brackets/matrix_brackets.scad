/* [Array] */
// Show panels
show_panels = true;
// Number of panel columns in layout
panel_columns = 2;
// Number of panel rows in layout
panel_rows = 2;

/* [Matrix] */
// Width of the matrix panel
matrix_width = 320;
// Height of the matrix panel
matrix_height = 160;
// Depth of the matrix panel
matrix_depth = 15;
// Distance screw centres are inset from matrix edges on the X axis
matrix_screw_inset_x = 8;
// Distance screw centres are inset from matrix edges on the Y axis
matrix_screw_inset_y = 8;
// Width of the matrix frame
matrix_frame_width = 12;
// Depth of the matrix frame
matrix_frame_depth = 10;

/* [Screw] */
// Screw shaft diameter
screw_shaft_size = 3;
// Screw head diameter
screw_head_size = 5.5;

/* [Bracket] */
// Thickness of the base of the bracket
bracket_base_thickness = 4;
// Thickness of the walls of the bracket
bracket_wall_thickness = 2;
// Height of the walls of the bracket
bracket_wall_height = 4;
// Radius of frame-fitting corners
bracket_corner_radius = 4;
// Length of the bracket extensions along the frame
bracket_frame_extensions = 24;
// Include centred screw holes
bracket_centred_screw_holes = false;
// Include middle brackets
middle_brackets = false;
// Include corner brackets
corner_brackets = false;
// Bracket spacing
bracket_spacing = 4;

module private() {}

function z_fix() = $preview ? 0.1 : 0;

// Screw hole
module screw_hole(depth=10, recess=0) {
  $fn = $preview ? 8 : 32;
  tolerance = 0.25;
  translate([0, 0, -(depth + recess)]) cylinder(h=depth + z_fix(), d=screw_shaft_size + tolerance);
  if (recess > 0) {
    translate([0, 0, -(recess)]) cylinder(h=recess + z_fix(), d=screw_head_size + tolerance);
  }
//  bevel = 16;
//  translate([0, 0, 0]) cylinder(h=bevel, d1=screw_head_size + tolerance, d2=screw_head_size + bevel + tolerance);
//  translate([0, 0, bevel]) cylinder(h=bevel, d=screw_head_size + bevel + tolerance);
}

// Matrix
module matrix() {
  module cutout() {
    square([(matrix_width / 2) - (2 * matrix_frame_width), matrix_height - (2 * matrix_frame_width)]);
  }
  
  difference() {
    linear_extrude(matrix_depth) square([matrix_width, matrix_height]);
    union() {
      // Cutouts
      translate([0, 0, -z_fix()]) linear_extrude(matrix_frame_depth + z_fix()) {
        translate([matrix_frame_width, matrix_frame_width]) cutout();
        translate([(matrix_width / 2) + matrix_frame_width, matrix_frame_width]) cutout();
      }
      // Screws
      mirror([0, 0, 1]) {
        translate([matrix_screw_inset_x, matrix_screw_inset_y, 0]) screw_hole();
        translate([matrix_width - matrix_screw_inset_x, matrix_screw_inset_y, 0]) screw_hole();
        translate([matrix_screw_inset_x, matrix_height - matrix_screw_inset_y, 0]) screw_hole();
        translate([matrix_width - matrix_screw_inset_x, matrix_height - matrix_screw_inset_y, 0]) screw_hole();
        translate([matrix_width / 2, matrix_screw_inset_y, 0]) screw_hole();
        translate([matrix_width / 2, matrix_height - matrix_screw_inset_y, 0]) screw_hole();
      }
    }
  }
}

bracket_half_size = matrix_frame_width + bracket_frame_extensions;
bracket_size = 2 * bracket_half_size;

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

// Bracket Quadrant
module bracket_quadrant(centre_screw_a = false, centre_screw_b = false) {
  tolerance = 0.125;
  bracket_top = bracket_base_thickness + bracket_wall_height;
  bracket_bottom = -bracket_wall_height;
  bracket_thickness = bracket_top - bracket_bottom;
  outer_corner_radius = 12;
  inner_corner_radius = max(outer_corner_radius - bracket_wall_thickness, 0);
  difference() {
    translate([0, 0, bracket_bottom]) cube([bracket_half_size, bracket_half_size, bracket_thickness]);
    union() {
      sector_cutout_offset = matrix_frame_width + bracket_wall_thickness;
      sector_offset = sector_cutout_offset + inner_corner_radius;
      // Full depth cutouts
      // Corner cutout
      translate([0, 0, bracket_bottom - z_fix()]) linear_extrude(bracket_thickness + 2 * z_fix()) {
        difference() {
          corner_cutout_size = bracket_half_size - (matrix_frame_width + bracket_wall_thickness);
          corner_cutout_offset = bracket_half_size - corner_cutout_size;
          translate([corner_cutout_offset, corner_cutout_offset]) square([corner_cutout_size + z_fix(), corner_cutout_size + z_fix()]);
          translate([sector_cutout_offset, sector_cutout_offset]) square([inner_corner_radius, inner_corner_radius]);
        }
        translate([sector_offset, sector_offset]) sector(inner_corner_radius, 180, 270);
      }
      // Top cutouts
      translate([0, 0, bracket_base_thickness]) linear_extrude(bracket_wall_height + z_fix()) difference() {
        union() {
          // Top centre
//          translate([centre_screw_a ? 0 : bracket_wall_thickness, centre_screw_b ? 0 : bracket_wall_thickness]) square([matrix_frame_width - (centre_screw_b ? bracket_wall_thickness : 0), matrix_frame_width - (centre_screw_a ? bracket_wall_thickness : 0)]);
          translate([bracket_wall_thickness, bracket_wall_thickness]) square([matrix_frame_width, matrix_frame_width]);
          // Top extensions
          top_extension_cutout_size = bracket_frame_extensions - bracket_wall_thickness + z_fix();
          top_extension_cutout_offset = bracket_half_size - top_extension_cutout_size + z_fix();
          translate([top_extension_cutout_offset, bracket_wall_thickness]) square([top_extension_cutout_size, matrix_frame_width - bracket_wall_thickness]);
          translate([bracket_wall_thickness, top_extension_cutout_offset]) square([matrix_frame_width - bracket_wall_thickness, top_extension_cutout_size]);
          // Top sector
          difference() {
            translate([matrix_frame_width, matrix_frame_width]) square([outer_corner_radius, outer_corner_radius]);
            translate([sector_offset, sector_offset]) sector(outer_corner_radius, 180, 270);
          }
        }
        union() {
          translate([matrix_screw_inset_x, matrix_screw_inset_y, screw_z]) difference() {
            circle(4);
            circle(2);
          }
          if (centre_screw_a) {
            translate([0, matrix_screw_inset_y, screw_z]) difference() {
              circle(4);
              circle(2);
            }
          }
          if (centre_screw_b) {
            translate([matrix_screw_inset_x, 0, screw_z]) difference() {
              circle(4);
              circle(2);
            }
          }
        }
      }
      // Bottom cutouts
      translate([0, 0, -bracket_wall_height - z_fix()]) linear_extrude(bracket_wall_height + z_fix()) union() {
        // Bottom centre
        translate([-z_fix(), -z_fix()]) square([matrix_frame_width + tolerance + z_fix(), matrix_frame_width + tolerance + z_fix()]);
        // Bottom extensions
        bottom_extension_cutout_offset = bracket_half_size - bracket_frame_extensions + z_fix();
        translate([bottom_extension_cutout_offset, -z_fix()]) square([bracket_frame_extensions + z_fix(), matrix_frame_width + tolerance + z_fix()]);
        translate([-z_fix(), bottom_extension_cutout_offset]) square([matrix_frame_width + tolerance + z_fix(), bracket_frame_extensions + z_fix()]);
        // Bottom sector
        difference() {
          translate([matrix_frame_width, matrix_frame_width]) square([outer_corner_radius, outer_corner_radius]);
          translate([sector_offset, sector_offset]) sector(outer_corner_radius - tolerance, 180, 270);
        }
      }
      // Round extension ends
      rotate([0, 0, -90]) translate([-(matrix_frame_width + bracket_wall_thickness), bracket_frame_extensions, 0]) difference () {
        cube([matrix_frame_width + bracket_wall_thickness, bracket_thickness / 2, bracket_thickness]);
        rotate([0, 90, 0]) linear_extrude(matrix_frame_width + bracket_wall_thickness) sector(bracket_thickness / 2, 0, 180);
      }
      // Screw holes
      screw_z = bracket_base_thickness;
      screw_recess = 1;
      translate([matrix_screw_inset_x, matrix_screw_inset_y, screw_z]) screw_hole(bracket_thickness, screw_recess);
      if (centre_screw_a) {
        translate([0, matrix_screw_inset_y, screw_z]) screw_hole(bracket_thickness, screw_recess);
      }
      if (centre_screw_b) {
        translate([matrix_screw_inset_x, 0, screw_z]) screw_hole(bracket_thickness, screw_recess);
      }
      if (centre_screw_a && centre_screw_b) {
        translate([0, 0, screw_z]) screw_hole(bracket_thickness, screw_recess);
      }
    }
  }
}

// Corner Bracket
module corner_bracket() {
  mirror([0, 0, 0]) bracket_quadrant();
}

// Edge Bracket
module edge_bracket() {
  mirror([0, 0, 0]) bracket_quadrant(bracket_centred_screw_holes);
  mirror([1, 0, 0]) bracket_quadrant(bracket_centred_screw_holes);
}

// Centre Bracket
module centre_bracket() {
  mirror([0, 0, 0]) edge_bracket();
  mirror([0, 1, 0]) edge_bracket();
}

// Matrix array
color("Gray") {
  if (show_panels) {
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
  bracket_x_offset = show_panels ? matrix_width : bracket_size + bracket_spacing + (middle_brackets ? bracket_size : 0);
  bracket_y_offset = show_panels ? matrix_height : bracket_size + bracket_spacing;

  // Centre brackets
  if (panel_rows > 1 && panel_columns > 1) {
    for (y = [1:panel_rows - 1]) {
      for (x = [1:panel_columns - 1]) {
        translate([x * bracket_x_offset, y * bracket_y_offset, 0]) centre_bracket();
      }
    }
  }
  
  // Middle brackets
  if (panel_rows > 1 && panel_columns > 0) {
    if (middle_brackets) {
      for (y = [1:panel_rows - 1]) {
        for (x = [1:panel_columns - 1 + 1]) {
          translate([(x - 0.5) * bracket_x_offset, y * bracket_y_offset, 0]) centre_bracket();
        }
      }
    }
  }

  if (panel_columns > 1) {
    // Bottom edge brackets
    for (x = [1:panel_columns - 1]) {
      translate([x * bracket_x_offset, 0, 0]) edge_bracket();
    }
    // Top edge brackets
    for (x = [1:panel_columns - 1]) {
      translate([x * bracket_x_offset, panel_rows * bracket_y_offset, 0]) rotate([0, 0, 180]) edge_bracket();
    }
  }

  if (panel_rows > 1) {
    // Left edge brackets
    for (y = [1:panel_rows - 1]) {
        translate([0, y * bracket_y_offset, 0]) rotate([0, 0, 270]) edge_bracket();
    }
    // Right edge brackets
    for (y = [1:panel_rows - 1]) {
        translate([panel_columns * bracket_x_offset, y * bracket_y_offset, 0]) rotate([0, 0, 90]) edge_bracket();
    }
  }

  // Corner brackets
  if (corner_brackets) {
    translate([0, 0, 0]) corner_bracket();
    translate([panel_columns * bracket_x_offset, 0, 0]) rotate([0, 0, 90]) corner_bracket();
    translate([panel_columns * bracket_x_offset, panel_rows * bracket_y_offset, 0]) rotate([0, 0, 180]) corner_bracket();
    translate([0, panel_rows * bracket_y_offset, 0]) rotate([0, 0, 270]) corner_bracket();
  }
}
