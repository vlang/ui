// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

/*
enum RadioState {
	normal
	check
}
*/
type RadioClickFn = fn (voidptr, voidptr)

[heap]
pub struct Radio {
pub mut:
	id             string
	selected_index int
	values         []string
	// state      RadioState
	title       string
	height      int
	width       int
	real_height int = 20
	real_width  int
	x           int
	y           int
	offset_x    int
	offset_y    int
	z_index     int
	parent      Layout
	is_focused  bool
	is_checked  bool
	ui          &UI
	text_cfg    gx.TextCfg
	text_size   f64
	hidden      bool
	horizontal  bool
	// component state for composable widget
	component voidptr
	// selected_value string
	on_click RadioClickFn
}

pub struct RadioConfig {
	id       string
	on_click RadioClickFn
	values   []string
	title    string
	width    int
	z_index  int
	// ref       &Radio = voidptr(0)
	text_cfg   gx.TextCfg
	text_size  f64
	horizontal bool
}

pub fn radio(c RadioConfig) &Radio {
	mut r := &Radio{
		id: c.id
		height: 20
		z_index: c.z_index
		values: c.values
		title: c.title
		width: c.width
		text_cfg: c.text_cfg
		text_size: c.text_size
		horizontal: c.horizontal
		ui: 0
		on_click: c.on_click
	}
	r.update_size()
	/*
	if c.ref != 0 {
		mut ref := c.ref
		*ref = *r
		return &ref
	}
	*/
	return r
}

fn (mut r Radio) init(parent Layout) {
	r.parent = parent
	ui := parent.get_ui()
	r.ui = ui
	// Get max value text width
	if r.width == 0 {
		mut max := 0
		for value in r.values {
			width := text_width(r, value)
			if width > max {
				max = width
			}
		}
		r.width = max + check_mark_size + 10
	}
	init_text_cfg(mut r)
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, radio_click, r)
}

[manualfree]
pub fn (mut r Radio) cleanup() {
	mut subscriber := r.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_click, r)
	unsafe { r.free() }
}

[unsafe]
pub fn (r &Radio) free() {
	$if free ? {
		print('radio $r.id')
	}
	unsafe {
		r.id.free()
		for v in r.values {
			v.free()
		}
		r.values.free()
		r.title.free()
		free(r)
	}
	$if free ? {
		println(' -> freed')
	}
}

pub fn (mut r Radio) set_pos(x int, y int) {
	r.x = x
	r.y = y
}

pub fn (mut r Radio) size() (int, int) {
	return r.real_width, r.real_height
}

pub fn (mut r Radio) propose_size(w int, h int) (int, int) {
	if r.horizontal {
		r.width = w / r.values.len
	} else {
		r.width = w
	}
	r.update_size()
	// r.height = 20//default_font_size
	return r.real_width, r.real_height
}

fn (mut r Radio) update_size() {
	if r.horizontal {
		r.real_width, r.real_height = r.values.len * r.width, r.height + 15
	} else {
		r.real_width, r.real_height = r.width, r.values.len * (r.height + 5)
	}
}

fn (mut r Radio) draw() {
	offset_start(mut r)
	if r.title != '' {
		// Border
		r.ui.gg.draw_empty_rect(r.x, r.y, r.real_width, r.real_height, gx.gray)
		// Title
		r.ui.gg.draw_rect(r.x + check_mark_size, r.y - 5, r.ui.gg.text_width(r.title) + 5,
			10, default_window_color)
		// r.ui.gg.draw_text(r.x + check_mark_size + 3, r.y - 7, r.title, r.text_cfg.as_text_cfg())
		// r.draw_text(r.x + check_mark_size + 3, r.y - 7, r.title)
		draw_text(r, r.x + check_mark_size + 3, r.y - 7, r.title)
	}
	// Values
	mut x, mut y, mut dy := 0, 0, 0
	if r.title != '' {
		dy = 15
	}
	for i, val in r.values {
		if r.horizontal {
			y = r.y + dy
			x = r.x + i * r.width + 5
		} else {
			y = r.y + r.height * i + dy
			x = r.x + 5
		}
		r.ui.gg.draw_image(x, y - 1, 16, 16, r.ui.selected_radio_image)
		if i != r.selected_index {
			r.ui.gg.draw_rect(x + 4, y + 3, 8, 8, gx.white) // hide the black circle
			// r.ui.gg.draw_image(x, y-3, 16, 16, r.ui.circle_image)
		}
		// Text
		// r.ui.gg.draw_text(r.x + check_mark_size + 10, y, val, r.text_cfg.as_text_cfg())
		// r.draw_text(r.x + check_mark_size + 10, y, val)
		draw_text(r, x + check_mark_size + 5, y, val)
	}
	$if bb ? {
		draw_bb(mut r, r.ui)
	}
	offset_end(mut r)
}

fn (r &Radio) point_inside(x f64, y f64) bool {
	rx, ry := r.x + r.offset_x, r.y + r.offset_y
	return x >= rx && x <= rx + r.real_width && y >= ry && y <= ry + r.real_height
}

fn radio_click(mut r Radio, e &MouseEvent, zzz voidptr) {
	if r.hidden {
		return
	}
	if !r.point_inside(e.x, e.y) {
		return
	}
	if r.horizontal {
		x := e.x - r.x
		r.selected_index = x / (r.width + 5)
		if r.selected_index == r.values.len {
			r.selected_index = r.values.len - 1
		}
	} else {
		// println('e.y=$e.y r.y=$r.y')
		y := e.y - r.y
		r.selected_index = y / (r.height + 5)
		if r.selected_index == r.values.len {
			r.selected_index = r.values.len - 1
		}
	}
	// println(r.selected_index)
}

fn (mut r Radio) set_visible(state bool) {
	r.hidden = !state
}

fn (mut r Radio) focus() {
	// r.is_focused = true
	set_focus(r.ui.window, mut r)
}

fn (mut r Radio) unfocus() {
	r.is_focused = false
}

pub fn (r &Radio) selected_value() string {
	return r.values[r.selected_index]
}

fn (r &Radio) is_focused() bool {
	return r.is_focused
}
