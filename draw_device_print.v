module ui

import gx
import gg

struct DrawDevicePrint {
	id       string = 'dd_print'
	filename string
}

pub fn draw_device_print(id string, filename string) &DrawDevicePrint {
	return &DrawDevicePrint{id, filename}
}

// pub fn (d &DrawDevicePrint) draw_pixel(x f32, y f32, c gx.Color) {
// 	println("$d.id draw_pixel($x, $y, $c)")
// }
// pub fn (d &DrawDevicePrint)	draw_pixels(points []f32, c gx.Color) {
// 	println("$d.id ")
// }
pub fn (d &DrawDevicePrint) draw_image(x f32, y f32, width f32, height f32, img &gg.Image) {
	println('$d.id draw_image($x, $y, $width, $height, img)')
}

// pub fn (d &DrawDevicePrint) draw_text_def(x int, y int, text string)
// pub fn (d &DrawDevicePrint) draw_text(x int, y int, text string)
pub fn (d &DrawDevicePrint) draw_triangle_empty(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	println('$d.id draw_triangle_empty($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDevicePrint) draw_triangle_filled(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	println('$d.id draw_triangle_filled($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDevicePrint) draw_rect_empty(x f32, y f32, w f32, h f32, color gx.Color) {
	println('$d.id draw_rect_empty($x, $y, $w, $h, color gx.Color)')
}

pub fn (d &DrawDevicePrint) draw_rect_filled(x f32, y f32, w f32, h f32, color gx.Color) {
	println('$d.id draw_rect_filled($x, $y, $w, $h, color gx.Color)')
}

pub fn (d &DrawDevicePrint) draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	println('$d.id draw_rounded_rect_filled($x, $y, $w, $h, $radius, color gx.Color)')
}

pub fn (d &DrawDevicePrint) draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, border_color gx.Color) {
	println('$d.id draw_rounded_rect_empty($x, $y, $w, $h, $radius, color gx.Color)')
}

pub fn (d &DrawDevicePrint) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDevicePrint) draw_circle_empty(x f32, y f32, r f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDevicePrint) draw_circle_filled(x f32, y f32, r f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDevicePrint) draw_slice_empty(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDevicePrint) draw_slice_filled(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDevicePrint) draw_arc_empty(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDevicePrint) draw_arc_filled(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDevicePrint) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDevicePrint) draw_convex_poly(points []f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDevicePrint) draw_poly_empty(points []f32, color gx.Color) {
	println('$d.id ')
}
