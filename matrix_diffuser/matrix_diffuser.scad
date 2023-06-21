/* [Matrix] */
// Cell count x
matrix_unit_count_x = 8;
// Cell count y
matrix_unit_count_y = 8;
// Cell width
matrix_unit_width = 8.4;
// Cell height
matrix_unit_height = 8.4;
// PCB depth
matrix_pcb_depth = 2.2;
// LED width
matrix_led_width = 5.0;
// LED height
matrix_led_height = 5.0;
// LED depth
matrix_led_depth = 1.5;

/* [Array] */
// Matrix count x
array_matrix_count_x = 2;
// Matrix count y
array_matrix_count_y = 1;
// Show matrix dummies
array_show_dummies = false;

/* [Diffuser] */
// Diffuser screen thickness
diffuser_screen_depth = 0.6;
// Diffuser Spacing
diffuser_spacing = 1.2;
// Diffuser unit wall thickness
diffuser_unit_wall_thickness = 0.4;
// Diffuser unit wall x spacing
diffuser_unit_wall_x_spacing = 1.0;
// Diffuser unit wall y spacing
diffuser_unit_wall_y_spacing = 0.0;
// Diffuser frame thickness
diffuser_frame_thickness = 1.2;
// Diffuser frame spacing
diffuser_frame_spacing = 0.2;
// Diffuser clip fraction
diffuser_clip_fraction = 0.5;
// Diffuser clip depth
diffuser_clip_depth = 0.8;
// Diffuser clip thickness
diffuser_clip_thickness = 1.2;
// Include grid
include_grid = true;
// Include screen and frame
include_screen_and_frame = true;

/* [Tweak] */
frame_tolerance = 0.25;
face_down = false;

module private() {}

matrix_width = matrix_unit_count_x * matrix_unit_width;
matrix_height = matrix_unit_count_y * matrix_unit_height;
matrix_depth = matrix_pcb_depth + matrix_led_depth;

module matrix() {
//    linear_extrude(height = matrix_pcb_depth)
//        square([matrix_width, matrix_height], center = true);
    
    module led() {
        linear_extrude(height = matrix_led_depth)
            square([matrix_led_width, matrix_led_height]);
    }
    
    module unit() {
        led_offset_x = (matrix_unit_width - matrix_led_width) / 2;
        led_offset_y = (matrix_unit_height - matrix_led_height) / 2;
        translate([led_offset_x, led_offset_y, -matrix_led_depth])
            color("White")
                led();
        color("DimGray")
            linear_extrude(height = matrix_pcb_depth)
                square([matrix_unit_width, matrix_unit_height]);
    }
    
    for (y = [0:matrix_unit_count_y - 1]) {
        for (x = [0:matrix_unit_count_x - 1]) {
            translate([x * matrix_unit_width, y * matrix_unit_height, 0])
                unit();
        }
    }
}

array_width = array_matrix_count_x * matrix_width;
array_height = array_matrix_count_y * matrix_height;

diffuser_width = array_width + 2 * diffuser_frame_thickness + 2 * diffuser_frame_spacing;
diffuser_height = array_height + 2 * diffuser_frame_thickness + 2 * diffuser_frame_spacing;

diffuser_depth = diffuser_screen_depth + diffuser_spacing + matrix_depth;

wall_x_depth = diffuser_depth - diffuser_unit_wall_x_spacing;
wall_y_depth = diffuser_depth - diffuser_unit_wall_y_spacing;

grid_depth = max(wall_x_depth, wall_y_depth);

dummy_offset = diffuser_screen_depth + grid_depth;

if (array_show_dummies) {
    translate([diffuser_frame_thickness, diffuser_frame_thickness])
        for (y = [0:array_matrix_count_y - 1]) {
            for (x = [0:array_matrix_count_x - 1]) {
                translate([x * matrix_width, y * matrix_height, dummy_offset])
                    matrix();
            }
        }
}

