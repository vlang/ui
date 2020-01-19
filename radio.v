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

type RadioClickFn fn()

pub struct Radio {
pub mut:
	idx            int
	selected_index int
	values         []string
	// state      RadioState
	title          string
	height         int
	width          int
	x              int
	y              int
	parent         &ui.Window
	is_focused     bool
	is_checked     bool
	ui             &UI
	//selected_value string
	// onclick    RadioClickFn
}

pub struct RadioConfig {
	x      int
	y      int
	parent &ui.Window
	// onclick    RadioClickFn
	values []string
	title  string
	width  int
}

pub fn new_radio(c RadioConfig) &Radio {
	mut cb := &Radio{
		height: 20
		x: c.x
		y: c.y
		parent: c.parent
		ui: c.parent.ui
		idx: c.parent.children.len
		values: c.values
		title: c.title
		width: c.width
		// onclick: c.onclick
	}
	// Get max value text width
	if cb.width == 0 {
		mut max := 0
		for value in cb.values {
			width := cb.ui.ft.text_width(value)
			if width > max {
				max = width
			}
		}
		cb.width = max + check_mark_size + 10
	}
	cb.parent.children << cb
	return cb
}

fn (b mut Radio) draw() {
	// Border
	b.ui.gg.draw_empty_rect(b.x, b.y, b.width, b.values.len * (b.height + 5), gx.gray)
	// Title
	b.ui.gg.draw_rect(b.x + check_mark_size, b.y - 5, b.ui.ft.text_width(b.title) + 5, 10, default_window_color)
	b.ui.ft.draw_text_def(b.x + check_mark_size + 3, b.y - 7, b.title)
	// Values
	for i, val in b.values {
		y := b.y + b.height * i + 15
		x := b.x + 5
		b.ui.gg.draw_image(x, y-1, 16, 16, b.ui.selected_radio_image)
		if i != b.selected_index {
			b.ui.gg.draw_rect(x+4,y+3,8,8,gx.white) // hide the black circle
			//b.ui.gg.draw_image(x, y-3, 16, 16, b.ui.circle_image)
		}
		// Text
		b.ui.ft.draw_text(b.x + check_mark_size + 10, y, val, btn_text_cfg)
	}
}

fn (b &Radio) key_down(e KeyEvent) {}

fn (t &Radio) point_inside(x, y f64) bool {
	return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + (t.height + 5) * t.values.len
}

fn (r mut Radio) click(e MouseEvent) {
	if e.action != 0 {
		return
	}
	// println('e.y=$e.y r.y=$r.y')
	y := e.y - r.y
	r.selected_index = (y) / (r.height + 5)
	//println(r.selected_index)
}

fn (r &Radio) mouse_move(e MouseEvent) {
}

fn (b mut Radio) focus() {
	b.is_focused = true
}

fn (b mut Radio) unfocus() {
	b.is_focused = false
}

fn (b &Radio) idx() int {
	return b.idx
}

fn (t &Radio) typ() WidgetType {
	return .radio
}

pub fn (r &Radio) selected_value() string {
	return r.values[r.selected_index]
}

fn (t &Radio) is_focused() bool {
	return t.is_focused
}
