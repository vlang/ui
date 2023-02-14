module ui

import gx
import gg
import math

struct DrawDevicePrint {
	id       string = 'dd_print'
	filename string
}

[params]
pub struct DrawDevicePrintParams {
	id       string = 'dd_print'
	filename string
}

// TODO: documentation
pub fn draw_device_print(p DrawDevicePrintParams) &DrawDevicePrint {
	return &DrawDevicePrint{p.id, p.filename}
}

fn draw_device_draw_print(filename string, mut w Window) {
	d := draw_device_print(id: 'test', filename: filename)
	mut dd := DrawDevice(d)
	dd.draw_window(mut w)
}

// TODO: documentation
pub fn (d &DrawDevicePrint) set_bg_color(color gx.Color) {}

// TODO: documentation
pub fn (d &DrawDevicePrint) has_text_style() bool {
	return false
}

// TODO: documentation
pub fn (d &DrawDevicePrint) set_text_style(font_name string, font_path string, size int, color gx.Color, align int, vertical_align int) {}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_text(x int, y int, text string, cfg gx.TextCfg) {
	println('${d.id} draw_text(${x}, ${y}, ${text}, ${cfg})')
}

// pub fn (d &DrawDevicePrint) draw_text_def(x int, y int, text string) {

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_text_default(x int, y int, text string) {
	println('${d.id} draw_text_default(${x}, ${y}, ${text})')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_text_def(x int, y int, text string) {}

// TODO: documentation
pub fn (d &DrawDevicePrint) set_text_cfg(c_ gx.TextCfg) {}

// TODO: documentation
pub fn (d &DrawDevicePrint) text_size(s string) (int, int) {
	return 0, 0
}

// TODO: documentation
pub fn (d &DrawDevicePrint) text_width(s string) int {
	return 0
}

// TODO: documentation
pub fn (d &DrawDevicePrint) text_height(s string) int {
	return 0
}

// TODO: documentation
pub fn (d &DrawDevicePrint) reset_clipping() {
	// TODO: implement
}

// TODO: documentation
pub fn (d &DrawDevicePrint) set_clipping(rect Rect) {
	// TODO: implement
}

// TODO: documentation
pub fn (d &DrawDevicePrint) get_clipping() Rect {
	// TODO: implement
	return Rect{0, 0, math.max_i32, math.max_i32}
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_pixel(x f32, y f32, color gx.Color) {
	println('${d.id} draw_pixel(${x}, ${y}, ${color})')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_pixels(points []f32, color gx.Color) {
	println('${d.id} draw_pixels(${points}, ${color})')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_image(x f32, y f32, width f32, height f32, img &gg.Image) {
	println('${d.id} draw_image(${x}, ${y}, ${width}, ${height}, img)')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_triangle_empty(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	println('${d.id} draw_triangle_empty(${x}, ${y}, ${x2}, ${y2}, ${x3}, ${y3}, ${color})')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_triangle_filled(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	println('${d.id} draw_triangle_filled(${x}, ${y}, ${x2}, ${y2}, ${x3}, ${y3}, ${color})')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_rect_empty(x f32, y f32, w f32, h f32, color gx.Color) {
	println('${d.id} draw_rect_empty(${x}, ${y}, ${w}, ${h}, ${color})')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_rect_filled(x f32, y f32, w f32, h f32, color gx.Color) {
	println('${d.id} draw_rect_filled(${x}, ${y}, ${w}, ${h}, ${color})')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	println('${d.id} draw_rounded_rect_filled(${x}, ${y}, ${w}, ${h}, ${radius}, ${color})')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, border_color gx.Color) {
	println('${d.id} draw_rounded_rect_empty(${x}, ${y}, ${w}, ${h}, ${radius}, ${border_color})')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_circle_empty(x f32, y f32, r f32, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_circle_filled(x f32, y f32, r f32, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_slice_empty(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_slice_filled(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_arc_empty(x f32, y f32, radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_arc_filled(x f32, y f32, radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_arc_line(x f32, y f32, radius f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_convex_poly(points []f32, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDevicePrint) draw_poly_empty(points []f32, color gx.Color) {
	println('${d.id} ')
}