module diffuser() {
    // Unit
    module diffuser_unit() {
//        translate([diffuser_internal_wall_thickness / 2, diffuser_internal_wall_thickness / 2, 0])
//            linear_extrude(height = matrix_depth)
//                square([matrix_unit_width - diffuser_internal_wall_thickness, matrix_unit_height - diffuser_internal_wall_thickness]);
        union() {
            linear_extrude(height = wall_x_depth) {
                translate([0, 0])
                    square([matrix_unit_width, diffuser_unit_wall_thickness]);
                translate([0, matrix_unit_height - diffuser_unit_wall_thickness])
                    square([matrix_unit_width, diffuser_unit_wall_thickness]);
            }
            linear_extrude(height = wall_y_depth) {
                translate([0, 0])
                    square([diffuser_unit_wall_thickness, matrix_unit_height]);
                translate([matrix_unit_width - diffuser_unit_wall_thickness, 0])
                    square([diffuser_unit_wall_thickness, matrix_unit_height]);
            }
        }
    }

    // Grid
    module matrix_grid() {
        for (y = [0:matrix_unit_count_y - 1]) {
            for (x = [0:matrix_unit_count_x - 1]) {
                translate([x * matrix_unit_width, y * matrix_unit_height, 0])
                    diffuser_unit();
            }
        }
    }    
    if (include_grid) {
        translate(include_screen_and_frame ? [diffuser_frame_thickness + diffuser_frame_spacing, diffuser_frame_thickness + diffuser_frame_spacing] : [0, 0])
            for (y = [0:array_matrix_count_y - 1]) {
                for (x = [0:array_matrix_count_x - 1]) {
                    translate([x * matrix_width, y * matrix_height, include_screen_and_frame ? diffuser_screen_depth : 0])
                        matrix_grid();
                }
            }
    }
    
    module clip() {
        linear_extrude(height = diffuser_clip_depth)
            square([matrix_width * diffuser_clip_fraction, diffuser_frame_thickness + diffuser_frame_spacing + diffuser_clip_thickness]);
    }
    if (include_screen_and_frame) {
        // Frame
        translate([0, 0, diffuser_screen_depth])
            linear_extrude(height = grid_depth + matrix_pcb_depth) {
                union() {
                    translate([0, 0])
                        square([diffuser_width, diffuser_frame_thickness]);
                    translate([0, diffuser_height - diffuser_frame_thickness])
                        square([diffuser_width, diffuser_frame_thickness]);
                    translate([0, 0])
                        square([diffuser_frame_thickness, diffuser_height]);
                    translate([diffuser_width - diffuser_frame_thickness, 0])
                        square([diffuser_frame_thickness, diffuser_height]);
                }
            }
            
        // Clips
        translate([0, 0, diffuser_screen_depth + grid_depth + matrix_pcb_depth]) {
            for (x = [0:array_matrix_count_x - 1]) {
                translate([diffuser_frame_thickness + diffuser_frame_spacing + (x + (1 - diffuser_clip_fraction) / 2) * matrix_width, 0])
                    clip();
                translate([diffuser_frame_thickness + diffuser_frame_spacing + (x + (1 - diffuser_clip_fraction) / 2) * matrix_width, diffuser_height])
                    mirror([0, 1, 0])
                        clip();
            }
            for (y = [0:array_matrix_count_y - 1]) {
                translate([0, diffuser_frame_thickness + (y + (1 - diffuser_clip_fraction) / 2) * matrix_height])
                    mirror([1, 0, 0])
                        rotate([0, 0, 90])
                            clip();
                translate([diffuser_width, diffuser_frame_thickness + (y + (1 - diffuser_clip_fraction) / 2) * matrix_height])
                    rotate([0, 0, 90])
                        clip();
            }
        }
        
        // Screen
        translate([0, 0, 0])
            linear_extrude(height = diffuser_screen_depth)
                square([diffuser_width, diffuser_height]);
    }
}

color("White", 0.5)
    diffuser();