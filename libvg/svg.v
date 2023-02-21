module libvg

import strings
import os

pub struct Svg {
pub mut:
	height   int
	width    int
	offset_x int
	offset_y int
	buffer   strings.Builder  = strings.new_builder(32768)
	content  &strings.Builder = unsafe { nil }
}

[params]
pub struct SvgParams {
	height int
	width  int
}

// TODO: documentation
pub fn svg(p SvgParams) &Svg {
	mut s := &Svg{
		height: p.height
		width: p.width
	}
	s.content = &s.buffer
	return s
}

// TODO: documentation
[unsafe]
pub fn (r &Svg) free() {
	unsafe {
		r.buffer.free()
	}
}

// TODO: documentation
pub fn (mut s Svg) resize(w int, h int) {
	s.width, s.height = w, h
}

// TODO: documentation
pub fn (mut s Svg) begin() {
	s.content.write_string("<?xml version='1.0' encoding='utf-8'?>\n<svg width='${s.width}px' height='${s.height}px'  xmlns='http://www.w3.org/2000/svg' version='1.1' xmlns:xlink='http://www.w3.org/1999/xlink'>\n")
}

// TODO: documentation
pub fn (mut s Svg) end() {
	s.content.write_string('</svg>\n')
}

// TODO: documentation
pub fn (mut s Svg) save(filepath string) ! {
	// write it to a file
	os.write_file_array(filepath, *s.content)!
}

[params]
pub struct Params {
	stroke      string = 'none'
	strokewidth int
	fill        string = 'none'
	rx          int
	ry          int
	linecap     string = 'butt'
	linejoin    string = 'bevel'
}

// TODO: documentation
pub fn (mut s Svg) circle(x int, y int, r int, p Params) {
	s.content.write_string("<circle cx='${x + s.offset_x}' cy='${y + s.offset_y}' r='${r}'  stroke='${p.stroke}' stroke-width='${p.strokewidth}px' stroke-linecap='${p.linecap}' stroke-linejoin='${p.linejoin}' fill='${p.fill}' />\n")
}

// TODO: documentation
pub fn (mut s Svg) line(x1 int, y1 int, x2 int, y2 int, p Params) {
	s.content.write_string("<line x1='${x1 + s.offset_x}' y1='${y1 + s.offset_y}' x2='${x2 +
		s.offset_x}' y2='${y2 + s.offset_y}' stroke='${p.stroke}' stroke-width='${p.strokewidth}px' stroke-linecap='${p.linecap}' stroke-linejoin='${p.linejoin}' />\n")
}

// TODO: documentation
pub fn (mut s Svg) rectangle(x int, y int, width int, height int, p Params) {
	s.content.write_string("<rect x='${x + s.offset_x}' y='${y + s.offset_y}' width='${width}' height='${height}' rx='${p.rx}' ry='${p.ry}' fill='${p.fill}' stroke='${p.stroke}' stroke-width='${p.strokewidth}px' stroke-linecap='${p.linecap}' stroke-linejoin='${p.linejoin}' />\n")
}

// TODO: documentation
pub fn (mut s Svg) fill(fill string) {
	s.rectangle(0, 0, s.width, s.height, fill: fill)
}

// TODO: documentation
pub fn (mut s Svg) text(x int, y int, text string, fill string, ts SvgTextStyle) {
	col := if fill !in ['', 'none', 'transparent'] { fill } else { hex_color(ts.color) }
	s.content.write_string("<text x='${x + s.offset_x}' y='${y + s.offset_y}'  fill='${col}' font-family='${ts.font_name}' font-size='${ts.size}px' dominant-baseline='${ts.vertical_align}' text-anchor='${ts.align}'><![CDATA[${text}]]></text>\n")
}

// TODO: documentation
pub fn (mut s Svg) ellipse(x int, y int, rx int, ry int, p Params) {
	s.content.write_string("<ellipse cx='${x + s.offset_x}' cy='${y + s.offset_y}' rx='${rx}' ry='${ry}' fill='${p.fill}' stroke='${p.stroke}' stroke-width='${p.strokewidth}px' stroke-linecap='${p.linecap}' stroke-linejoin='${p.linejoin}' />\n")
}

// TODO: documentation
pub fn (mut s Svg) polygon(points string, p Params) {
	s.content.write_string("<polygon points='${points}' fill='${p.fill}' stroke='${p.stroke}' stroke-width='${p.strokewidth}px' stroke-linecap='${p.linecap}' stroke-linejoin='${p.linejoin}' />\n")
}

// TODO: documentation
pub fn (mut s Svg) polyline(points string, p Params) {
	s.content.write_string("<polyline points='${points}' fill='${p.fill}' stroke='${p.stroke}' stroke-width='${p.strokewidth}px' stroke-linecap='${p.linecap}' stroke-linejoin='${p.linejoin}' />\n")
}

// TODO: documentation
pub fn (mut s Svg) path(d string, p Params) {
	s.content.write_string("<path d='${d}' fill='${p.fill}' stroke='${p.stroke}' stroke-width='${p.strokewidth}px' stroke-linecap='${p.linecap}' stroke-linejoin='${p.linejoin}' />\n")
}

// TODO: documentation
pub fn (mut s Svg) image(x int, y int, width int, height int, path string) {
	s.content.write_string("<image xlink:href='${path}' x='${x + s.offset_x}' y='${y + s.offset_y}' height='${height}' width='${width}' />\n")
}
