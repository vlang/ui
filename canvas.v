// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gg

pub struct Canvas {
mut:
	width int
	height int
	x		int
	y		int
	parent Layout
	draw_fn DrawFn = voidptr(0)
	gg &gg.Context
}

pub struct CanvasConfig {
	width int
	height int
	text   string
	draw_fn DrawFn = voidptr(0)
}

fn (mut c Canvas)init(parent Layout) {
	c.parent = parent
	c.gg = parent.get_ui().gg
}

pub fn canvas(c CanvasConfig) &Canvas {
	mut canvas := &Canvas{
		width: c.width
		height: c.height
		draw_fn: c.draw_fn
	}
	return canvas
}

fn (mut b Canvas) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (mut b Canvas) size() (int, int) {
	return b.width, b.height
}

fn (mut b Canvas) propose_size(w, h int) (int, int) {
	/* b.width = w
	b.height = h
	return w, h */
	if b.width == 0 {
		b.width = w
	}
	return b.width, b.height
}

fn (c &Canvas) draw() {
	parent := c.parent
	state := parent.get_state()
	if c.draw_fn != voidptr(0) {
		c.draw_fn(c.gg, state)
	}
}

fn (t &Canvas) focus() {}

fn (t &Canvas) is_focused() bool {
	return false
}

fn (t &Canvas) unfocus() {}

fn (t &Canvas) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}
