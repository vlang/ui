// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

[heap]
pub struct Rectangle {
pub mut:
	id string
	// color    gx.Color
	text     string
	offset_x int
	offset_y int
	height   int
	width    int
	ui       &UI    = unsafe { nil }
	parent   Layout = empty_stack
	// Style
	theme_style  string
	style        RectangleShapeStyle
	style_params RectangleStyleParams
	// text styles
	text_styles TextStyles
	// text_size   f64
	// component state for composable widget
	component voidptr
mut:
	x       int
	y       int
	z_index int
	radius  int
	border  bool
	// border_color gx.Color
	hidden bool
}

[params]
pub struct RectangleParams {
	RectangleStyleParams
	id      string
	text    string
	height  int
	width   int
	z_index int
	// color        gx.Color = gx.Color{0, 0, 0, 0}
	radius int
	border bool
	// border_color gx.Color = gx.Color{
	// 	r: 180
	// 	g: 180
	// 	b: 190
	// }
	x int
	y int
	// text_size f64
	theme string = no_style
}

pub fn rectangle(c RectangleParams) &Rectangle {
	mut rect := &Rectangle{
		id: c.id
		text: c.text
		height: c.height
		width: c.width
		z_index: c.z_index
		radius: c.radius
		style_params: c.RectangleStyleParams
		// color: c.color
		border: c.border
		// border_color: c.border_color
		ui: 0
		x: c.x
		y: c.y
		// text_size: c.text_size
	}
	rect.style_params.style = c.theme
	return rect
}

// Workaround to have a spacing notably
pub fn spacing(c RectangleParams) &Rectangle {
	mut rect := &Rectangle{
		// color: c.color
		ui: 0
	}
	rect.hidden = true
	return rect
}

fn (mut r Rectangle) init(parent Layout) {
	r.parent = parent
	ui := parent.get_ui()
	r.ui = ui
	// r.init_style()
	r.load_style()
}

// fn (mut r Rectangle) init_style() {
// 	mut dtw := DrawTextWidget(r)
// 	dtw.init_style()
// 	dtw.update_text_size(r.text_size)
// }

[manualfree]
pub fn (mut r Rectangle) cleanup() {
	unsafe { r.free() }
}

[unsafe]
pub fn (r &Rectangle) free() {
	$if free ? {
		print('rectangle ${r.id}')
	}
	unsafe {
		r.text.free()
		r.id.free()
		free(r)
	}
	$if free ? {
		println(' -> freed')
	}
}

pub fn (mut r Rectangle) set_pos(x int, y int) {
	r.x = x
	r.y = y
}

pub fn (mut r Rectangle) size() (int, int) {
	return r.width, r.height
}

pub fn (mut r Rectangle) propose_size(w int, h int) (int, int) {
	r.width, r.height = w, h
	return r.width, r.height
}

fn (mut r Rectangle) draw() {
	r.draw_device(mut r.ui.dd)
}

fn (mut r Rectangle) draw_device(mut d DrawDevice) {
	offset_start(mut r)
	$if layout ? {
		if r.ui.layout_print {
			println('Rectangle(${r.id}): (${r.x}, ${r.y}, ${r.width}, ${r.height})')
		}
	}
	if r.radius > 0 {
		d.draw_rounded_rect_filled(r.x, r.y, r.width, r.height, r.radius, r.style.color)
		if r.border {
			d.draw_rounded_rect_empty(r.x, r.y, r.width, r.height, r.radius, r.style.border_color)
		}
	} else {
		d.draw_rect_filled(r.x, r.y, r.width, r.height, r.style.color)
		if r.border {
			d.draw_rect_empty(r.x, r.y, r.width, r.height, r.style.border_color)
		}
	}
	// Display rectangle text
	if r.text != '' {
		mut dtw := DrawTextWidget(r)
		dtw.draw_device_load_style(d)
		text_width, text_height := dtw.text_size(r.text)
		mut dx := (r.width - text_width) / 2
		mut dy := (r.height - text_height) / 2
		if dx < 0 {
			dx = 0
		}
		if dy < 0 {
			dy = 0
		}
		dtw.draw_device_text(d, r.x + dx, r.y + dy, r.text)
		// draw_text(r, r.x + dx, r.y + dy, r.text)
	}
	offset_end(mut r)
}

// fn (mut r Rectangle) draw(d DrawDevice) {
// 	offset_start(mut r)
// 	if r.radius > 0 {
// 		r.ui.dd.draw_rounded_rect_filled(r.x, r.y, r.width, r.height, r.radius, r.color)
// 		if r.border {
// 			r.ui.dd.draw_rounded_rect_empty(r.x, r.y, r.width, r.height, r.radius, r.border_color)
// 		}
// 	} else {
// 		r.ui.dd.draw_rect_filled(r.x, r.y, r.width, r.height, r.color)
// 		if r.border {
// 			r.ui.dd.draw_rect_empty(r.x, r.y, r.width, r.height, r.border_color)
// 		}
// 	}
// 	// Display rectangle text
// 	if r.text != '' {
// 		text_width, text_height := text_size(r, r.text)
// 		mut dx := (r.width - text_width) / 2
// 		mut dy := (r.height - text_height) / 2
// 		if dx < 0 {
// 			dx = 0
// 		}
// 		if dy < 0 {
// 			dy = 0
// 		}
// 		draw_text(r, r.x + dx, r.y + dy, r.text)
// 	}
// 	offset_end(mut r)
// }

fn (mut r Rectangle) set_visible(state bool) {
	r.hidden = !state
}

fn (r &Rectangle) point_inside(x f64, y f64) bool {
	return point_inside(r, x, y)
}
