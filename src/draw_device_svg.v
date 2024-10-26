module ui

import gx
import gg
import ui.libvg

struct DrawDeviceSVG {
mut:
	id string              = 'dd_svg'
	ts &libvg.SvgTextStyle = unsafe { nil }
pub mut:
	s &libvg.Svg = unsafe { nil }
}

@[params]
struct DrawDeviceSVGParams {
pub:
	id string = 'dd_svg'
}

// TODO: documentation
pub fn draw_device_svg(p DrawDeviceSVGParams) &DrawDeviceSVG {
	ts := libvg.svg_text_style()
	return &DrawDeviceSVG{
		id: p.id
		ts: ts
	}
}

// screenshot method for SVG device
@[manualfree]
pub fn (mut d DrawDeviceSVG) screenshot_window(filename string, mut w Window) {
	// println("svg device")
	d.s = libvg.svg(width: w.width, height: w.height)
	d.begin(w.bg_color)
	mut dd := DrawDevice(d)
	dd.draw_window(mut w)
	d.end()
	d.save(filename)
	unsafe { d.s.free() }
}

// methods

// TODO: documentation
pub fn (d &DrawDeviceSVG) begin(win_bg_color gx.Color) {
	mut s := d.s
	s.begin()
	// window.bg_color
	s.fill(hex_color(win_bg_color))
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) end() {
	mut s := d.s
	s.end()
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) save(filepath string) {
	mut s := d.s
	// println("save $filepath")
	s.save(filepath) or {}
}

// interface DrawDevice

// TODO: documentation
pub fn (d DrawDeviceSVG) set_bg_color(color gx.Color) {}

// TODO: documentation
pub fn (d &DrawDeviceSVG) has_text_style() bool {
	return true
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) set_text_style(font_name string, font_path string, size int, color gx.Color, align int, vertical_align int) {
	mut ts := d.ts
	ts.font_name = if font_name == 'system' { 'Systemfont' } else { font_name }
	ts.font_path = font_path
	ts.size = size
	ts.color = color
	ts.set_align(align)
	ts.set_vertical_align(vertical_align)
	// println('set_text_style: $d.ts')
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_text(x int, y int, text string, cfg gx.TextCfg) {
	// println('$d.id draw_text($x, $y, $text)')
	mut s := d.s
	s.text(x, y, text, 'none', d.ts)
}

// pub fn (d &DrawDeviceSVG) draw_text_def(x int, y int, text string) {

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_text_default(x int, y int, text string) {
	// println('$d.id draw_text_default($x, $y, $text)')
	mut s := d.s
	s.text(x, y, text, 'none', d.ts)
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_text_def(x int, y int, text string) {}

// TODO: documentation
pub fn (d &DrawDeviceSVG) set_text_cfg(c gx.TextCfg) {}

// TODO: documentation
pub fn (d &DrawDeviceSVG) text_size(s string) (int, int) {
	return 0, 0
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) text_width(s string) int {
	return 0
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) text_height(s string) int {
	return 0
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) reset_clipping() {
	// TODO: implement
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) set_clipping(rect Rect) {
	// TODO: implement
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) get_clipping() Rect {
	// TODO: implement
	return Rect{0, 0, int(max_i32), int(max_i32)}
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_pixel(x f32, y f32, color gx.Color, params gg.DrawPixelConfig) {
	mut s := d.s
	s.rectangle(int(x), int(y), 1, 1, fill: hex_color(color))
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_pixels(points []f32, color gx.Color, params gg.DrawPixelConfig) {
	mut s := d.s
	for i in 0 .. points.len / 2 {
		s.rectangle(int(points[i * 2]), int(points[i * 2 + 1]), 1, 1, fill: hex_color(color))
	}
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_image(x f32, y f32, width f32, height f32, img &gg.Image) {
	// println('$d.id draw_image($x, $y, $width, $height, img)')
	mut s := d.s
	s.image(int(x), int(y), int(width), int(height), img.path)
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_triangle_empty(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	// println('$d.id draw_triangle_empty($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
	mut s := d.s
	s.polyline('${x},${y} ${x2},${y2} ${x3},${y3} ${x},${y}',
		stroke:      hex_color(color)
		strokewidth: 1
	)
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_triangle_filled(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color) {
	// println('$d.id draw_triangle_filled($x, $y, $x2, $y2, $x3, $y3, color gx.Color)')
	mut s := d.s
	s.polygon('${x},${y} ${x2},${y2} ${x3},${y3} ${x},${y}', fill: hex_color(color))
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_rect_empty(x f32, y f32, w f32, h f32, color gx.Color) {
	// println('$d.id draw_rect_empty($x, $y, $w, $h, $color)')
	mut s := d.s
	s.rectangle(int(x), int(y), int(w), int(h), stroke: hex_color(color), strokewidth: 1)
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_rect_filled(x f32, y f32, w f32, h f32, color gx.Color) {
	// println('$d.id draw_rect_filled($x, $y, $w, $h, $color)')
	mut s := d.s
	s.rectangle(int(x), int(y), int(w), int(h), fill: hex_color(color))
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	// println('$d.id draw_rounded_rect_filled($x, $y, $w, $h, $radius, color gx.Color)')
	mut s := d.s
	s.rectangle(int(x), int(y), int(w), int(h),
		rx:   int(radius)
		ry:   int(radius)
		fill: hex_color(color)
	)
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, color gx.Color) {
	// println('$d.id draw_rounded_rect_empty($x, $y, $w, $h, $radius, color gx.Color)')
	mut s := d.s
	s.rectangle(int(x), int(y), int(w), int(h),
		rx:          int(radius)
		ry:          int(radius)
		stroke:      hex_color(color)
		strokewidth: 1
	)
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_circle_line(x f32, y f32, r int, segments int, color gx.Color) {
	println('${d.id} ')
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_circle_empty(x f32, y f32, r f32, color gx.Color) {
	// println('$d.id ')
	mut s := d.s
	s.circle(int(x), int(y), int(r), stroke: hex_color(color), strokewidth: 1)
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_circle_filled(x f32, y f32, r f32, color gx.Color) {
	// println('$d.id ')
	mut s := d.s
	s.circle(int(x), int(y), int(r), fill: hex_color(color))
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_slice_empty(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_slice_filled(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_arc_empty(x f32, y f32, radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_arc_filled(x f32, y f32, radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_arc_line(x f32, y f32, radius f32, start_angle f32, end_angle f32, segments int, color gx.Color) {
	// println('$d.id ')
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color) {
	// println('$d.id ')
	mut s := d.s
	s.line(int(x), int(y), int(x2), int(y2), stroke: hex_color(color), strokewidth: 1)
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_convex_poly(points []f32, color gx.Color) {
	// println('$d.id ')
	// mut s := d.s
	// s.polygon(points.map(it.str()).join(','), fill: svg.color(color))
}

// TODO: documentation
pub fn (d &DrawDeviceSVG) draw_poly_empty(points []f32, color gx.Color) {
	// println('$d.id ')
}
