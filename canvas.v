// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub type DrawFn fn(voidptr)

pub struct Canvas {
mut:
	parent &ui.Window
	x      int
	y      int
	width int
	height int
	ui     &UI
	draw_fn DrawFn
	idx int
}

pub struct CanvasConfig {
	x      int
	y      int
	parent &ui.Window
	text   string
	draw_fn DrawFn
}

pub fn new_canvas(c CanvasConfig) &Canvas {
	mut canvas := &Canvas{
		x: c.x
		y: c.y
		parent: c.parent
		ui: c.parent.ui
		draw_fn: c.draw_fn
	}
	canvas.parent.children << canvas
	return canvas
}

fn (c mut Canvas) draw() {
	c.draw_fn(c.parent.user_ptr)
}

fn (t &Canvas) key_down(e KeyEvent) {}

fn (t &Canvas) click(e MouseEvent) {
}

fn (t &Canvas) focus() {}

fn (t &Canvas) idx() int {
	return t.idx
}

fn (t &Canvas) is_focused() bool {
	return false
}

fn (t &Canvas) unfocus() {}

fn (t &Canvas) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

