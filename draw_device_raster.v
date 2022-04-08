module ui

import gx
import gg
import ui.libvg

struct DrawDeviceRaster {
	id string = 'dd_png'
	ts &libvg.TextStyle = 0
pub mut:
	r &libvg.Raster = 0
}

[params]
pub struct DrawDeviceRasterParams {
	id string = 'dd_png'
}

pub fn draw_device_raster(p DrawDeviceRasterParams) &DrawDeviceRaster {
	ts := libvg.text_style()
	return &DrawDeviceRaster{
		id: p.id
		ts: ts
	}
}

pub fn (mut d DrawDeviceRaster) png_screenshot_window(filename string, mut w Window) {
	d.r = libvg.raster(width: w.width, height: w.height)
	d.r.rectangle_filled(0, 0, w.width, w.height, w.bg_color)
	DrawDevice(d).draw_window(mut w)
	d.r.save_image_as(filename)
}

// methods

// pub fn (d &DrawDeviceRaster) begin(win_bg_color gx.Color) {
// 	mut r := d.s
// 	s.begin()
// 	// window.bg_color
// 	s.fill(libvg.color(win_bg_color))
// }

// pub fn (d &DrawDeviceRaster) end() {
// 	mut r := d.r
// 	s.end()
// }

// pub fn (d &DrawDeviceRaster) save(filepath string) {
// 	mut r := d.r
// 	// println("save $filepath")
// 	r.save(filepath) or {}
// }

// interface DrawDevice

pub fn (d &DrawDeviceRaster) has_text_style() bool {
	return false
}

pub fn (d &DrawDeviceRaster) set_text_style(font_name string, size int, color gx.Color, align int, vertical_align int) {}

pub fn (d &DrawDeviceRaster) scissor_rect(x int, y int, w int, h int) {}

// pub fn (d &DrawDeviceRaster) draw_pixel(x f32, y f32, c gx.Color) {
// 	println("$d.id draw_pixel($x, $y, $c)")
// }
// pub fn (d &DrawDeviceRaster)	draw_pixels(points []f32, c gx.Color) {
// 	println("$d.id ")
// }
pub fn (d &DrawDeviceRaster) draw_image(x f32, y f32, width f32, height f32, img &gg.Image) {
	// println('$d.id draw_image($x, $y, $width, $height, img)')
	mut r := d.r
	mut r2 := libvg.raster()
	r2.load(img)
	r.copy(r2, int(x), int(y), int(width), int(height))
}

// pub fn (d &DrawDeviceRaster) draw_text_def(x int, y int, text string)
pub fn (d &DrawDeviceRaster) draw_text_default(x int, y int, text string) {
	// println('$d.id draw_text_default($x, $y, $text)')
}

pub fn (d &DrawDeviceRaster) draw_triangle_empty(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	// println('$d.id draw_triangle_empty($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDeviceRaster) draw_triangle_filled(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	// println('$d.id draw_triangle_filled($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDeviceRaster) draw_rect_empty(x f32, y f32, w f32, h f32, color gx.Color) {
	// println('$d.id draw_rect_empty($x, $y, $w, $h, $color)')
	mut r := d.r
	r.box(int(x), int(y), int(x + w), int(y + h), color)
}

pub fn (d &DrawDeviceRaster) draw_rect_filled(x f32, y f32, w f32, h f32, color gx.Color) {
	// println('$d.id draw_rect_filled($x, $y, $w, $h, $color)')
	mut r := d.r
	r.rectangle_filled(int(x), int(y), int(w), int(h), color)
}

pub fn (d &DrawDeviceRaster) draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	// println('$d.id draw_rounded_rect_filled($x, $y, $w, $h, $radius, color gx.Color)')
}

pub fn (d &DrawDeviceRaster) draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, border_color gx.Color) {
	// println('$d.id draw_rounded_rect_empty($x, $y, $w, $h, $radius, color gx.Color)')
}

pub fn (d &DrawDeviceRaster) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceRaster) draw_circle_empty(x f32, y f32, r f32, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceRaster) draw_circle_filled(x f32, y f32, r f32, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceRaster) draw_slice_empty(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceRaster) draw_slice_filled(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceRaster) draw_arc_empty(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceRaster) draw_arc_filled(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceRaster) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceRaster) draw_convex_poly(points []f32, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceRaster) draw_poly_empty(points []f32, color gx.Color) {
	// println('$d.id ')
}
