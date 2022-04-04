module ui

import gx
import gg

struct DrawDeviceTest {
	id       string = 'dd_test'
	filename string
}

// pub fn (d &DrawDeviceTest) draw_pixel(x f32, y f32, c gx.Color) {
// 	println("$d.id draw_pixel($x, $y, $c)")
// }
// pub fn (d &DrawDeviceTest)	draw_pixels(points []f32, c gx.Color) {
// 	println("$d.id ")
// }
pub fn (d &DrawDeviceTest) draw_image(x f32, y f32, width f32, height f32, img &gg.Image) {
	println('$d.id draw_image($x, $y, $width, $height, img)')
}

// pub fn (d &DrawDeviceTest) draw_text_def(x int, y int, text string)
// pub fn (d &DrawDeviceTest) draw_text(x int, y int, text string)
pub fn (d &DrawDeviceTest) draw_triangle_empty(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	println('$d.id draw_triangle_empty($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDeviceTest) draw_triangle_filled(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	println('$d.id draw_triangle_filled($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDeviceTest) draw_rect_empty(x f32, y f32, w f32, h f32, color gx.Color) {
	println('$d.id draw_rect_empty($x, $y, $w, $h, color gx.Color)')
}

pub fn (d &DrawDeviceTest) draw_rect_filled(x f32, y f32, w f32, h f32, color gx.Color) {
	println('$d.id draw_rect_filled($x, $y, $w, $h, color gx.Color)')
}

pub fn (d &DrawDeviceTest) draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	println('$d.id draw_rounded_rect_filled($x, $y, $w, $h, $radius, color gx.Color)')
}

pub fn (d &DrawDeviceTest) draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, border_color gx.Color) {
	println('$d.id draw_rounded_rect_empty($x, $y, $w, $h, $radius, color gx.Color)')
}

pub fn (d &DrawDeviceTest) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceTest) draw_circle_empty(x f32, y f32, r f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceTest) draw_circle_filled(x f32, y f32, r f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceTest) draw_slice_empty(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceTest) draw_slice_filled(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceTest) draw_arc_empty(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceTest) draw_arc_filled(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceTest) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceTest) draw_convex_poly(points []f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceTest) draw_poly_empty(points []f32, color gx.Color) {
	println('$d.id ')
}
