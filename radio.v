// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
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
type RadioClickFn = fn ()

[ref_only]
pub struct Radio {
pub mut:
	selected_index int
	values         []string
	// state      RadioState
	title      string
	height     int
	width      int
	x          int
	y          int
	parent     Layout
	is_focused bool
	is_checked bool
	ui         &UI
	// selected_value string
	// onclick    RadioClickFn
}

pub struct RadioConfig {
	// onclick    RadioClickFn
	values []string
	title  string
	width  int
	ref    &Radio = voidptr(0)
}

fn (mut r Radio) init(parent Layout) {
	r.parent = parent
	ui := parent.get_ui()
	r.ui = ui
	// Get max value text width
	if r.width == 0 {
		mut max := 0
		for value in r.values {
			width := r.ui.gg.text_width(value)
			if width > max {
				max = width
			}
		}
		r.width = max + check_mark_size + 10
	}
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_click, radio_click, r)
}

pub fn radio(c RadioConfig) &Radio {
	mut r := &Radio{
		height: 20
		values: c.values
		title: c.title
		width: c.width
		ui: 0
		// onclick: c.onclick
	}
	/*
	if c.ref != 0 {
		mut ref := c.ref
		*ref = *r
		return &ref
	}
	*/
	return r
}

fn (mut r Radio) set_pos(x int, y int) {
	r.x = x
	r.y = y
}

fn (mut r Radio) size() (int, int) {
	return r.width, r.height
}

fn (mut r Radio) propose_size(w int, h int) (int, int) {
	// r.width = w
	// r.height = 20//default_font_size
	return r.width, r.values.len * (r.height + 5)
}

fn (mut r Radio) draw() {
	// Border
	r.ui.gg.draw_empty_rect(r.x, r.y, r.width, r.values.len * (r.height + 5), gx.gray)
	// Title
	r.ui.gg.draw_rect(r.x + check_mark_size, r.y - 5, r.ui.gg.text_width(r.title) + 5,
		10, default_window_color)
	r.ui.gg.draw_text_def(r.x + check_mark_size + 3, r.y - 7, r.title)
	// Values
	for i, val in r.values {
		y := r.y + r.height * i + 15
		x := r.x + 5
		r.ui.gg.draw_image(x, y - 1, 16, 16, r.ui.selected_radio_image)
		if i != r.selected_index {
			r.ui.gg.draw_rect(x + 4, y + 3, 8, 8, gx.white) // hide the black circle
			// r.ui.gg.draw_image(x, y-3, 16, 16, r.ui.circle_image)
		}
		// Text
		r.ui.gg.draw_text(r.x + check_mark_size + 10, y, val, btn_text_cfg)
	}
}

fn (r &Radio) point_inside(x f64, y f64) bool {
	return x >= r.x && x <= r.x + r.width && y >= r.y && y <= r.y + (r.height + 5) * r.values.len
}

fn radio_click(mut r Radio, e &MouseEvent, zzz voidptr) {
	if !r.point_inside(e.x, e.y) {
		return
	}
	// println('e.y=$e.y r.y=$r.y')
	y := e.y - r.y
	r.selected_index = (y) / (r.height + 5)
	if r.selected_index == r.values.len {
		r.selected_index = r.values.len - 1
	}
	// println(r.selected_index)
}

fn (mut r Radio) focus() {
	r.is_focused = true
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
