module ui

import gx
import gg
import vsvg

struct DrawDeviceSVG {
mut:
	id string = 'dd_svg'
	s  &vsvg.Svg
	ts &vsvg.TextStyle = 0
}

[params]
struct DrawDeviceSVGParams {
	id     string = 'dd_print'
	width  int
	height int
}

pub fn draw_device_svg(p DrawDeviceSVGParams) &DrawDeviceSVG {
	s := vsvg.svg(width: p.width, height: p.height)
	ts := vsvg.text_style()
	return &DrawDeviceSVG{
		id: p.id
		s: s
		ts: ts
	}
}

pub fn draw_device_draw_window(filename string, mut w Window) {
	// println("svg device")
	d := draw_device_svg(width: w.width, height: w.height)
	d.begin()

	mut children := if w.child_window == 0 { w.children } else { w.child_window.children }

	for mut child in children {
		child.draw_device(d)
	}

	for mut sw in w.subwindows {
		sw.draw_device(d)
	}

	// draw dragger if active
	draw_dragger(mut w)
	// draw tooltip if active
	w.tooltip.draw_device(d)

	if w.on_draw != voidptr(0) {
		w.on_draw(w)
	}

	w.mouse.draw_device(d)

	d.end()
	d.save(filename)
}

// methods

pub fn (d &DrawDeviceSVG) begin() {
	mut s := d.s
	s.begin()
}

pub fn (d &DrawDeviceSVG) end() {
	mut s := d.s
	s.end()
}

pub fn (d &DrawDeviceSVG) save(filepath string) {
	mut s := d.s
	// println("save $filepath")
	s.save(filepath) or {}
}

// interface DrawDevice

pub fn (d &DrawDeviceSVG) has_text_style() bool {
	return true
}

pub fn (d &DrawDeviceSVG) set_text_style(font_name string, size int, color gx.Color, align int, vertical_align int) {
	mut ts := d.ts
	ts.font_name = if font_name == 'system' { 'SFNS' } else { font_name }
	ts.size = size
	ts.color = color
	ts.set_align(align)
	ts.set_vertical_align(vertical_align)
	println('set_text_style: $d.ts')
}

pub fn (d &DrawDeviceSVG) draw_image(x f32, y f32, width f32, height f32, img &gg.Image) {
	// println('$d.id draw_image($x, $y, $width, $height, img)')
}

// pub fn (d &DrawDeviceSVG) draw_text_def(x int, y int, text string)
pub fn (d &DrawDeviceSVG) draw_text_default(x int, y int, text string) {
	// println('$d.id draw_text_default($x, $y, $text)')
	mut s := d.s
	s.text(x, y, text, '#000000', '#000000', d.ts)
}

pub fn (d &DrawDeviceSVG) draw_triangle_empty(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	// println('$d.id draw_triangle_empty($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDeviceSVG) draw_triangle_filled(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	// println('$d.id draw_triangle_filled($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
}

pub fn (d &DrawDeviceSVG) draw_rect_empty(x f32, y f32, w f32, h f32, color gx.Color) {
	// println('$d.id draw_rect_empty($x, $y, $w, $h, color gx.Color)')
	mut s := d.s
	s.rectangle(int(x), int(y), int(w), int(h), 'none', vsvg.color(color), 1, 0, 0)
}

pub fn (d &DrawDeviceSVG) draw_rect_filled(x f32, y f32, w f32, h f32, color gx.Color) {
	// println('$d.id draw_rect_filled($x, $y, $w, $h, color gx.Color)')
	mut s := d.s
	s.rectangle(int(x), int(y), int(w), int(h), vsvg.color(color), 'none', 0, 0, 0)
}

pub fn (d &DrawDeviceSVG) draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	println('$d.id draw_rounded_rect_filled($x, $y, $w, $h, $radius, color gx.Color)')
	mut s := d.s
	s.rectangle(int(x), int(y), int(w), int(h), vsvg.color(color), 'none', 0, int(radius),
		int(radius))
}

pub fn (d &DrawDeviceSVG) draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	println('$d.id draw_rounded_rect_empty($x, $y, $w, $h, $radius, color gx.Color)')
	mut s := d.s
	s.rectangle(int(x), int(y), int(w), int(h), 'none', vsvg.color(color), 1, int(radius),
		int(radius))
}

pub fn (d &DrawDeviceSVG) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceSVG) draw_circle_empty(x f32, y f32, r f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceSVG) draw_circle_filled(x f32, y f32, r f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceSVG) draw_slice_empty(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceSVG) draw_slice_filled(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceSVG) draw_arc_empty(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceSVG) draw_arc_filled(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceSVG) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceSVG) draw_convex_poly(points []f32, color gx.Color) {
	println('$d.id ')
}

pub fn (d &DrawDeviceSVG) draw_poly_empty(points []f32, color gx.Color) {
	println('$d.id ')
}
