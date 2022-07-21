module ui

import gx
import gg
import ui.libvg

struct DrawDeviceBitmap {
	id string = 'dd_bitmap'
	ts &libvg.BitmapTextStyle = unsafe { nil }
pub mut:
	r &libvg.Raster = unsafe { nil }
}

[params]
pub struct DrawDeviceBitmapParams {
	id string = 'dd_bitmap'
}

pub fn draw_device_bitmap(p DrawDeviceBitmapParams) &DrawDeviceBitmap {
	ts := libvg.bitmap_text_style()
	return &DrawDeviceBitmap{
		id: p.id
		ts: ts
	}
}

pub fn (mut d DrawDeviceBitmap) png_screenshot_window(filename string, mut w Window) {
	d.r = libvg.raster(width: w.width, height: w.height)
	d.r.attach_bitmap()
	d.r.rectangle_filled(0, 0, w.width, w.height, w.bg_color)
	DrawDevice(d).draw_window(mut w)
	d.r.save_image_as(filename)
}

// methods

// pub fn (d &DrawDeviceBitmap) begin(win_bg_color gx.Color) {
// 	mut r := d.s
// 	s.begin()
// 	// window.bg_color
// 	s.fill(libvg.color(win_bg_color))
// }

// pub fn (d &DrawDeviceBitmap) end() {
// 	mut r := d.r
// 	s.end()
// }

// pub fn (d &DrawDeviceBitmap) save(filepath string) {
// 	mut r := d.r
// 	// println("save $filepath")
// 	r.save(filepath) or {}
// }

// interface DrawDevice

pub fn (d &DrawDeviceBitmap) has_text_style() bool {
	return true
}

pub fn (d &DrawDeviceBitmap) set_text_style(font_name string, font_path string, size int, color gx.Color, align int, vertical_align int) {
	mut ts := d.ts
	ts.font_name = if font_name == 'system' { 'Systemfont' } else { font_name }
	ts.font_path = font_path
	ts.size = size
	ts.color = color
	ts.set_align(align)
	ts.set_vertical_align(vertical_align)
	// font
	if font_path !in d.r.ttf_fonts {
		mut r := d.r
		r.add_ttf(font_path)
	}
}

pub fn (d &DrawDeviceBitmap) scissor_rect(x int, y int, w int, h int) {}

// pub fn (d &DrawDeviceBitmap) draw_pixel(x f32, y f32, c gx.Color) {
// 	println("$d.id draw_pixel($x, $y, $c)")
// }
// pub fn (d &DrawDeviceBitmap)	draw_pixels(points []f32, c gx.Color) {
// 	println("$d.id ")
// }
pub fn (d &DrawDeviceBitmap) draw_image(x f32, y f32, width f32, height f32, img &gg.Image) {
	// println('$d.id draw_image($x, $y, $width, $height, img)')
	mut r := d.r
	mut r2 := libvg.raster()
	r2.load(img)
	r.copy(r2, int(x), int(y), int(width), int(height))
}

// pub fn (d &DrawDeviceBitmap) draw_text_def(x int, y int, text string)
pub fn (d &DrawDeviceBitmap) draw_text_default(x int, y int, text string) {
	// println('$d.id draw_text_default($x, $y, $text) $d.ts')
	mut r := d.r
	r.init_style(d.ts)
	// r.get_info_string()
	dy := int(r.get_y_base() * d.ts.vertical_align)
	println('draw text bmp ($text) ($x, $y) dy := $dy = $r.get_y_base() * $d.ts.vertical_align} ')
	r.draw_text_block(text, x: x, y: y + dy, w: r.width, h: r.height)
}

pub fn (d &DrawDeviceBitmap) draw_triangle_empty(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	// println('$d.id draw_triangle_empty($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDeviceBitmap) draw_triangle_filled(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	// println('$d.id draw_triangle_filled($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDeviceBitmap) draw_rect_empty(x f32, y f32, w f32, h f32, color gx.Color) {
	// println('$d.id draw_rect_empty($x, $y, $w, $h, $color)')
	mut r := d.r
	r.box(int(x), int(y), int(x + w), int(y + h), color)
}

pub fn (d &DrawDeviceBitmap) draw_rect_filled(x f32, y f32, w f32, h f32, color gx.Color) {
	// println('$d.id draw_rect_filled($x, $y, $w, $h, $color)')
	mut r := d.r
	r.rectangle_filled(int(x), int(y), int(w), int(h), color)
}

pub fn (d &DrawDeviceBitmap) draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	// println('$d.id draw_rounded_rect_filled($x, $y, $w, $h, $radius, color gx.Color)')
	d.draw_rect_filled(x, y, w, h, color)
}

pub fn (d &DrawDeviceBitmap) draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	// println('$d.id draw_rounded_rect_empty($x, $y, $w, $h, $radius, color gx.Color)')
	d.draw_rect_empty(x, y, w, h, color)
}

pub fn (d &DrawDeviceBitmap) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceBitmap) draw_circle_empty(x f32, y f32, r f32, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceBitmap) draw_circle_filled(x f32, y f32, r f32, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceBitmap) draw_slice_empty(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceBitmap) draw_slice_filled(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceBitmap) draw_arc_empty(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceBitmap) draw_arc_filled(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceBitmap) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	// println('$d.id ')
	mut r := d.r
	r.line(int(x), int(y), int(x2), int(y2), color)
}

pub fn (d &DrawDeviceBitmap) draw_convex_poly(points []f32, color gx.Color) {
	// println('$d.id ')
}

pub fn (d &DrawDeviceBitmap) draw_poly_empty(points []f32, color gx.Color) {
	// println('$d.id ')
}
